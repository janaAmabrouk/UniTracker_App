import 'package:flutter/material.dart';
import 'package:location/location.dart';

class LocationService extends ChangeNotifier {
  final Location _location = Location();
  LocationData? _currentLocation;
  bool _serviceEnabled = false;
  bool _hasPermission = false;

  LocationData? get currentLocation => _currentLocation;
  bool get hasPermission => _hasPermission;

  Future<bool> initialize() async {
    // Check if location service is enabled
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    // Request location permission
    PermissionStatus permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
    }

    _hasPermission = permissionStatus == PermissionStatus.granted;

    if (_hasPermission) {
      // Configure location settings
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 1000, // Update interval in milliseconds
        distanceFilter: 10, // Minimum distance (meters) before updates
      );

      // Get initial location
      try {
        _currentLocation = await _location.getLocation();
        notifyListeners();
      } catch (e) {
        debugPrint('Error getting initial location: $e');
      }

      // Listen to location changes
      _location.onLocationChanged.listen((LocationData locationData) {
        _currentLocation = locationData;
        notifyListeners();
      });
    }

    return _hasPermission;
  }

  void stopLocationUpdates() {
    _location.enableBackgroundMode(enable: false);
  }
}
