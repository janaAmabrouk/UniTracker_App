import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';

class RouteProvider with ChangeNotifier {
  List<BusRoute> _routes = [];
  bool _isLoading = false;
  String? _error;
  Timer? _updateTimer;

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
      await Future.delayed(const Duration(seconds: 1));
      _routes = [
        BusRoute(
          id: 'maadi',
          name: 'Maadi Route',
          pickup: 'El Cornishe HSBC Bank',
          drop: 'EUI Campus',
          startTime: '07:20 AM',
          endTime: '08:45 AM',
          stops: [
            const BusStop(id: '1', name: 'El Cornishe HSBC Bank', order: 1),
            const BusStop(id: '2', name: 'Military Hospital', order: 2),
            const BusStop(id: '3', name: 'House of Donuts', order: 3),
            const BusStop(id: '4', name: 'El Horia Square', order: 4),
            const BusStop(id: '5', name: 'Victoria Square', order: 5),
            const BusStop(id: '6', name: 'Vodafone ElZahraa', order: 6),
            const BusStop(id: '7', name: 'Hub 50 Mall', order: 7),
            const BusStop(id: '8', name: 'IMS School', order: 8),
            const BusStop(id: '9', name: 'Becho American City', order: 9),
            const BusStop(id: '10', name: 'EUI Campus', order: 10),
          ],
          iconColor: '2196F3', // Blue color
        ),
      ];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load routes: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
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
}
