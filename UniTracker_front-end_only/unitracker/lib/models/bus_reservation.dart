class BusReservation {
  final int id;
  final String routeName;
  final String routeCode;
  final DateTime date;
  final String time;
  final String pickup;
  final String dropoff;
  final String seatNumber;
  final String status; // confirmed, completed, cancelled
  final DateTime createdAt;

  BusReservation({
    required this.id,
    required this.routeName,
    required this.routeCode,
    required this.date,
    required this.time,
    required this.pickup,
    required this.dropoff,
    required this.seatNumber,
    required this.status,
    required this.createdAt,
  });

  factory BusReservation.fromJson(Map<String, dynamic> json) {
    return BusReservation(
      id: json['id'],
      routeName: json['routeName'],
      routeCode: json['routeCode'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      pickup: json['pickup'],
      dropoff: json['dropoff'],
      seatNumber: json['seatNumber'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeName': routeName,
      'routeCode': routeCode,
      'date': date.toIso8601String(),
      'time': time,
      'pickup': pickup,
      'dropoff': dropoff,
      'seatNumber': seatNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
