import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/driver_stats.dart';
import '../models/driver_activity.dart';

class DriverProvider extends ChangeNotifier {
  Driver? _driver;
  DriverStats? _stats;
  List<DriverActivity> _activities = [];

  Driver? get driver => _driver;
  DriverStats? get stats => _stats;
  List<DriverActivity> get activities => _activities;

  // Mock initialization for demo
  void loadMockData() {
    _driver = Driver(
      id: '1',
      name: 'Mohamed Hamdy',
      driverId: 'DRV-12345',
      licenseNumber: 'LIC-987654',
      licenseExpirationDate: DateTime(2025, 6, 30),
      licenseImagePath: '',
      profileImage: null,
      isAvailable: false,
      currentRouteId: null,
      currentBusId: null,
      isLocalImage: false,
    );
    _stats = DriverStats(
      totalTrips: 120,
      rating: 4.8,
      onTimePerformance: 93.2,
      safetyScore: 89.5,
      customerSatisfaction: 96.7,
      joinedDate: DateTime(2022, 9, 15),
    );
    _activities = DriverActivity.getMockActivities();
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? licenseNumber,
    DateTime? licenseExpirationDate,
    String? profileImage,
    bool? isLocalImage,
  }) {
    if (_driver != null) {
      _driver = _driver!.copyWith(
        name: name,
        licenseNumber: licenseNumber,
        licenseExpirationDate: licenseExpirationDate,
        profileImage: profileImage,
        isLocalImage: isLocalImage,
      );
      notifyListeners();
    }
  }

  void setDriver(Driver driver) {
    _driver = driver;
    notifyListeners();
  }

  void setStats(DriverStats stats) {
    _stats = stats;
    notifyListeners();
  }

  void addActivity(DriverActivity activity) {
    _activities.insert(0, activity); // Add to the top
    notifyListeners();
  }

  // Add more methods as needed (e.g., fetch from API, update stats, etc.)
}
