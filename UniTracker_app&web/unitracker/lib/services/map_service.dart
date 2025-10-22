import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/map_location.dart';
import '../models/bus_route.dart';
import '../models/bus_schedule.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService extends ChangeNotifier {
  final Map<String, List<MapLocation>> _routeLocations = {};
  final Map<String, StreamController<MapLocation>> _busLocationControllers = {};
  Timer? _updateTimer;
  bool _isInitialized = false;

  // Constants for calculations
  static const double averageSpeed = 40.0; // km/h
  static const double stopDuration = 3.0; // minutes
  static const double earthRadius = 6371.0; // km

  // Google Maps API configuration
  static const String baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  // TODO: Replace with your actual API key
  static const String apiKey = 'AIzaSyBrsMZk0tAIpmjIjyhAZdPZAdEGvCmS_Lw';

  Map<String, List<MapLocation>> get routeLocations =>
      Map.unmodifiable(_routeLocations);
  bool get isInitialized => _isInitialized;

  MapService() {
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateLocations();
    });
  }

  Stream<MapLocation> getBusLocationStream(String busId) {
    if (!_busLocationControllers.containsKey(busId)) {
      _busLocationControllers[busId] =
          StreamController<MapLocation>.broadcast();
    }
    return _busLocationControllers[busId]!.stream;
  }

  void _updateLocations() {
    for (var entry in _routeLocations.entries) {
      final routeId = entry.key;
      final locations = entry.value;

      // Find bus and stops in this route
      final busLocations = locations.where((loc) => loc.type == 'bus').toList();
      final stopLocations =
          locations.where((loc) => loc.type == 'stop').toList();

      for (var busLocation in busLocations) {
        _updateBusLocation(busLocation, stopLocations, routeId);
      }
    }
    notifyListeners();
  }

  void _updateBusLocation(
    MapLocation busLocation,
    List<MapLocation> stops,
    String routeId,
  ) {
    if (stops.isEmpty) return;

    // Find next stop
    var nextStop = _findNextStop(busLocation, stops);
    if (nextStop == null) return;

    // Calculate new position
    final currentPos = _calculateNewPosition(
      busLocation.latitude,
      busLocation.longitude,
      nextStop.latitude,
      nextStop.longitude,
    );

    // Calculate speed and ETA
    final distance = _calculateDistance(
      currentPos.$1,
      currentPos.$2,
      nextStop.latitude,
      nextStop.longitude,
    );

    final speed = _calculateCurrentSpeed(distance);
    final eta = _calculateETA(distance, speed);

    // Create updated bus location
    final updatedBusLocation = MapLocation.fromBus(
      id: busLocation.id,
      name: busLocation.name,
      latitude: currentPos.$1,
      longitude: currentPos.$2,
      speed: speed,
      status: 'moving',
      eta: eta,
      routeId: routeId,
    );

    // Update route locations
    final index = _routeLocations[routeId]?.indexWhere(
          (loc) => loc.id == busLocation.id,
        ) ??
        -1;

    if (index != -1) {
      _routeLocations[routeId]![index] = updatedBusLocation;
    }

    // Notify bus location stream
    _busLocationControllers[busLocation.id]?.add(updatedBusLocation);
  }

  MapLocation? _findNextStop(MapLocation busLocation, List<MapLocation> stops) {
    var minDistance = double.infinity;
    MapLocation? nextStop;

    for (var stop in stops) {
      final distance = _calculateDistance(
        busLocation.latitude,
        busLocation.longitude,
        stop.latitude,
        stop.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nextStop = stop;
      }
    }

    return nextStop;
  }

  (double, double) _calculateNewPosition(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const double stepSize = 0.0001; // Adjust for speed
    final double bearing =
        _calculateBearing(startLat, startLng, endLat, endLng);

    final double newLat = startLat + (stepSize * math.cos(bearing));
    final double newLng = startLng + (stepSize * math.sin(bearing));

    return (newLat, newLng);
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _toRadians(lon2 - lon1);

    lat1 = _toRadians(lat1);
    lat2 = _toRadians(lat2);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return math.atan2(y, x);
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  double _calculateCurrentSpeed(double distanceToNextStop) {
    // Simulate varying speed based on distance to next stop
    return math.min(
      averageSpeed,
      averageSpeed * (distanceToNextStop / 5),
    );
  }

  DateTime _calculateETA(double distance, double speed) {
    if (speed <= 0) return DateTime.now();

    final hours = distance / speed;
    return DateTime.now().add(Duration(
      minutes: (hours * 60).round() + stopDuration.round(),
    ));
  }

  void updateRouteLocations(String routeId, List<MapLocation> locations) {
    _routeLocations[routeId] = locations;
    notifyListeners();
  }

  List<MapLocation> getRouteLocations(String routeId) {
    return _routeLocations[routeId] ?? [];
  }

  void clearRouteLocations(String routeId) {
    _routeLocations.remove(routeId);
    _busLocationControllers[routeId]?.close();
    _busLocationControllers.remove(routeId);
    notifyListeners();
  }

  void clearAllLocations() {
    _routeLocations.clear();
    for (var controller in _busLocationControllers.values) {
      controller.close();
    }
    _busLocationControllers.clear();
    notifyListeners();
  }

  List<MapLocation> convertRouteToLocations(BusRoute route) {
    final locations = <MapLocation>[];
    final now = DateTime.now();

    // Add actual route stops with real coordinates
    if (route.id == 'maadi') {
      // Maadi Route
      locations.addAll([
        MapLocation.fromStop(
          id: 'stop_1',
          name: 'El Cornishe HSBC Bank',
          latitude: 29.977181081761824,
          longitude: 31.234552930506265,
          arrivalTime: null,
          departureTime: now.add(const Duration(minutes: 5)),
          nextBusId: 'bus_${route.id}',
          nextBusArrival: now.add(const Duration(minutes: 15)),
        ),
        MapLocation.fromStop(
          id: 'stop_2',
          name: 'Military Hospital',
          latitude: 29.968417448873556,
          longitude: 31.241466671336887,
          arrivalTime: now.add(const Duration(minutes: 10)),
          departureTime: now.add(const Duration(minutes: 12)),
          nextBusId: 'bus_${route.id}',
          nextBusArrival: now.add(const Duration(minutes: 25)),
        ),
        MapLocation.fromStop(
          id: 'stop_3',
          name: 'House of Donuts',
          latitude: 29.960184986981876,
          longitude: 31.250800003612703,
          arrivalTime: now.add(const Duration(minutes: 15)),
          departureTime: now.add(const Duration(minutes: 17)),
          nextBusId: 'bus_${route.id}',
          nextBusArrival: now.add(const Duration(minutes: 35)),
        ),
        MapLocation.fromStop(
          id: 'stop_4',
          name: 'El Horia Square',
          latitude: 29.95953974002419,
          longitude: 31.253987466634356,
          arrivalTime: now.add(const Duration(minutes: 20)),
          departureTime: now.add(const Duration(minutes: 22)),
          nextBusId: 'bus_${route.id}',
          nextBusArrival: now.add(const Duration(minutes: 45)),
        ),
        MapLocation.fromStop(
          id: 'stop_5',
          name: 'Victoria Square',
          latitude: 29.95971568411058,
          longitude: 31.270619976390247,
          arrivalTime: now.add(const Duration(minutes: 30)),
          departureTime: now.add(const Duration(minutes: 32)),
          nextBusId: 'bus_${route.id}',
          nextBusArrival: now.add(const Duration(minutes: 55)),
        ),
        MapLocation.fromStop(
          id: 'stop_6',
          name: 'Vodafone ElZahraa',
          latitude: 29.96197529161935,
          longitude: 31.30305911933381,
          arrivalTime: now.add(const Duration(minutes: 40)),
          departureTime: now.add(const Duration(minutes: 42)),
          nextBusId: 'bus_${route.id}',
          nextBusArrival: now.add(const Duration(minutes: 65)),
        ),
        MapLocation.fromStop(
          id: 'stop_7',
          name: 'Hub 50 Mall',
          latitude: 29.96750442563834,
          longitude: 31.3140336528946,
          arrivalTime: now.add(const Duration(minutes: 50)),
          departureTime: now.add(const Duration(minutes: 52)),
          nextBusId: 'bus_${route.id}',
          nextBusArrival: now.add(const Duration(minutes: 75)),
        ),
        MapLocation.fromStop(
          id: 'stop_8',
          name: 'IMS School',
          latitude: 29.969725240386857,
          longitude: 31.32078256992448,
          arrivalTime: now.add(const Duration(minutes: 60)),
          departureTime: now.add(const Duration(minutes: 62)),
          nextBusId: 'bus_${route.id}',
          nextBusArrival: now.add(const Duration(minutes: 85)),
        ),
        MapLocation.fromStop(
          id: 'stop_9',
          name: 'Becho American City',
          latitude: 29.970029097467165,
          longitude: 31.331451410167865,
          arrivalTime: now.add(const Duration(minutes: 70)),
          departureTime: now.add(const Duration(minutes: 72)),
          nextBusId: 'bus_${route.id}',
          nextBusArrival: now.add(const Duration(minutes: 95)),
        ),
        MapLocation.fromStop(
          id: 'stop_10',
          name: 'EUI Campus',
          latitude: 30.02229168783005,
          longitude: 31.708040703086247,
          arrivalTime: now.add(const Duration(minutes: 85)),
          departureTime: null,
          nextBusId: 'bus_${route.id}',
          nextBusArrival: now.add(const Duration(minutes: 115)),
        ),
      ]);

      // Add intermediate waypoints for accurate street following
      locations.addAll([
        // HSBC to Military Hospital
        MapLocation(
          id: 'waypoint_1',
          type: 'waypoint',
          name: 'Hussein Ibrahim Street',
          latitude: 29.976981,
          longitude: 31.234052,
        ),
        MapLocation(
          id: 'waypoint_2',
          type: 'waypoint',
          name: 'Corniche El Maadi Turn',
          latitude: 29.973181,
          longitude: 31.235552,
        ),
        MapLocation(
          id: 'waypoint_3',
          type: 'waypoint',
          name: 'Armed Forces Hospital Entry',
          latitude: 29.969417,
          longitude: 31.241066,
        ),

        // Military Hospital to House of Donuts
        MapLocation(
          id: 'waypoint_4',
          type: 'waypoint',
          name: 'Hospital Internal Path 1',
          latitude: 29.968017,
          longitude: 31.241867,
        ),
        MapLocation(
          id: 'waypoint_5',
          type: 'waypoint',
          name: 'Nile Corniche Turn',
          latitude: 29.964184,
          longitude: 31.245800,
        ),
        MapLocation(
          id: 'waypoint_6',
          type: 'waypoint',
          name: 'Street 151 Turn',
          latitude: 29.961184,
          longitude: 31.249800,
        ),

        // House of Donuts to Al Horia Square
        MapLocation(
          id: 'waypoint_7',
          type: 'waypoint',
          name: 'Street 150 Turn',
          latitude: 29.959984,
          longitude: 31.251800,
        ),
        MapLocation(
          id: 'waypoint_8',
          type: 'waypoint',
          name: 'Street 101 Turn',
          latitude: 29.959740,
          longitude: 31.253087,
        ),

        // Al Horia Square to Victoria Square
        MapLocation(
          id: 'waypoint_9',
          type: 'waypoint',
          name: 'El-Nahda Entry',
          latitude: 29.959616,
          longitude: 31.255620,
        ),
        MapLocation(
          id: 'waypoint_10',
          type: 'waypoint',
          name: 'Port Said Road',
          latitude: 29.959716,
          longitude: 31.265620,
        ),

        // Victoria Square to Vodafone ElZahraa
        MapLocation(
          id: 'waypoint_11',
          type: 'waypoint',
          name: 'Cairo-Suez Road Entry',
          latitude: 29.960975,
          longitude: 31.285059,
        ),
        MapLocation(
          id: 'waypoint_12',
          type: 'waypoint',
          name: 'Zahraa Al Maadi Turn',
          latitude: 29.961575,
          longitude: 31.295059,
        ),

        // Vodafone to Hub 50 Mall
        MapLocation(
          id: 'waypoint_13',
          type: 'waypoint',
          name: 'Zahraa Al Maadi Roundabout',
          latitude: 29.964504,
          longitude: 31.310034,
        ),

        // Hub 50 Mall to IMS School
        MapLocation(
          id: 'waypoint_14',
          type: 'waypoint',
          name: 'Cairo-Suez Road North',
          latitude: 29.968725,
          longitude: 31.318783,
        ),

        // IMS School to Becho American City
        MapLocation(
          id: 'waypoint_15',
          type: 'waypoint',
          name: 'El-Basatin Approach',
          latitude: 29.969829,
          longitude: 31.328451,
        ),

        // Becho to EUI (Regional Ring Road and NAC)
        MapLocation(
          id: 'waypoint_16',
          type: 'waypoint',
          name: 'Ain El Sokhna Road Entry',
          latitude: 29.975029,
          longitude: 31.358451,
        ),
        MapLocation(
          id: 'waypoint_17',
          type: 'waypoint',
          name: 'Regional Ring Road 1',
          latitude: 29.985029,
          longitude: 31.458451,
        ),
        MapLocation(
          id: 'waypoint_18',
          type: 'waypoint',
          name: 'Regional Ring Road 2',
          latitude: 29.995029,
          longitude: 31.558451,
        ),
        MapLocation(
          id: 'waypoint_19',
          type: 'waypoint',
          name: 'NAC Approach',
          latitude: 30.012291,
          longitude: 31.658451,
        ),
        MapLocation(
          id: 'waypoint_20',
          type: 'waypoint',
          name: 'EUI Approach Road',
          latitude: 30.020291,
          longitude: 31.698451,
        ),
      ]);
    }

    // Add bus with initial position at first stop
    if (locations.isNotEmpty) {
      final firstStop = locations.firstWhere((loc) => loc.type == 'stop');
      locations.add(
        MapLocation.fromBus(
          id: 'bus_${route.id}',
          name: 'Bus ${route.id}',
          latitude: firstStop.latitude,
          longitude: firstStop.longitude,
          speed: averageSpeed,
          status: 'moving',
          routeId: route.id,
        ),
      );
    }

    return locations;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    for (var controller in _busLocationControllers.values) {
      controller.close();
    }
    super.dispose();
  }

  Future<List<LatLng>> getRoutePoints(
      LatLng origin, LatLng destination, List<LatLng> waypoints) async {
    try {
      // Convert waypoints to optimize format
      final waypointStr = waypoints.isNotEmpty
          ? 'optimize:true|' +
              waypoints
                  .map((point) => '${point.latitude},${point.longitude}')
                  .join('|')
          : '';

      final url = Uri.parse('$baseUrl'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '${waypointStr.isNotEmpty ? '&waypoints=$waypointStr' : ''}'
          '&mode=driving'
          '&alternatives=true'
          '&traffic_model=best_guess'
          '&departure_time=now'
          '&key=$apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          // Get the most optimal route (first one in alternatives)
          final route = data['routes'][0];
          final List<LatLng> points = [];

          // Extract detailed steps for more accurate route
          for (var leg in route['legs']) {
            for (var step in leg['steps']) {
              points.addAll(decodePolyline(step['polyline']['points']));
            }
          }

          return points;
        }
      }
      throw Exception('Failed to fetch route: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting route: $e');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
