import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/driver_stats.dart';
import '../models/driver_activity.dart';
import 'supabase_service.dart';
import 'notification_settings_service.dart';

class DriverService extends ChangeNotifier {
  static DriverService? _instance;
  static DriverService get instance {
    _instance ??= DriverService._internal();
    return _instance!;
  }

  DriverService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  NotificationSettingsService? _notificationSettingsService;

  BusRoute? _assignedRoute;
  List<BusStop> _routeStops = [];
  DriverStats? _driverStats;
  List<DriverActivity> _tripHistory = [];
  bool _isLoading = false;
  String? _error;
  bool _isTripInProgress = false;
  DateTime? _tripStartTime;
  Map<String, dynamic>? _todaySchedule;
  int _currentStopIndex = 0;
  List<bool> _stopCheckIns = [];
  bool _isTripCompletedToday = false;

  // Getters
  BusRoute? get assignedRoute => _assignedRoute;
  List<BusStop> get routeStops => List.unmodifiable(_routeStops);
  DriverStats? get driverStats => _driverStats;
  List<DriverActivity> get tripHistory => List.unmodifiable(_tripHistory);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTripInProgress => _isTripInProgress;
  Map<String, dynamic>? get todaySchedule => _todaySchedule;
  int get currentStopIndex => _currentStopIndex;
  List<bool> get stopCheckIns => List.unmodifiable(_stopCheckIns);
  bool get hasScheduleToday => _todaySchedule != null;
  bool get canStartTrip =>
      _todaySchedule != null &&
      !_isTripInProgress &&
      _currentStopIndex == 0 &&
      !_isTripCompletedToday;
  bool get isLastStop => _currentStopIndex >= _routeStops.length - 1;
  bool get isTripCompletedToday => _isTripCompletedToday;

  // Get scheduled days as readable string
  String get scheduledDays {
    if (_todaySchedule == null) return 'No schedule';

    final daysOfWeek = _todaySchedule!['days_of_week'] as List<dynamic>?;
    if (daysOfWeek == null || daysOfWeek.isEmpty) return 'No days scheduled';

    final dayNames = daysOfWeek.map((day) => _getDayName(day as int)).toList();

    if (dayNames.length == 1) {
      return dayNames.first;
    } else if (dayNames.length == 2) {
      return '${dayNames[0]}\n& ${dayNames[1]}';
    } else {
      return '${dayNames.sublist(0, dayNames.length - 1).join(', ')}\n& ${dayNames.last}';
    }
  }

  Future<void> loadDriverData(String driverId) async {
    debugPrint('🚗 DriverService: Loading data for driver ID: $driverId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load driver assignment (route and bus)
      debugPrint('🚗 DriverService: Loading driver assignment...');
      await _loadDriverAssignment(driverId);

      // Check today's schedule
      debugPrint('🚗 DriverService: Checking today\'s schedule...');
      try {
        await _checkTodaySchedule(driverId);
      } catch (e) {
        debugPrint('❌ DriverService: Error in schedule check: $e');
        _todaySchedule = null;
      }

      // Check if trip was completed today
      await _checkTripCompletionToday(driverId);

      // Load driver statistics
      debugPrint('🚗 DriverService: Loading driver statistics...');
      await _loadDriverStats(driverId);

      // Load trip history
      debugPrint('🚗 DriverService: Loading trip history...');
      await _loadTripHistory(driverId);

      debugPrint('🚗 DriverService: Successfully loaded all driver data');
    } catch (e) {
      _error = 'Failed to load driver data: ${e.toString()}';
      debugPrint('❌ DriverService: Error loading driver data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDriverAssignment(String driverId) async {
    try {
      debugPrint('🚗 DriverService: Fetching assignment for driver: $driverId');
      final assignmentData = await _supabaseService.getDriverAssignment(
        driverId,
      );

      if (assignmentData != null) {
        debugPrint(
          '🚗 DriverService: Found assignment data: ${assignmentData.keys}',
        );
        final routeData = assignmentData['routes'] as Map<String, dynamic>;
        final routeId = routeData['id'] as String;
        debugPrint(
          '🚗 DriverService: Route ID: $routeId, Route Name: ${routeData['name']}',
        );

        // Get bus stops for this route separately
        final stopsData = await _supabaseService.client
            .from('bus_stops')
            .select('*')
            .eq('route_id', routeId)
            .order('stop_order', ascending: true);

        debugPrint(
          '🚗 DriverService: Found ${(stopsData as List).length} bus stops',
        );

        // Convert stops data
        final stops = (stopsData as List<dynamic>)
            .map(
              (stopData) => BusStop(
                id: stopData['id'] as String,
                name: stopData['name'] as String,
                order: stopData['stop_order'] as int,
                arrivalTime: stopData['estimated_arrival_time']?.toString(),
                departureTime: stopData['estimated_arrival_time']?.toString(),
              ),
            )
            .toList();

        // Sort stops by stop_order to ensure correct chronological order
        stops.sort((a, b) => a.order.compareTo(b.order));

        // Debug: Print stop order and times
        for (int i = 0; i < stops.length; i++) {
          debugPrint(
            '🚏 Stop ${i + 1}: ${stops[i].name} (Order: ${stops[i].order}, Time: ${stops[i].arrivalTime})',
          );
        }

        _assignedRoute = BusRoute(
          id: routeData['id'] as String,
          name: routeData['name'] as String,
          pickup: routeData['pickup_location'] as String,
          drop: routeData['drop_location'] as String,
          startTime: _formatTime(routeData['start_time'] as String),
          endTime: _formatTime(routeData['end_time'] as String),
          stops: stops,
          iconColor: routeData['color_code'] as String? ?? '2196F3',
        );

        _routeStops = stops;
        _stopCheckIns = List.filled(stops.length, false);
        debugPrint(
          '✅ DriverService: Successfully loaded route: ${_assignedRoute!.name}',
        );
      } else {
        debugPrint(
          '⚠️ DriverService: No assignment found for driver: $driverId',
        );
      }
    } catch (e) {
      debugPrint('❌ DriverService: Error loading driver assignment: $e');
      rethrow;
    }
  }

  Future<void> _checkTodaySchedule(String driverId) async {
    try {
      final today = DateTime.now();
      final dayOfWeek = today.weekday; // 1=Monday, 7=Sunday

      debugPrint(
        '🚗 DriverService: Checking schedule for day: $dayOfWeek (${_getDayName(dayOfWeek)})',
      );

      // Get driver assignment first
      final driverAssignment = await _supabaseService.getDriverAssignment(
        driverId,
      );
      debugPrint('🚗 DriverService: Driver assignment: $driverAssignment');

      if (driverAssignment != null) {
        final routeId = driverAssignment['route_id'];
        final busId = driverAssignment['bus_id'];

        debugPrint(
          '🚗 DriverService: Looking for schedule with route_id: $routeId, bus_id: $busId, day: $dayOfWeek',
        );

        // Get today's schedule for this driver
        final scheduleData = await _supabaseService.client
            .from('schedules')
            .select('''
              id,
              route_id,
              bus_id,
              departure_time,
              arrival_time,
              days_of_week,
              is_active,
              routes!inner(
                id,
                name
              ),
              buses!inner(
                id,
                bus_number
              )
            ''')
            .eq('is_active', true)
            .eq('route_id', routeId)
            .eq('bus_id', busId);

        debugPrint(
          '🚗 DriverService: Found ${(scheduleData as List).length} schedules for this route/bus',
        );

        // Filter by day of week
        final todaySchedules = scheduleData.where((schedule) {
          final daysOfWeek = schedule['days_of_week'] as List<dynamic>?;
          final hasToday = daysOfWeek?.contains(dayOfWeek) ?? false;
          debugPrint(
            '🚗 DriverService: Schedule ${schedule['id']} has days: $daysOfWeek, contains today ($dayOfWeek): $hasToday',
          );
          return hasToday;
        }).toList();

        if (todaySchedules.isNotEmpty) {
          _todaySchedule = todaySchedules.first;
          debugPrint(
            '✅ DriverService: Found schedule for today: ${_todaySchedule!['departure_time']} - ${_todaySchedule!['arrival_time']}',
          );
        } else {
          _todaySchedule = null;
          debugPrint(
            '⚠️ DriverService: No schedule found for today (${_getDayName(dayOfWeek)})',
          );
        }
      } else {
        _todaySchedule = null;
        debugPrint('⚠️ DriverService: No driver assignment found');
      }
    } catch (e) {
      debugPrint('❌ DriverService: Error checking today\'s schedule: $e');
      _todaySchedule = null;
    }
  }

  String _getDayName(int dayOfWeek) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek];
  }

  Future<void> _checkTripCompletionToday(String driverId) async {
    try {
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      debugPrint(
        '🔍 DriverService: Checking trip completion for date: $todayString',
      );

      // Only check for the currently assigned route
      final routeId = _assignedRoute?.id;
      debugPrint(
          '🔍 DriverService: Assigned route ID for trip completion check: $routeId');
      if (routeId == null) {
        _isTripCompletedToday = false;
        debugPrint(
            '⚠️ DriverService: No assigned route to check trip completion for.');
        return;
      }

      // Check if there's a completed trip for today for the current route in trip_history table
      final completedTrips = await _supabaseService.client
          .from('trip_history')
          .select('id, trip_date, status, route_id')
          .eq('driver_id', driverId)
          .eq('trip_date', todayString)
          .eq('status', 'completed')
          .eq('route_id', routeId);

      debugPrint(
          '🔍 DriverService: Completed trips query result: $completedTrips');
      _isTripCompletedToday = (completedTrips as List).isNotEmpty;
      debugPrint(
          '🔍 DriverService: _isTripCompletedToday = $_isTripCompletedToday');

      if (_isTripCompletedToday) {
        debugPrint(
          '✅ DriverService: Trip already completed today for route $routeId - found ${(completedTrips as List).length} completed trip(s)',
        );
      } else {
        debugPrint(
            '🚗 DriverService: No trip completed today yet for route $routeId');
      }
    } catch (e) {
      debugPrint('❌ DriverService: Error checking trip completion: $e');
      _isTripCompletedToday = false;
    }
  }

  Future<void> _loadDriverStats(String driverId) async {
    try {
      final statsData = await _supabaseService.getDriverStats(driverId);

      _driverStats = DriverStats(
        totalTrips: statsData['total_trips'] as int,
        completedTrips: statsData['completed_trips'] as int,
        rating: (statsData['rating'] as num).toDouble(),
        onTimePerformance: (statsData['on_time_performance'] as num).toDouble(),
        safetyScore: (statsData['safety_score'] as num).toDouble(),
        customerSatisfaction:
            (statsData['customer_satisfaction'] as num).toDouble(),
        joinedDate: DateTime.now().subtract(
          const Duration(days: 365),
        ), // Mock joined date
      );
    } catch (e) {
      debugPrint('Error loading driver stats: $e');
      rethrow;
    }
  }

  Future<void> _loadTripHistory(String driverId) async {
    try {
      final historyData = await _supabaseService.getDriverTripHistory(driverId);

      _tripHistory = historyData
          .map<DriverActivity>(
            (trip) => DriverActivity(
              id: trip['id'] as String,
              type: DriverActivityType.tripCompleted,
              description: 'Completed ${trip['routes']['name']} route',
              timestamp: DateTime.parse(trip['created_at'] as String),
              status: DriverActivityStatus.completed,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading trip history: $e');
      rethrow;
    }
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

  Future<void> startTrip() async {
    if (_assignedRoute == null) {
      throw Exception('No route assigned');
    }

    if (_todaySchedule == null) {
      throw Exception(
        'No schedule for today. This route is not scheduled for ${_getDayName(DateTime.now().weekday)}.',
      );
    }

    if (_isTripInProgress) {
      throw Exception('Trip already in progress');
    }

    if (_isTripCompletedToday) {
      throw Exception(
        'Trip already completed today. You can only complete one trip per day.',
      );
    }

    // Fetch driver profile and check isActive
    final currentUser = _supabaseService.currentUser;
    if (currentUser != null) {
      final driverProfile = await _supabaseService.client
          .from('drivers')
          .select('is_active')
          .eq('id', currentUser.id)
          .maybeSingle();
      if (driverProfile != null && driverProfile['is_active'] != true) {
        throw Exception(
            'Your account is inactive. Please contact the administrator.');
      }
    }

    debugPrint(
      '🚗 DriverService: Starting new trip for route: ${_assignedRoute!.name}',
    );

    _isTripInProgress = true;
    _tripStartTime = DateTime.now();
    _currentStopIndex = 0;
    _stopCheckIns = List.filled(_routeStops.length, false);
    notifyListeners();

    // Send notification about trip start
    if (currentUser != null &&
        (_notificationSettingsService?.routeDelaysEnabled ?? true)) {
      await _supabaseService.createNotification({
        'user_id': currentUser.id,
        'title': 'Trip Started',
        'message':
            'Started ${_assignedRoute!.name} route at ${_formatTime(DateTime.now().toString().split(' ')[1])}',
        'type': 'info',
      });
    }
  }

  Future<void> checkInAtStop(int stopIndex) async {
    if (!_isTripInProgress) {
      throw Exception('No trip in progress');
    }

    if (stopIndex != _currentStopIndex) {
      throw Exception(
        'Must check in at stops in order. Next stop: ${_routeStops[_currentStopIndex].name}',
      );
    }

    if (stopIndex >= _routeStops.length) {
      throw Exception('Invalid stop index');
    }

    _stopCheckIns[stopIndex] = true;
    _currentStopIndex = stopIndex + 1;
    notifyListeners();

    final currentUser = _supabaseService.currentUser;
    if (currentUser != null &&
        (_notificationSettingsService?.routeDelaysEnabled ?? true)) {
      await _supabaseService.createNotification({
        'user_id': currentUser.id,
        'title': 'Stop Check-in',
        'message': 'Checked in at ${_routeStops[stopIndex].name}',
        'type': 'info',
      });
    }

    // If this was the last stop, complete the trip automatically
    if (stopIndex >= _routeStops.length - 1) {
      await _autoCompleteTrip();
    }
  }

  Future<void> _autoCompleteTrip() async {
    if (!_isTripInProgress ||
        _tripStartTime == null ||
        _assignedRoute == null) {
      return;
    }

    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      // Get driver assignment to get bus ID
      final assignment = await _supabaseService.getDriverAssignment(
        currentUser.id,
      );
      if (assignment == null) {
        throw Exception('No active assignment found');
      }

      // Complete trip in database
      await _supabaseService.completeTrip(
        driverId: currentUser.id,
        routeId: _assignedRoute!.id,
        busId: assignment['bus_id'] as String,
        startTime: _tripStartTime!,
        endTime: DateTime.now(),
        passengerCount: 0, // Will be updated if needed
        distanceKm: 0.0, // Will be calculated if needed
        onTime: true, // Assume on time for auto-completion
        notes: 'Trip completed automatically after all stops',
      );

      // Update local state
      _isTripInProgress = false;
      _tripStartTime = null;
      _currentStopIndex = 0;
      _isTripCompletedToday = true;
      notifyListeners();

      // Reload driver data to reflect new trip statistics
      await loadDriverData(currentUser.id);

      // Send completion notification
      if (_notificationSettingsService?.routeDelaysEnabled ?? true) {
        await _supabaseService.createNotification({
          'user_id': currentUser.id,
          'title': 'Trip Completed',
          'message':
              'Successfully completed ${_assignedRoute!.name} route - all stops checked in',
          'type': 'success',
        });
      }

      debugPrint('✅ DriverService: Trip auto-completed successfully');
    } catch (e) {
      debugPrint('Error auto-completing trip: $e');
    }
  }

  Future<void> completeTrip({
    required int passengerCount,
    required double distanceKm,
    required bool onTime,
    String? notes,
  }) async {
    if (!_isTripInProgress ||
        _tripStartTime == null ||
        _assignedRoute == null) {
      throw Exception('No trip in progress');
    }

    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Get driver assignment to get bus ID
      final assignment = await _supabaseService.getDriverAssignment(
        currentUser.id,
      );
      if (assignment == null) {
        throw Exception('No active assignment found');
      }

      // Complete trip in database
      await _supabaseService.completeTrip(
        driverId: currentUser.id,
        routeId: _assignedRoute!.id,
        busId: assignment['bus_id'] as String,
        startTime: _tripStartTime!,
        endTime: DateTime.now(),
        passengerCount: passengerCount,
        distanceKm: distanceKm,
        onTime: onTime,
        notes: notes,
      );

      // Update local state
      _isTripInProgress = false;
      _tripStartTime = null;
      _isTripCompletedToday = true;

      // Reload driver data to reflect new trip
      await loadDriverData(currentUser.id);

      // Send completion notification
      if (_notificationSettingsService?.routeDelaysEnabled ?? true) {
        await _supabaseService.createNotification({
          'user_id': currentUser.id,
          'title': 'Trip Completed',
          'message':
              'Successfully completed ${_assignedRoute!.name} route with $passengerCount passengers',
          'type': 'success',
        });
      }
    } catch (e) {
      _error = 'Failed to complete trip: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required double speed,
    required bool isMoving,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return;

    try {
      await _supabaseService.updateDriverLocation(
        driverId: currentUser.id,
        latitude: latitude,
        longitude: longitude,
        speed: speed,
        isMoving: isMoving,
      );
    } catch (e) {
      debugPrint('Error updating driver location: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setNotificationSettingsService(NotificationSettingsService service) {
    _notificationSettingsService = service;
  }
}
