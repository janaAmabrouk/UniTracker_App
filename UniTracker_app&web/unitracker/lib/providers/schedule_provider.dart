import 'package:flutter/foundation.dart';
import '../models/bus_schedule.dart';

class ScheduleProvider with ChangeNotifier {
  List<BusSchedule> _schedules = [];
  bool _isLoading = false;
  String? _error;

  List<BusSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<BusSchedule> get favoriteSchedules =>
      _schedules.where((s) => s.isFavorite).toList();

  Future<void> loadSchedules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data - in a real app, this would be fetched from an API
      _schedules = [
        BusSchedule(
          name: 'Ain Shams Line',
          id: 'BA123',
          morningPickupTime: '07:15 AM',
          morningDropTime: '08:30 AM',
          afternoonPickupTime: '12:15 PM',
          afternoonDropTime: '01:30 PM',
          eveningPickupTime: '04:15 PM',
          eveningDropTime: '05:30 PM',
          pickup: 'Ain Shams',
          drop: 'EUI Campus',
          isFavorite: true,
          afternoonRoute: true,
        ),
        BusSchedule(
          name: 'Shubra Express',
          id: 'BA124',
          morningPickupTime: '06:30 AM',
          morningDropTime: '08:00 AM',
          afternoonPickupTime: '12:30 PM',
          afternoonDropTime: '02:00 PM',
          eveningPickupTime: '04:30 PM',
          eveningDropTime: '06:00 PM',
          pickup: 'Shubra',
          drop: 'EUI Campus',
          afternoonRoute: true,
        ),
        BusSchedule(
          name: 'Maadi Shuttle',
          id: 'BA125',
          morningPickupTime: '07:00 AM',
          morningDropTime: '08:15 AM',
          afternoonPickupTime: '12:00 PM',
          afternoonDropTime: '01:15 PM',
          eveningPickupTime: '04:00 PM',
          eveningDropTime: '05:15 PM',
          pickup: 'Maadi',
          drop: 'EUI Campus',
          afternoonRoute: false,
        ),
      ];
    } catch (e) {
      _error = 'Failed to load schedules: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleFavorite(String id) {
    final scheduleIndex = _schedules.indexWhere((s) => s.id == id);
    if (scheduleIndex != -1) {
      _schedules[scheduleIndex].isFavorite =
          !_schedules[scheduleIndex].isFavorite;
      notifyListeners();
    }
  }

  List<BusSchedule> filterSchedules({
    required String searchQuery,
    required String timeFilter,
    required bool showFavorites,
  }) {
    return _schedules.where((schedule) {
      // Apply search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!schedule.name.toLowerCase().contains(query) &&
            !schedule.pickup.toLowerCase().contains(query) &&
            !schedule.drop.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Apply favorites filter
      if (showFavorites && !schedule.isFavorite) {
        return false;
      }

      // Apply time filter
      switch (timeFilter) {
        case 'Morning':
          return schedule.morningPickupTime.isNotEmpty;
        case 'Afternoon':
          return schedule.afternoonRoute;
        case 'Evening':
          return schedule.eveningPickupTime.isNotEmpty;
        default:
          return true;
      }
    }).toList();
  }
}
