import 'package:unitracker/models/bus_route.dart';

class Reservation {
  final String id;
  final String userId;
  final BusRoute route;
  final String date;
  final String status; // 'confirmed', 'pending', 'cancelled'
  final String seatNumber;
  final String pickupPoint;
  final String dropPoint;
  final String? slotId;
  final String? slotDate;
  final String? slotTime;
  final String? slotDirection;
  final int? slotCapacity;

  Reservation({
    required this.id,
    required this.userId,
    required this.route,
    required this.date,
    required this.status,
    required this.seatNumber,
    required this.pickupPoint,
    required this.dropPoint,
    this.slotId,
    this.slotDate,
    this.slotTime,
    this.slotDirection,
    this.slotCapacity,
  });
}
