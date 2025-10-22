import 'package:unitracker/models/bus_route.dart';

class Reservation {
  final String id;
  final BusRoute route;
  final String date;
  final String status; // 'confirmed', 'pending', 'cancelled'
  final String seatNumber;
  final String pickupPoint;
  final String dropPoint;

  Reservation({
    required this.id,
    required this.route,
    required this.date,
    required this.status,
    required this.seatNumber,
    required this.pickupPoint,
    required this.dropPoint,
  });
}
