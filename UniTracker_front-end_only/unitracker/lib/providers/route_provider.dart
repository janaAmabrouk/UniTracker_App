import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../services/supabase_service.dart';

class RouteProvider with ChangeNotifier {
  List<BusRoute> _routes = [];
  bool _isLoading = false;
  String? _error;
  Timer? _updateTimer;
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<BusRoute> get routes => List.unmodifiable(_routes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  RouteProvider() {
    _loadRoutes();
    _startRouteUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startRouteUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateRouteLocations();
    });
  }

  void _updateRouteLocations() {
    // TODO: Add location update logic if BusStop includes latitude/longitude in the future
    // For now, this is a placeholder
    notifyListeners();
  }

  Future<void> _loadRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final routesData = await _supabaseService.getRoutes();
      _routes = routesData.map((data) => _mapSupabaseToRoute(data)).toList();

      // If no routes from database, load sample data
      if (_routes.isEmpty) {
        _loadSampleRoutes();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading routes from database: $e');
      _loadSampleRoutes();
      _error = null; // Don't show error, just use sample data
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadSampleRoutes() {
    // Clear existing routes first to avoid duplicates
    _routes.clear();
    _routes = [];
    // Ensure no duplicates by filtering unique IDs
    final uniqueRoutes = <String, BusRoute>{};
    for (final route in _routes) {
      uniqueRoutes[route.id] = route;
    }
    _routes = uniqueRoutes.values.toList();
  }

  BusRoute _mapSupabaseToRoute(Map<String, dynamic> data) {
    final stopsData = data['bus_stops'] as List<dynamic>? ?? [];
    final stops = stopsData
        .map((stopData) => BusStop(
              id: stopData['id'] as String,
              name: stopData['name'] as String,
              order: stopData['stop_order'] as int,
              arrivalTime: stopData['estimated_arrival_time']?.toString(),
              departureTime: stopData['estimated_arrival_time']?.toString(),
            ))
        .toList();

    // Sort stops by order
    stops.sort((a, b) => a.order.compareTo(b.order));

    return BusRoute(
      id: data['id'] as String,
      name: data['name'] as String,
      pickup: data['pickup_location'] as String,
      drop: data['drop_location'] as String,
      startTime: _formatTime(data['start_time'] as String),
      endTime: _formatTime(data['end_time'] as String),
      stops: stops,
      iconColor: data['color_code'] as String? ?? '2196F3',
    );
  }

  String _formatTime(String timeString) {
    // Convert 24-hour format to 12-hour format with AM/PM
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

  BusRoute? getRouteById(String id) {
    try {
      return _routes.firstWhere((route) => route.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateRouteLocation(String id, double latitude, double longitude) {
    // TODO: Implement location update if BusStop includes latitude/longitude in the future
    notifyListeners();
  }

  void updateRouteStatus(String id, String status) {
    // This method can be implemented if you add a status field to BusRoute
    // For now, it's a placeholder
    notifyListeners();
  }

  Future<void> refreshRoutes() async {
    await _loadRoutes();
  }

  Future<void> loadRoutes() async {
    await _loadRoutes();
  }

  void toggleFavorite(String routeId) {
    final routeIndex = _routes.indexWhere((route) => route.id == routeId);
    if (routeIndex != -1) {
      final currentRoute = _routes[routeIndex];
      _routes[routeIndex] = BusRoute(
        id: currentRoute.id,
        name: currentRoute.name,
        pickup: currentRoute.pickup,
        drop: currentRoute.drop,
        startTime: currentRoute.startTime,
        endTime: currentRoute.endTime,
        iconColor: currentRoute.iconColor,
        stops: currentRoute.stops,
        isFavorite: !currentRoute.isFavorite,
      );
      notifyListeners();
    }
  }
}
