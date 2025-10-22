import 'package:flutter/foundation.dart';

class MapLocation {
  final String id;
  final String type; // 'bus' or 'stop'
  final String name;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? additionalInfo;
  final DateTime? timestamp;
  final DateTime? arrivalTime;
  final DateTime? departureTime;

  MapLocation({
    required this.id,
    required this.type,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.additionalInfo,
    this.timestamp,
    this.arrivalTime,
    this.departureTime,
  });

  factory MapLocation.fromBus({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    double? speed,
    String? status,
    DateTime? eta,
    String? routeId,
  }) {
    return MapLocation(
      id: id,
      type: 'bus',
      name: name,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      additionalInfo: {
        'speed': speed ?? 0.0,
        'status': status ?? 'unknown',
        'eta': eta?.toString() ?? 'Calculating...',
        'routeId': routeId,
      },
    );
  }

  factory MapLocation.fromStop({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    DateTime? arrivalTime,
    DateTime? departureTime,
    String? nextBusId,
    DateTime? nextBusArrival,
  }) {
    return MapLocation(
      id: id,
      type: 'stop',
      name: name,
      latitude: latitude,
      longitude: longitude,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
      additionalInfo: {
        'nextBusId': nextBusId,
        'nextBusArrival': nextBusArrival?.toString() ?? 'No bus scheduled',
      },
    );
  }

  MapLocation copyWith({
    String? id,
    String? type,
    String? name,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? additionalInfo,
    DateTime? timestamp,
    DateTime? arrivalTime,
    DateTime? departureTime,
  }) {
    return MapLocation(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      timestamp: timestamp ?? this.timestamp,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
    );
  }
}
