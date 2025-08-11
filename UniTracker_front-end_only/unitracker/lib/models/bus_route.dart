import 'package:unitracker/models/bus_stop.dart' as bus_stop_model;

class BusRoute {
  final String id;
  final String name;
  final String pickup;
  final String drop;
  final String startTime;
  final String endTime;
  final List<bus_stop_model.BusStop> stops;
  final String iconColor;
  bool isFavorite;

  BusRoute({
    required this.id,
    required this.name,
    required this.pickup,
    required this.drop,
    required this.startTime,
    required this.endTime,
    required this.stops,
    required this.iconColor,
    this.isFavorite = false,
  });

  int get iconColorValue => int.parse(iconColor, radix: 16);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusRoute && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
