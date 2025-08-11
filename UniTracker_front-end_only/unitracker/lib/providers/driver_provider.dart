import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/driver_stats.dart';
import '../models/driver_activity.dart';
import '../services/supabase_service.dart';

class DriverProvider extends ChangeNotifier {
  Driver? _driver;
  DriverStats? _stats;
  List<DriverActivity> _activities = [];
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = false;
  String? _error;

  Driver? get driver => _driver;
  DriverStats? get stats => _stats;
  List<DriverActivity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load real driver data from Supabase
  Future<void> loadDriverData(String driverId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load driver profile
      await _loadDriverProfile(driverId);

      // Load driver statistics
      await _loadDriverStats(driverId);

      // Load driver activities
      await _loadDriverActivities(driverId);

      debugPrint('✅ Driver data loaded successfully');
    } catch (e) {
      _error = 'Failed to load driver data: $e';
      debugPrint('❌ Error loading driver data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDriverProfile(String driverId) async {
    final response = await _supabaseService.client
        .from('drivers')
        .select('*')
        .eq('id', driverId)
        .single();

    _driver = Driver(
      id: response['id'] as String,
      name: response['name'] as String,
      driverId: response['driver_id'] as String,
      licenseNumber: response['license_number'] as String? ?? '',
      licenseExpirationDate: response['license_expiry_date'] != null
          ? DateTime.parse(response['license_expiry_date'] as String)
          : DateTime.now().add(const Duration(days: 365)),
      licenseImagePath: response['license_image_url'] as String? ?? '',
      profileImage: response['profile_image_url'] as String?,
      isAvailable: response['is_available'] as bool? ?? false,
      currentRouteId: response['current_route_id'] as String?,
      currentBusId: response['current_bus_id'] as String?,
      isLocalImage: false,
    );
  }

  Future<void> _loadDriverStats(String driverId) async {
    try {
      final response = await _supabaseService.client
          .from('driver_statistics')
          .select('*')
          .eq('driver_id', driverId)
          .maybeSingle();

      if (response != null) {
        final totalTrips = response['total_trips'] as int? ?? 0;
        final onTimeTrips = response['on_time_trips'] as int? ?? 0;
        final onTimePerformance =
            totalTrips > 0 ? (onTimeTrips / totalTrips) * 100 : 100.0;

        _stats = DriverStats(
          totalTrips: totalTrips,
          completedTrips: response['completed_trips'] as int? ?? 0,
          rating: (response['rating'] as num?)?.toDouble() ?? 5.0,
          onTimePerformance: onTimePerformance,
          safetyScore: (response['safety_score'] as num?)?.toDouble() ?? 100.0,
          customerSatisfaction: 95.0, // Calculate from ratings if available
          joinedDate: DateTime.parse(response['created_at'] as String),
        );
      } else {
        // Create default stats if none exist
        await _createDefaultStats(driverId);
        _stats = DriverStats(
          totalTrips: 0,
          completedTrips: 0,
          rating: 5.0,
          onTimePerformance: 100.0,
          safetyScore: 100.0,
          customerSatisfaction: 100.0,
          joinedDate: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading driver stats: $e');
      // Use default stats
      _stats = DriverStats(
        totalTrips: 0,
        completedTrips: 0,
        rating: 5.0,
        onTimePerformance: 100.0,
        safetyScore: 100.0,
        customerSatisfaction: 100.0,
        joinedDate: DateTime.now(),
      );
    }
  }

  Future<void> _createDefaultStats(String driverId) async {
    try {
      await _supabaseService.client.from('driver_statistics').insert({
        'driver_id': driverId,
        'total_trips': 0,
        'completed_trips': 0,
        'cancelled_trips': 0,
        'on_time_trips': 0,
        'late_trips': 0,
        'rating': 5.0,
        'safety_score': 100.0,
      });
      debugPrint('✅ Default driver statistics created');
    } catch (e) {
      debugPrint('❌ Error creating default stats: $e');
    }
  }

  Future<void> _loadDriverActivities(String driverId) async {
    try {
      final response = await _supabaseService.client
          .from('trip_history')
          .select('*')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false)
          .limit(20);

      _activities = (response as List<dynamic>).map((activity) {
        return DriverActivity(
          id: activity['id'] as String,
          type: _getActivityType(activity['status'] as String?),
          description:
              'Trip ${activity['route_name'] ?? 'Unknown Route'} - Status: ${activity['status'] ?? 'Unknown'}',
          timestamp: DateTime.parse(activity['created_at'] as String),
          status: _getActivityStatus(activity['status'] as String?),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error loading driver activities: $e');
      _activities = [];
    }
  }

  DriverActivityType _getActivityType(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return DriverActivityType.tripCompleted;
      case 'started':
        return DriverActivityType.routeAssigned;
      case 'cancelled':
        return DriverActivityType.statusChanged;
      default:
        return DriverActivityType.statusChanged;
    }
  }

  DriverActivityStatus _getActivityStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return DriverActivityStatus.completed;
      case 'started':
        return DriverActivityStatus.inProgress;
      case 'cancelled':
        return DriverActivityStatus.cancelled;
      default:
        return DriverActivityStatus.scheduled;
    }
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
