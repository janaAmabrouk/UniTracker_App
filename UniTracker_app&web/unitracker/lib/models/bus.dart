class Bus {
  final String id;
  final String busNumber;
  final String plateNumber;
  final int capacity;
  final bool isActive;
  final String? currentDriverId;
  final String? currentRouteId;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;

  const Bus({
    required this.id,
    required this.busNumber,
    required this.plateNumber,
    required this.capacity,
    this.isActive = true,
    this.currentDriverId,
    this.currentRouteId,
    this.lastMaintenance,
    this.nextMaintenance,
  });

  Bus copyWith({
    String? id,
    String? busNumber,
    String? plateNumber,
    int? capacity,
    bool? isActive,
    String? currentDriverId,
    String? currentRouteId,
    DateTime? lastMaintenance,
    DateTime? nextMaintenance,
  }) {
    return Bus(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      plateNumber: plateNumber ?? this.plateNumber,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
      currentDriverId: currentDriverId ?? this.currentDriverId,
      currentRouteId: currentRouteId ?? this.currentRouteId,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      nextMaintenance: nextMaintenance ?? this.nextMaintenance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busNumber': busNumber,
      'plateNumber': plateNumber,
      'capacity': capacity,
      'isActive': isActive,
      'currentDriverId': currentDriverId,
      'currentRouteId': currentRouteId,
      'lastMaintenance': lastMaintenance?.toIso8601String(),
      'nextMaintenance': nextMaintenance?.toIso8601String(),
    };
  }

  factory Bus.fromMap(Map<String, dynamic> map) {
    return Bus(
      id: map['id'] as String,
      busNumber: map['busNumber'] as String,
      plateNumber: map['plateNumber'] as String,
      capacity: map['capacity'] as int,
      isActive: map['isActive'] as bool? ?? true,
      currentDriverId: map['currentDriverId'] as String?,
      currentRouteId: map['currentRouteId'] as String?,
      lastMaintenance: map['lastMaintenance'] != null
          ? DateTime.parse(map['lastMaintenance'] as String)
          : null,
      nextMaintenance: map['nextMaintenance'] != null
          ? DateTime.parse(map['nextMaintenance'] as String)
          : null,
    );
  }
}
