import 'package:flutter/foundation.dart';
import '../models/bus_reservation.dart';
import '../models/reservation.dart';
import '../models/bus_route.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReservationProvider with ChangeNotifier {
  List<BusReservation> _currentReservations = [];
  List<BusReservation> _historyReservations = [];
  bool _isLoading = false;
  String? _error;

  // Expose as Reservation objects for the app
  List<Reservation> get currentReservations =>
      _currentReservations.map(_busReservationToReservation).toList();
  List<Reservation> get historyReservations =>
      _historyReservations.map(_busReservationToReservation).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  ReservationProvider() {
    _loadReservations();
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    // Check for completed reservations every minute
    Future.delayed(const Duration(minutes: 1), () {
      moveCompletedReservations();
      _startPeriodicUpdates();
    });
  }

  Future<void> _loadReservations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentReservationsJson = prefs.getString('current_reservations');
      final historyReservationsJson = prefs.getString('history_reservations');

      if (currentReservationsJson != null) {
        final List<dynamic> currentList = json.decode(currentReservationsJson);
        _currentReservations =
            currentList.map((json) => BusReservation.fromJson(json)).toList();
      }

      if (historyReservationsJson != null) {
        final List<dynamic> historyList = json.decode(historyReservationsJson);
        _historyReservations =
            historyList.map((json) => BusReservation.fromJson(json)).toList();
      }
    } catch (e) {
      _error = 'Failed to load reservations: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveReservations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'current_reservations',
        json.encode(_currentReservations.map((r) => r.toJson()).toList()),
      );
      await prefs.setString(
        'history_reservations',
        json.encode(_historyReservations.map((r) => r.toJson()).toList()),
      );
    } catch (e) {
      _error = 'Failed to save reservations: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> createReservation({
    required String routeName,
    required String routeCode,
    required DateTime date,
    required String time,
    required String pickup,
    required String dropoff,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate inputs
      if (date.isBefore(DateTime.now())) {
        throw Exception('Cannot create reservation for past dates');
      }

      // Generate a unique ID (in a real app, this would come from the backend)
      final id = DateTime.now().millisecondsSinceEpoch % 10000;

      final reservation = BusReservation(
        id: id,
        routeName: routeName,
        routeCode: routeCode,
        date: date,
        time: time,
        pickup: pickup,
        dropoff: dropoff,
        seatNumber: 'A${id % 20 + 1}', // Mock seat number
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      _currentReservations.add(reservation);
      await _saveReservations();

      // TODO: Implement notification logic for reservation confirmation and reminder
      // await NotificationService.showReservationConfirmationNotification(reservation);
      // await NotificationService.scheduleReservationReminder(reservation);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create reservation: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelReservation(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final index = _currentReservations.indexWhere((res) => res.id == id);
      if (index != -1) {
        final reservation = _currentReservations[index];
        final cancelledReservation = BusReservation(
          id: reservation.id,
          routeName: reservation.routeName,
          routeCode: reservation.routeCode,
          date: reservation.date,
          time: reservation.time,
          pickup: reservation.pickup,
          dropoff: reservation.dropoff,
          seatNumber: reservation.seatNumber,
          status: 'cancelled',
          createdAt: reservation.createdAt,
        );

        _currentReservations.removeAt(index);
        _historyReservations.add(cancelledReservation);
        await _saveReservations();

        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('Reservation not found');
      }
    } catch (e) {
      _error = 'Failed to cancel reservation: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> moveCompletedReservations() async {
    try {
      final now = DateTime.now();
      final completedReservations = _currentReservations.where((res) {
        final reservationDateTime = DateTime(
          res.date.year,
          res.date.month,
          res.date.day,
          int.parse(res.time.split(':')[0]),
          int.parse(res.time.split(':')[1].split(' ')[0]),
        );
        return reservationDateTime.isBefore(now);
      }).toList();

      for (var res in completedReservations) {
        final completedReservation = BusReservation(
          id: res.id,
          routeName: res.routeName,
          routeCode: res.routeCode,
          date: res.date,
          time: res.time,
          pickup: res.pickup,
          dropoff: res.dropoff,
          seatNumber: res.seatNumber,
          status: 'completed',
          createdAt: res.createdAt,
        );

        _currentReservations.remove(res);
        _historyReservations.add(completedReservation);
      }

      if (completedReservations.isNotEmpty) {
        await _saveReservations();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update completed reservations: ${e.toString()}';
      notifyListeners();
    }
  }

  // Mapping from BusReservation to Reservation for app use
  Reservation _busReservationToReservation(BusReservation busRes) {
    // TODO: Fetch the actual BusRoute object by code/name if needed
    final route = BusRoute(
      id: busRes.routeCode,
      name: busRes.routeName,
      pickup: '',
      drop: '',
      startTime: '',
      endTime: '',
      stops: const [],
      iconColor: '000000',
    );
    return Reservation(
      id: busRes.id.toString(),
      route: route,
      date: busRes.date.toIso8601String(),
      status: busRes.status,
      seatNumber: busRes.seatNumber,
      pickupPoint: busRes.pickup,
      dropPoint: busRes.dropoff,
    );
  }
}
