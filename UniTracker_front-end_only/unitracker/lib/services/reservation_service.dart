import 'package:flutter/foundation.dart';
import 'package:unitracker/models/bus_route.dart';
import 'package:unitracker/models/reservation.dart';
import 'package:unitracker/services/notification_service.dart';
import 'package:unitracker/services/notification_settings_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_notification.dart';
import '../models/bus_stop.dart';
import 'supabase_service.dart';

class ReservationService extends ChangeNotifier {
  // Singleton instance with NotificationService
  static ReservationService? _instance;
  static ReservationService getInstance(NotificationService notificationService,
      NotificationSettingsService notificationSettingsService) {
    _instance ??= ReservationService._internal(
        notificationService, notificationSettingsService);
    return _instance!;
  }

  final NotificationService _notificationService;
  final NotificationSettingsService _notificationSettingsService;
  final SupabaseService _supabaseService = SupabaseService.instance;
  late final List<Reservation> _reservations;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  ReservationService._internal(
      this._notificationService, this._notificationSettingsService) {
    _reservations = [];
    loadReservations();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    // Listen for changes to the user's reservations
    final currentUser = _supabaseService.currentUser;
    if (currentUser != null) {
      _supabaseService.client
          .channel('reservations')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'reservations',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: currentUser.id,
            ),
            callback: (payload) {
              debugPrint('🔄 Reservation update detected: $payload');
              // Reload reservations when any change is detected
              loadReservations();
            },
          )
          .subscribe();
    }
  }

  Future<void> loadReservations() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final reservationsData =
          await _supabaseService.getUserReservations(currentUser.id);
      _reservations.clear();
      _reservations.addAll(
          reservationsData.map((data) => _mapSupabaseToReservation(data)));
      _error = null;
    } catch (e) {
      _error = 'Failed to load reservations: ${e.toString()}';
      debugPrint('Error loading reservations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getter for reservations (immutable copy)
  List<Reservation> get reservations => List.unmodifiable(_reservations);

  // Check if time is morning hours (before 2 PM)
  bool _isMorningHours(DateTime time) {
    return time.hour < 14; // Before 2 PM is considered morning
  }

  // Check if time is evening hours (2 PM or later)
  bool _isEveningHours(DateTime time) {
    return time.hour >= 14; // 2 PM or later is considered evening
  }

  // Check if user has existing reservation for the same time period and direction on the same day
  bool _hasExistingReservation(
      DateTime newReservationTime, String pickupPoint, String dropPoint) {
    final existingReservations = _reservations.where((reservation) {
      try {
        final existingReservationTime = DateTime.parse(reservation.date);
        // Check if it's the same day
        if (existingReservationTime.year == newReservationTime.year &&
            existingReservationTime.month == newReservationTime.month &&
            existingReservationTime.day == newReservationTime.day &&
            reservation.status != 'cancelled') {
          // Determine direction for new reservation
          final isNewToUniversity =
              _isToUniversityDirection(pickupPoint, dropPoint);

          // Determine direction for existing reservation
          final isExistingToUniversity = _isToUniversityDirection(
              reservation.pickupPoint, reservation.dropPoint);

          // Check if both reservations are in the same direction
          if (isNewToUniversity == isExistingToUniversity) {
            // Check if both reservations are in the same time period (morning/evening)
            final isNewMorning = _isMorningHours(newReservationTime);
            final isExistingMorning = _isMorningHours(existingReservationTime);

            return isNewMorning == isExistingMorning;
          }
        }
        return false;
      } catch (e) {
        return false;
      }
    });

    return existingReservations.isNotEmpty;
  }

  bool _isToUniversityDirection(String pickupPoint, String dropPoint) {
    // Check if this is a "To University" trip
    final pickup = pickupPoint.toLowerCase().trim();
    final drop = dropPoint.toLowerCase().trim();

    debugPrint('🔍 Direction check: pickup="$pickup", drop="$drop"');

    // University/campus keywords
    final universityKeywords = ['eui', 'campus', 'university', 'college'];

    // Check if pickup point contains university keywords
    bool pickupIsUniversity =
        universityKeywords.any((keyword) => pickup.contains(keyword));

    // Check if drop point contains university keywords
    bool dropIsUniversity =
        universityKeywords.any((keyword) => drop.contains(keyword));

    // "To University" means going TO the campus (drop point is university, pickup is not)
    bool isToUniversity = dropIsUniversity && !pickupIsUniversity;

    // "From University" means going FROM the campus (pickup point is university, drop is not)
    bool isFromUniversity = pickupIsUniversity && !dropIsUniversity;

    debugPrint('🔍 Direction analysis:');
    debugPrint('  - Pickup is university: $pickupIsUniversity');
    debugPrint('  - Drop is university: $dropIsUniversity');
    debugPrint('  - To university: $isToUniversity');
    debugPrint('  - From university: $isFromUniversity');

    return isToUniversity;
  }

  // Cancel a reservation
  Future<void> cancelReservation(String reservationId) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        final reservation = _reservations[index];
        final now = DateTime.now();
        final reservationDateTime = DateTime.parse(reservation.date);

        // Check if cancellation is allowed (more than 2 hours before departure)
        if (reservationDateTime.difference(now).inHours <= 2) {
          throw Exception(
              'Reservations can only be cancelled more than 2 hours before departure');
        }

        // Cancel in Supabase
        await _supabaseService.cancelReservation(reservationId);

        _reservations[index] = Reservation(
          id: reservation.id,
          userId: reservation.userId,
          route: reservation.route,
          date: reservation.date,
          status: 'cancelled',
          seatNumber: reservation.seatNumber,
          pickupPoint: reservation.pickupPoint,
          dropPoint: reservation.dropPoint,
        );

        // Send cancellation notification if enabled
        if (_notificationSettingsService.reservationUpdatesEnabled) {
          await _supabaseService.createNotification({
            'user_id': currentUser.id,
            'title': 'Reservation Cancelled',
            'message':
                'Your reservation for ${DateFormat('MMM d').format(reservationDateTime)} has been cancelled.',
            'type': 'info',
          });
        }

        _error = null;
        notifyListeners();
      } else {
        throw Exception('Reservation not found');
      }
    } catch (e) {
      _error = 'Failed to cancel reservation: ${e.toString()}';
      throw Exception('Failed to cancel reservation: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Reservation _createFallbackReservation(BusRoute route, DateTime dateTime,
      String pickupPoint, String dropPoint, int seatNumber) {
    return Reservation(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      userId: '', // fallback, not used
      route: route,
      date: dateTime.toIso8601String(),
      pickupPoint: pickupPoint,
      dropPoint: dropPoint,
      seatNumber: seatNumber.toString(),
      status: 'confirmed',
    );
  }

  Reservation _mapSupabaseToReservation(Map<String, dynamic> data) {
    final routeData = data['routes'] as Map<String, dynamic>;
    final pickupStopData = data['pickup_stop'] as Map<String, dynamic>?;
    final dropStopData = data['drop_stop'] as Map<String, dynamic>?;
    final slotData = data['reservation_slots'] as Map<String, dynamic>?;

    final route = BusRoute(
      id: routeData['id'] as String,
      name: routeData['name'] as String,
      pickup: routeData['pickup_location'] as String,
      drop: routeData['drop_location'] as String,
      startTime: _formatTime(routeData['start_time'] as String),
      endTime: _formatTime(routeData['end_time'] as String),
      stops: [], // We'll load stops separately if needed
      iconColor: routeData['color_code'] as String? ?? '2196F3',
    );

    // Determine the actual pickup and drop points based on the direction
    // The stops in the database are intermediate stops, but we want to show main locations
    String actualPickupPoint;
    String actualDropPoint;

    // Check if this is a "To University" or "From University" trip
    final pickupStopName = pickupStopData?['name'] as String? ?? '';
    final dropStopName = dropStopData?['name'] as String? ?? '';

    // If pickup is gate 2 and drop is gate 3, this is "To University"
    if (pickupStopName.toLowerCase().contains('gate 2') &&
        dropStopName.toLowerCase().contains('gate 3')) {
      actualPickupPoint = route.pickup; // gate 1
      actualDropPoint = route.drop; // gate 4 (EUI Campus)
    }
    // If pickup is gate 3 and drop is gate 2, this is "From University"
    else if (pickupStopName.toLowerCase().contains('gate 3') &&
        dropStopName.toLowerCase().contains('gate 2')) {
      actualPickupPoint = route.drop; // gate 4 (EUI Campus)
      actualDropPoint = route.pickup; // gate 1
    }
    // Fallback to the stop names if we can't determine direction
    else {
      actualPickupPoint =
          pickupStopName.isNotEmpty ? pickupStopName : route.pickup;
      actualDropPoint = dropStopName.isNotEmpty ? dropStopName : route.drop;
    }

    // Use slot date/time if available, else fallback to reservation_date
    final slotDate = slotData?['slot_date'] as String?;
    final slotTime = slotData?['slot_time'] as String?;
    final slotId = slotData?['id'] as String?;
    final slotDirection = slotData?['direction'] as String?;
    final slotCapacity = slotData?['capacity'] as int?;

    return Reservation(
      id: data['id'] as String,
      userId: data['user_id'] as String? ?? '',
      route: route,
      date: slotDate ?? data['reservation_date'] as String,
      status: data['status'] as String,
      seatNumber: data['seat_number']?.toString() ?? '',
      pickupPoint: actualPickupPoint,
      dropPoint: actualDropPoint,
      slotId: slotId,
      slotDate: slotDate,
      slotTime: slotTime,
      slotDirection: slotDirection,
      slotCapacity: slotCapacity,
    );
  }

  String _formatTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];

    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }

  Future<String?> _findStopId(String routeId, String stopName) async {
    try {
      // Query bus_stops table directly for this route
      final response = await _supabaseService.client
          .from('bus_stops')
          .select('id, name')
          .eq('route_id', routeId)
          .order(
              'created_at'); // Order by creation to get consistent first/last

      final stops = response as List<dynamic>? ?? [];

      debugPrint('🔍 Available stops for route $routeId:');
      for (final stop in stops) {
        debugPrint('  - ${stop['name']} (ID: ${stop['id']})');
      }
      debugPrint('🔍 Looking for stop: $stopName');

      // Special mapping for main pickup/drop locations to intermediate stops
      final stopNameLower = stopName.toLowerCase();

      debugPrint(
          '🎯 Checking special mapping for: "$stopName" (lowercase: "$stopNameLower")');

      // Map main locations to intermediate stops
      if (stopNameLower.contains('gate 1')) {
        // Main pickup location (gate 1) -> First intermediate stop (gate 2)
        if (stops.isNotEmpty) {
          final firstStop = stops.first;
          debugPrint(
              '🎯 Mapping main pickup location "$stopName" -> ${firstStop['name']} (${firstStop['id']})');
          return firstStop['id'] as String;
        }
      } else if (stopNameLower.contains('gate 4') ||
          stopNameLower.contains('gate4') ||
          stopNameLower.contains('eui') ||
          stopNameLower.contains('campus') ||
          stopNameLower.contains('university')) {
        // Main drop location (gate 4/EUI Campus) -> Last intermediate stop (gate 3)
        if (stops.isNotEmpty) {
          final lastStop = stops.last;
          debugPrint(
              '🎯 Mapping main drop location "$stopName" -> ${lastStop['name']} (${lastStop['id']})');
          return lastStop['id'] as String;
        }
      }

      debugPrint(
          '🎯 No special mapping found, proceeding with exact match search...');

      // First try exact match for intermediate stops
      for (final stop in stops) {
        if (stop['name'] == stopName) {
          debugPrint('✅ Found exact match: ${stop['name']} -> ${stop['id']}');
          return stop['id'] as String;
        }
      }

      // If no exact match, try case-insensitive match
      for (final stop in stops) {
        if (stop['name'].toString().toLowerCase() == stopName.toLowerCase()) {
          debugPrint(
              '✅ Found case-insensitive match: ${stop['name']} -> ${stop['id']}');
          return stop['id'] as String;
        }
      }

      // If still no match, try partial match
      for (final stop in stops) {
        final dbStopNameLower = stop['name'].toString().toLowerCase();
        if (dbStopNameLower.contains(stopNameLower) ||
            stopNameLower.contains(dbStopNameLower)) {
          debugPrint('✅ Found partial match: ${stop['name']} -> ${stop['id']}');
          return stop['id'] as String;
        }
      }

      // Final fallback: use first stop
      if (stops.isNotEmpty) {
        final fallbackStop = stops.first;
        debugPrint(
            '🔄 Using first stop as final fallback: ${fallbackStop['name']} -> ${fallbackStop['id']}');
        return fallbackStop['id'] as String;
      }

      debugPrint('❌ No stops found for route $routeId');
      return null;
    } catch (e) {
      debugPrint('❌ Error finding stop ID: $e');
      return null;
    }
  }

  Future<int> getBusCapacity(String routeId) async {
    try {
      // Get the bus capacity for this route
      final response = await _supabaseService.client.from('routes').select('''
            buses!inner(capacity)
          ''').eq('id', routeId).single();

      final busData = response['buses'] as Map<String, dynamic>;
      final capacity =
          busData['capacity'] as int? ?? 20; // Default to 20 if not found

      debugPrint('🚌 Bus capacity for route $routeId: $capacity seats');
      return capacity;
    } catch (e) {
      debugPrint('❌ Error getting bus capacity: $e');
      return 20; // Default capacity
    }
  }

  Future<int> _getReservedSeatsCount(String routeId, String date,
      {String? direction}) async {
    try {
      // Count existing reservations for this route and date
      var query = _supabaseService.client
          .from('reservations')
          .select('''
            id,
            pickup_stop:pickup_stop_id(name),
            drop_stop:drop_stop_id(name)
          ''')
          .eq('route_id', routeId)
          .eq('reservation_date', date.split('T')[0]) // Compare date only
          .neq('status', 'cancelled');

      final response = await query;
      final reservations = response as List<dynamic>? ?? [];

      // If direction is specified, filter by direction
      if (direction != null) {
        final filteredReservations = reservations.where((reservation) {
          // Get stop names from the joined data
          final pickupStopData =
              reservation['pickup_stop'] as Map<String, dynamic>?;
          final dropStopData =
              reservation['drop_stop'] as Map<String, dynamic>?;

          final pickupPoint = pickupStopData?['name'] as String? ?? '';
          final dropPoint = dropStopData?['name'] as String? ?? '';

          final reservationDirection =
              _isToUniversityDirection(pickupPoint, dropPoint)
                  ? 'to_university'
                  : 'from_university';
          return reservationDirection == direction;
        }).toList();

        final count = filteredReservations.length;
        debugPrint(
            '🎫 Reserved seats for route $routeId on $date ($direction): $count');
        return count;
      } else {
        // Return total count for both directions
        final count = reservations.length;
        debugPrint(
            '🎫 Total reserved seats for route $routeId on $date: $count');
        return count;
      }
    } catch (e) {
      debugPrint('❌ Error getting reserved seats count: $e');
      return 0;
    }
  }

  Future<int> _getNextAvailableSeatNumber(String routeId, String date,
      {String? direction}) async {
    try {
      final reservedCount =
          await _getReservedSeatsCount(routeId, date, direction: direction);
      return reservedCount + 1;
    } catch (e) {
      debugPrint('Error getting seat number: $e');
      return 1;
    }
  }

  Future<int> getRemainingSeats(String routeId, String dateTime,
      {String? direction}) async {
    try {
      final busCapacity = await getBusCapacity(routeId);
      final reservedSeats =
          await _getReservedSeatsCount(routeId, dateTime, direction: direction);
      final remainingSeats = busCapacity - reservedSeats;

      final directionText =
          direction != null ? ' for $direction direction' : '';
      debugPrint(
          '🎫 Remaining seats for route $routeId$directionText: $remainingSeats/$busCapacity');
      return remainingSeats > 0 ? remainingSeats : 0;
    } catch (e) {
      debugPrint('❌ Error getting remaining seats: $e');
      return 0;
    }
  }

  // Synchronous version for backward compatibility
  int getRemainingSeatsSync(String routeId, String dateTime) {
    // Return a default value for immediate UI updates
    // The async version should be used for accurate data
    return 15; // Default assumption
  }

  List<Reservation> getCurrentReservations() {
    final now = DateTime.now();
    return _reservations.where((reservation) {
      try {
        final reservationDate = DateTime.parse(reservation.date);
        return reservationDate.isAfter(now) &&
            reservation.status != 'cancelled';
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Reservation> getReservationHistory() {
    final now = DateTime.now();
    return _reservations.where((reservation) {
      try {
        final reservationDate = DateTime.parse(reservation.date);
        return reservationDate.isBefore(now) ||
            reservation.status == 'cancelled';
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Remove test reservations method as it's no longer needed
  void addTestReservations() {
    // No longer adding test reservations
    notifyListeners();
  }

  Future<void> createReservation({
    required BusRoute route,
    required String date,
    required String pickupPoint,
    required String dropPoint,
    String? slotId,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final reservationDateTime = DateTime.parse(date);
      final now = DateTime.now();

      if (reservationDateTime.isBefore(now)) {
        throw Exception('Cannot make reservations for past times.');
      }

      if (reservationDateTime.difference(now).inHours < 2) {
        throw Exception('Reservations close 2 hours before departure.');
      }

      if (_hasExistingReservation(
          reservationDateTime, pickupPoint, dropPoint)) {
        throw Exception('You already have a reservation for this time period.');
      }

      final busCapacity = await getBusCapacity(route.id);
      final direction = _isToUniversityDirection(pickupPoint, dropPoint)
          ? 'to_university'
          : 'from_university';
      final reservedSeats =
          await _getReservedSeatsCount(route.id, date, direction: direction);

      if (reservedSeats >= busCapacity) {
        throw Exception('No seats available for this trip.');
      }

      final seatNumber = await _getNextAvailableSeatNumber(route.id, date,
          direction: direction);
      final pickupStopId = await _findStopId(route.id, pickupPoint);
      final dropStopId = await _findStopId(route.id, dropPoint);

      if (pickupStopId == null || dropStopId == null) {
        throw Exception('Could not find pickup or drop stop.');
      }

      await _supabaseService.createReservation({
        'user_id': currentUser.id,
        'route_id': route.id,
        'slot_id': slotId,
        'reservation_date': reservationDateTime.toIso8601String(),
        'pickup_stop_id': pickupStopId,
        'drop_stop_id': dropStopId,
        'seat_number': seatNumber,
        'status': 'pending',
      });

      // Send notification to student
      if (_notificationSettingsService.reservationUpdatesEnabled) {
        await _supabaseService.createNotification({
          'user_id': currentUser.id,
          'title': 'Reservation Pending',
          'message':
              'Your reservation is pending and will be reviewed by the admin.',
          'type': 'info',
        });
      }

      // This is the fix: Reload all reservations from the server.
      await loadReservations();
    } catch (e) {
      _error = 'Failed to create reservation: ${e.toString()}';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Count reservations for a given slot_id
  Future<int> countReservationsForSlot(String slotId) async {
    try {
      final response = await _supabaseService.client
          .from('reservations')
          .select('id')
          .eq('slot_id', slotId)
          .neq('status', 'cancelled');
      final reservations = response as List<dynamic>? ?? [];
      return reservations.length;
    } catch (e) {
      debugPrint('❌ Error counting reservations for slot: $e');
      return 0;
    }
  }

  Future<void> confirmReservation(String reservationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService
          .updateReservation(reservationId, {'status': 'confirmed'});
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        final reservation = _reservations[index];
        _reservations[index] = Reservation(
          id: reservation.id,
          userId: reservation.userId,
          route: reservation.route,
          date: reservation.date,
          status: 'confirmed',
          seatNumber: reservation.seatNumber,
          pickupPoint: reservation.pickupPoint,
          dropPoint: reservation.dropPoint,
        );
        // Send notification to student
        await _supabaseService.createNotification({
          'user_id': reservation.userId,
          'title': 'Reservation Confirmed',
          'message': 'Your reservation has been confirmed by the admin.',
          'type': 'success',
        });
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to confirm reservation: ${e.toString()}';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectReservation(String reservationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService
          .updateReservation(reservationId, {'status': 'cancelled'});
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        final reservation = _reservations[index];
        _reservations[index] = Reservation(
          id: reservation.id,
          userId: reservation.userId,
          route: reservation.route,
          date: reservation.date,
          status: 'cancelled',
          seatNumber: reservation.seatNumber,
          pickupPoint: reservation.pickupPoint,
          dropPoint: reservation.dropPoint,
        );
        // Send notification to student
        await _supabaseService.createNotification({
          'user_id': reservation.userId,
          'title': 'Reservation Cancelled',
          'message': 'Your reservation has been cancelled by the admin.',
          'type': 'alert',
        });
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reject reservation: ${e.toString()}';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
