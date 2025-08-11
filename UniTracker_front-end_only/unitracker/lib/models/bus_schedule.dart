class BusSchedule {
  final String name;
  final String id;
  final String morningPickupTime;
  final String morningDropTime;
  final String afternoonPickupTime;
  final String afternoonDropTime;
  final String eveningPickupTime;
  final String eveningDropTime;
  final String pickup;
  final String drop;
  bool isFavorite;
  final bool afternoonRoute;

  BusSchedule({
    required this.name,
    required this.id,
    required this.morningPickupTime,
    required this.morningDropTime,
    required this.afternoonPickupTime,
    required this.afternoonDropTime,
    required this.eveningPickupTime,
    required this.eveningDropTime,
    required this.pickup,
    required this.drop,
    this.isFavorite = false,
    this.afternoonRoute = false,
  });

  factory BusSchedule.fromJson(Map<String, dynamic> json) {
    return BusSchedule(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      morningPickupTime: json['morningPickupTime'] ?? '',
      morningDropTime: json['morningDropTime'] ?? '',
      afternoonPickupTime: json['afternoonPickupTime'] ?? '',
      afternoonDropTime: json['afternoonDropTime'] ?? '',
      eveningPickupTime: json['eveningPickupTime'] ?? '',
      eveningDropTime: json['eveningDropTime'] ?? '',
      pickup: json['pickup'] ?? '',
      drop: json['drop'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      afternoonRoute: json['afternoonRoute'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'morningPickupTime': morningPickupTime,
      'morningDropTime': morningDropTime,
      'afternoonPickupTime': afternoonPickupTime,
      'afternoonDropTime': afternoonDropTime,
      'eveningPickupTime': eveningPickupTime,
      'eveningDropTime': eveningDropTime,
      'pickup': pickup,
      'drop': drop,
      'isFavorite': isFavorite,
      'afternoonRoute': afternoonRoute,
    };
  }
}
