// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// class BusRoute {
//   final String id;
//   final String name;
//   final String description;
//   final List<LatLng> waypoints;
//   final LatLng startPoint;
//   final LatLng endPoint;
//   final String? assignedBusId;
//   final String? assignedDriverId;
//   final List<String>
//       scheduledTimes; // List of departure times in 24-hour format (HH:mm)
//   final bool isActive;
//   final int estimatedDurationMinutes;
//   final double estimatedDistanceKm;
//
//   const BusRoute({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.waypoints,
//     required this.startPoint,
//     required this.endPoint,
//     required this.scheduledTimes,
//     required this.estimatedDurationMinutes,
//     required this.estimatedDistanceKm,
//     this.assignedBusId,
//     this.assignedDriverId,
//     this.isActive = true,
//   });
//
//   BusRoute copyWith({
//     String? id,
//     String? name,
//     String? description,
//     List<LatLng>? waypoints,
//     LatLng? startPoint,
//     LatLng? endPoint,
//     String? assignedBusId,
//     String? assignedDriverId,
//     List<String>? scheduledTimes,
//     bool? isActive,
//     int? estimatedDurationMinutes,
//     double? estimatedDistanceKm,
//   }) {
//     return BusRoute(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       waypoints: waypoints ?? this.waypoints,
//       startPoint: startPoint ?? this.startPoint,
//       endPoint: endPoint ?? this.endPoint,
//       assignedBusId: assignedBusId ?? this.assignedBusId,
//       assignedDriverId: assignedDriverId ?? this.assignedDriverId,
//       scheduledTimes: scheduledTimes ?? this.scheduledTimes,
//       isActive: isActive ?? this.isActive,
//       estimatedDurationMinutes:
//           estimatedDurationMinutes ?? this.estimatedDurationMinutes,
//       estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'description': description,
//       'waypoints': waypoints
//           .map((point) => {
//                 'latitude': point.latitude,
//                 'longitude': point.longitude,
//               })
//           .toList(),
//       'startPoint': {
//         'latitude': startPoint.latitude,
//         'longitude': startPoint.longitude,
//       },
//       'endPoint': {
//         'latitude': endPoint.latitude,
//         'longitude': endPoint.longitude,
//       },
//       'assignedBusId': assignedBusId,
//       'assignedDriverId': assignedDriverId,
//       'scheduledTimes': scheduledTimes,
//       'isActive': isActive,
//       'estimatedDurationMinutes': estimatedDurationMinutes,
//       'estimatedDistanceKm': estimatedDistanceKm,
//     };
//   }
//
//   factory BusRoute.fromMap(Map<String, dynamic> map) {
//     final List<dynamic> waypointsList = map['waypoints'] as List<dynamic>;
//     final List<LatLng> waypoints = waypointsList
//         .map((point) => LatLng(
//               (point as Map<String, dynamic>)['latitude'] as double,
//               point['longitude'] as double,
//             ))
//         .toList();
//
//     final Map<String, dynamic> startPointMap =
//         map['startPoint'] as Map<String, dynamic>;
//     final Map<String, dynamic> endPointMap =
//         map['endPoint'] as Map<String, dynamic>;
//
//     return BusRoute(
//       id: map['id'] as String,
//       name: map['name'] as String,
//       description: map['description'] as String,
//       waypoints: waypoints,
//       startPoint: LatLng(
//         startPointMap['latitude'] as double,
//         startPointMap['longitude'] as double,
//       ),
//       endPoint: LatLng(
//         endPointMap['latitude'] as double,
//         endPointMap['longitude'] as double,
//       ),
//       assignedBusId: map['assignedBusId'] as String?,
//       assignedDriverId: map['assignedDriverId'] as String?,
//       scheduledTimes: List<String>.from(map['scheduledTimes'] as List<dynamic>),
//       isActive: map['isActive'] as bool? ?? true,
//       estimatedDurationMinutes: map['estimatedDurationMinutes'] as int,
//       estimatedDistanceKm: map['estimatedDistanceKm'] as double,
//     );
//   }
// }

class BusRoute {
  final String id;
  final String name;
  final String description;
  final String? assignedBusId;
  final String? assignedDriverId;
  final List<String>
      scheduledTimes; // List of departure times in 24-hour format (HH:mm)
  final bool isActive;
  final int estimatedDurationMinutes;
  final double estimatedDistanceKm;

  const BusRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.scheduledTimes,
    required this.estimatedDurationMinutes,
    required this.estimatedDistanceKm,
    this.assignedBusId,
    this.assignedDriverId,
    this.isActive = true,
  });

  BusRoute copyWith({
    String? id,
    String? name,
    String? description,
    String? assignedBusId,
    String? assignedDriverId,
    List<String>? scheduledTimes,
    bool? isActive,
    int? estimatedDurationMinutes,
    double? estimatedDistanceKm,
  }) {
    return BusRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      assignedBusId: assignedBusId ?? this.assignedBusId,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      isActive: isActive ?? this.isActive,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'assignedBusId': assignedBusId,
      'assignedDriverId': assignedDriverId,
      'scheduledTimes': scheduledTimes,
      'isActive': isActive,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'estimatedDistanceKm': estimatedDistanceKm,
    };
  }

  factory BusRoute.fromMap(Map<String, dynamic> map) {
    return BusRoute(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      assignedBusId: map['assignedBusId'] as String?,
      assignedDriverId: map['assignedDriverId'] as String?,
      scheduledTimes: List<String>.from(map['scheduledTimes'] as List<dynamic>),
      isActive: map['isActive'] as bool? ?? true,
      estimatedDurationMinutes: map['estimatedDurationMinutes'] as int,
      estimatedDistanceKm: map['estimatedDistanceKm'] as double,
    );
  }
}
