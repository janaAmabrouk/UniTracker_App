class DriverStats {
  /// Total number of trips (all statuses)
  final int totalTrips;

  /// Number of completed trips
  final int completedTrips;
  final double rating;
  final double onTimePerformance;
  final double safetyScore;
  final double customerSatisfaction;
  final DateTime joinedDate;

  const DriverStats({
    required this.totalTrips,
    required this.completedTrips,
    required this.rating,
    required this.onTimePerformance,
    required this.safetyScore,
    required this.customerSatisfaction,
    required this.joinedDate,
  });

  // Create a factory constructor for mock data
  factory DriverStats.mock() {
    return DriverStats(
      totalTrips: 247,
      completedTrips: 247,
      rating: 4.9,
      onTimePerformance: 98.5,
      safetyScore: 95.0,
      customerSatisfaction: 97.2,
      joinedDate: DateTime(2023, 1, 1),
    );
  }

  // Convert to Map for storage/API
  Map<String, dynamic> toMap() {
    return {
      'totalTrips': totalTrips,
      'completedTrips': completedTrips,
      'rating': rating,
      'onTimePerformance': onTimePerformance,
      'safetyScore': safetyScore,
      'customerSatisfaction': customerSatisfaction,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }

  // Create from Map (from storage/API)
  factory DriverStats.fromMap(Map<String, dynamic> map) {
    return DriverStats(
      totalTrips: map['totalTrips'] as int,
      completedTrips: map['completedTrips'] as int,
      rating: (map['rating'] as num).toDouble(),
      onTimePerformance: (map['onTimePerformance'] as num).toDouble(),
      safetyScore: (map['safetyScore'] as num).toDouble(),
      customerSatisfaction: (map['customerSatisfaction'] as num).toDouble(),
      joinedDate: DateTime.parse(map['joinedDate'] as String),
    );
  }
}
