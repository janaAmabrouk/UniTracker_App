import 'package:flutter/foundation.dart';
import 'package:unitracker/models/bus_route.dart';
import 'package:unitracker/models/reservation.dart';
import 'package:unitracker/services/notification_service.dart';
import 'package:unitracker/services/notification_settings_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/driver_notification.dart';

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
  late final List<Reservation> _reservations;
  static const int maxSeatsPerBus = 12;

  ReservationService._internal(
      this._notificationService, this._notificationSettingsService) {
    _reservations = [];
  }

  // Getter for reservations (immutable copy)
  List<Reservation> get reservations => List.unmodifiable(_reservations);

  // Check if time is morning hours (before 12 PM)
  bool _isMorningHours(DateTime time) {
    return time.hour < 12;
  }

  // Check if user has existing reservation for the same time period on the same day
  bool _hasExistingReservation(DateTime newReservationTime) {
    final bool isNewReservationMorning = _isMorningHours(newReservationTime);
    final existingReservations = _reservations.where((reservation) {
      try {
        final existingReservationTime = DateTime.parse(reservation.date);
        // Check if it's the same day
        if (existingReservationTime.year == newReservationTime.year &&
            existingReservationTime.month == newReservationTime.month &&
            existingReservationTime.day == newReservationTime.day) {
          // Check if both reservations are in the same time period (morning/evening)
          final bool isExistingMorning =
              _isMorningHours(existingReservationTime);
          return isExistingMorning == isNewReservationMorning &&
              reservation.status != 'cancelled';
        }
        return false;
      } catch (e) {
        return false;
      }
    });

    return existingReservations.isNotEmpty;
  }

  // Cancel a reservation
  Future<void> cancelReservation(String reservationId) async {
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

        _reservations[index] = Reservation(
          id: reservation.id,
          route: reservation.route,
          date: reservation.date,
          status: 'cancelled',
          seatNumber: reservation.seatNumber,
          pickupPoint: reservation.pickupPoint,
          dropPoint: reservation.dropPoint,
        );

        // Send cancellation notification if enabled
        if (_notificationSettingsService.reservationUpdatesEnabled) {
          _notificationService.addNotification(
            title: 'Reservation Cancelled',
            message:
                'Your reservation for ${DateFormat('MMM d').format(reservationDateTime)} at ${DateFormat('h:mm a').format(reservationDateTime)} has been cancelled.',
            type: NotificationType.alert,
            data: {
              'routeName': reservation.route.name,
              'date': reservation.date,
              'pickupPoint': reservation.pickupPoint,
              'dropPoint': reservation.dropPoint,
            },
          );
        }

        notifyListeners();
      } else {
        throw Exception('Reservation not found');
      }
    } catch (e) {
      throw Exception('Failed to cancel reservation: $e');
    }
  }

  // Get the next available seat number for a specific route and date
  int _getNextAvailableSeatNumber(String routeId, String date) {
    final existingSeats = _reservations
        .where((r) =>
            r.route.id == routeId && r.date == date && r.status != 'cancelled')
        .map((r) => int.tryParse(r.seatNumber) ?? 0)
        .toList();

    if (existingSeats.isEmpty) return 1;

    // Sort seats to find gaps
    existingSeats.sort();

    // Find first available number
    for (int i = 1; i <= maxSeatsPerBus; i++) {
      if (!existingSeats.contains(i)) {
        return i;
      }
    }

    throw Exception('No seats available');
  }

  Future<Reservation> createReservation({
    required BusRoute route,
    required String date,
    required String pickupPoint,
    required String dropPoint,
  }) async {
    try {
      // Parse the reservation date and time
      final reservationDateTime = DateTime.parse(date);
      final now = DateTime.now();

      // Check if the reservation time has already passed
      if (reservationDateTime.isBefore(now)) {
        throw Exception(
            'Cannot make reservations for past times. Please select a future time.');
      }

      // Check for existing reservation in the same time period
      if (_hasExistingReservation(reservationDateTime)) {
        final period =
            _isMorningHours(reservationDateTime) ? 'morning' : 'evening';
        throw Exception(
            'You already have a reservation for the $period. Only one reservation per time period is allowed.');
      }

      // Get next available seat number
      final seatNumber = _getNextAvailableSeatNumber(route.id, date);

      // Check if seats are available
      if (seatNumber > maxSeatsPerBus) {
        throw Exception('No seats available for this trip');
      }

      // Convert University to EUI Campus in dropPoint if needed
      final adjustedDropPoint =
          dropPoint == 'University' ? 'EUI Campus' : dropPoint;

      final reservation = Reservation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        route: route,
        date: reservationDateTime.toIso8601String(),
        status: 'confirmed',
        seatNumber: seatNumber.toString(),
        pickupPoint: pickupPoint,
        dropPoint: adjustedDropPoint,
      );

      _reservations.add(reservation);

      // Only send notification if reservation updates are enabled
      if (_notificationSettingsService.reservationUpdatesEnabled) {
        _notificationService.addNotification(
          title: 'Reservation Confirmed',
          message:
              'Your reservation for ${DateFormat('MMM d').format(reservationDateTime)} at ${DateFormat('h:mm a').format(reservationDateTime)} has been confirmed.',
          type: NotificationType.alert,
          data: {
            'routeName': route.name,
            'date': reservation.date,
            'pickupPoint': pickupPoint,
            'dropPoint': adjustedDropPoint,
          },
        );
      }

      notifyListeners();
      return reservation;
    } catch (e) {
      throw Exception('Failed to create reservation: $e');
    }
  }

  int getRemainingSeats(String routeId, String dateTime) {
    final reservations = _reservations
        .where((r) =>
            r.route.id == routeId &&
            r.date == dateTime &&
            r.status != 'cancelled')
        .length;

    return maxSeatsPerBus - reservations;
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
}
