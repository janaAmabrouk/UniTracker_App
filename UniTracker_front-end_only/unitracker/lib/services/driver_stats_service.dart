import 'package:flutter/foundation.dart';
import '../models/driver_stats.dart';
import '../models/driver_activity.dart';
import 'driver_service.dart';

class DriverStatsService extends ChangeNotifier {
  DriverStats? _driverStats;
  List<DriverActivity> _activities = [];
  bool _isLoading = false;

  DriverStats? get driverStats => _driverStats;
  List<DriverActivity> get activities => List.unmodifiable(_activities);
  bool get isLoading => _isLoading;

  // Load driver stats from Supabase
  Future<void> loadDriverStats(String driverId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DriverService.instance.loadDriverData(driverId);
      _driverStats = DriverService.instance.driverStats;
      _activities = DriverService.instance.tripHistory;
    } catch (e) {
      debugPrint('Error loading driver stats: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get recent activities (last 7 days by default)
  List<DriverActivity> getRecentActivities({int days = 7}) {
    final DateTime cutoff = DateTime.now().subtract(Duration(days: days));
    return _activities
        .where((activity) => activity.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Update driver stats (e.g., after completing a trip)
  Future<void> updateStats({
    int? newTrips,
    double? newRating,
    double? newOnTimePerformance,
    double? newSafetyScore,
    double? newCustomerSatisfaction,
  }) async {
    if (_driverStats == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      _driverStats = DriverStats(
        totalTrips: newTrips ?? _driverStats!.totalTrips,
        completedTrips: _driverStats!.completedTrips,
        rating: newRating ?? _driverStats!.rating,
        onTimePerformance:
            newOnTimePerformance ?? _driverStats!.onTimePerformance,
        safetyScore: newSafetyScore ?? _driverStats!.safetyScore,
        customerSatisfaction:
            newCustomerSatisfaction ?? _driverStats!.customerSatisfaction,
        joinedDate: _driverStats!.joinedDate,
      );
    } catch (e) {
      debugPrint('Error updating driver stats: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new activity
  Future<void> addActivity(DriverActivity activity) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));
      _activities.insert(0, activity);
    } catch (e) {
      debugPrint('Error adding activity: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get performance summary for a specific metric
  double getPerformanceMetric(String metric) {
    if (_driverStats == null) return 0.0;

    switch (metric) {
      case 'onTime':
        return _driverStats!.onTimePerformance;
      case 'safety':
        return _driverStats!.safetyScore;
      case 'satisfaction':
        return _driverStats!.customerSatisfaction;
      default:
        return 0.0;
    }
  }

  // Calculate trip completion rate
  double getTripCompletionRate() {
    if (_activities.isEmpty) return 0.0;

    final completedTrips = _activities
        .where((a) =>
            a.type == DriverActivityType.tripCompleted &&
            a.status == DriverActivityStatus.completed)
        .length;

    final totalTrips = _activities
        .where((a) => a.type == DriverActivityType.tripCompleted)
        .length;

    return totalTrips > 0 ? (completedTrips / totalTrips) * 100 : 0.0;
  }
}
