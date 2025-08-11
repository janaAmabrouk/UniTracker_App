class BusStop {
  final String id;
  final String name;
  final int order;
  final String? arrivalTime;
  final String? departureTime;

  const BusStop({
    required this.id,
    required this.name,
    required this.order,
    this.arrivalTime,
    this.departureTime,
  });

  @override
  String toString() => name;
}
