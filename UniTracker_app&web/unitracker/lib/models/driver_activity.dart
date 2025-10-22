enum DriverActivityType {
  tripCompleted,
  routeAssigned,
  statusChanged,
  maintenanceScheduled,
  breakStarted,
  breakEnded,
}

enum DriverActivityStatus {
  completed,
  inProgress,
  scheduled,
  cancelled,
}

class DriverActivity {
  final String id;
  final DriverActivityType type;
  final String description;
  final DateTime timestamp;
  final DriverActivityStatus status;
  final Map<String, dynamic>? additionalData;

  const DriverActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.status,
    this.additionalData,
  });

  // Create a list of mock activities
  static List<DriverActivity> getMockActivities() {
    return [
      DriverActivity(
        id: '1',
        type: DriverActivityType.tripCompleted,
        description: 'Completed trip from Maadi to EUI Campus',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: DriverActivityStatus.completed,
        additionalData: {
          'routeName': 'Maadi Shuttle',
          'passengers': 12,
          'onTime': true,
        },
      ),
      DriverActivity(
        id: '2',
        type: DriverActivityType.routeAssigned,
        description: 'Assigned to Heliopolis morning route',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        status: DriverActivityStatus.inProgress,
        additionalData: {
          'routeName': 'Heliopolis Shuttle',
          'startTime': '8:00 AM',
          'expectedDuration': '45 minutes',
        },
      ),
      DriverActivity(
        id: '3',
        type: DriverActivityType.maintenanceScheduled,
        description: 'Vehicle maintenance scheduled',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        status: DriverActivityStatus.scheduled,
        additionalData: {
          'vehicleId': 'BUS-001',
          'maintenanceType': 'Regular checkup',
          'scheduledDate':
              DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        },
      ),
    ];
  }

  // Convert to Map for storage/API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString(),
      'additionalData': additionalData,
    };
  }

  // Create from Map (from storage/API)
  factory DriverActivity.fromMap(Map<String, dynamic> map) {
    return DriverActivity(
      id: map['id'] as String,
      type: DriverActivityType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      description: map['description'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: DriverActivityStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
      ),
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }
}
