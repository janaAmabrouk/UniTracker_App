import 'package:flutter/material.dart';
import 'dart:async';
import 'package:unitracker/services/reservation_service.dart';
import 'package:unitracker/utils/responsive_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unitracker/services/notification_service.dart';
import 'package:unitracker/services/notification_settings_service.dart';

class ReservationCountdown extends StatefulWidget {
  final String routeId;
  final DateTime travelDate;
  final String pickupPoint;
  final String dropPoint;
  final String dateTime;
  final TimeOfDay selectedTime;
  final String? slotId;
  final int? slotCapacity;

  const ReservationCountdown({
    super.key,
    required this.routeId,
    required this.travelDate,
    required this.pickupPoint,
    required this.dropPoint,
    required this.dateTime,
    required this.selectedTime,
    this.slotId,
    this.slotCapacity,
  });

  @override
  State<ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<ReservationCountdown>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  int _seatsRemaining = 20; // Default max seats
  int _totalSeats = 20; // Total bus capacity
  late AnimationController _controller;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Update more frequently to catch immediate changes
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_disposed) {
        _updateTimeRemaining();
        _updateSeatsRemaining();
      }
    });
  }

  @override
  void didUpdateWidget(ReservationCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update immediately when widget data changes
    if (!_disposed &&
        (oldWidget.dateTime != widget.dateTime ||
            oldWidget.routeId != widget.routeId)) {
      _updateSeatsRemaining();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _updateTimeRemaining() {
    if (!mounted || _disposed) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final travelDay = DateTime(
      widget.travelDate.year,
      widget.travelDate.month,
      widget.travelDate.day,
    );

    // Only apply deadline if it's the day of travel
    if (travelDay.isAtSameMomentAs(today)) {
      final selectedDateTime = DateTime(
        widget.travelDate.year,
        widget.travelDate.month,
        widget.travelDate.day,
        widget.selectedTime.hour,
        widget.selectedTime.minute,
      );

      final deadline = selectedDateTime.subtract(const Duration(hours: 2));

      if (now.isBefore(deadline)) {
        setState(() {
          _timeRemaining = deadline.difference(now);
        });
      } else {
        setState(() {
          _timeRemaining = Duration.zero;
        });
      }
    } else {
      // For future dates, no time restriction
      setState(() {
        _timeRemaining = const Duration(hours: 24); // Just a non-zero duration
      });
    }
  }

  void _updateSeatsRemaining() async {
    if (!mounted || _disposed) return;

    try {
      final reservationService =
          Provider.of<ReservationService>(context, listen: false);

      int slotCapacity = widget.slotCapacity ?? 0;
      int reservedCount = 0;
      if (widget.slotId != null) {
        reservedCount =
            await reservationService.countReservationsForSlot(widget.slotId!);
      }
      final seatsAvailable = slotCapacity - reservedCount;

      if (!mounted || _disposed) return;

      setState(() {
        _seatsRemaining = seatsAvailable;
        _totalSeats = slotCapacity;
      });
    } catch (e) {
      debugPrint('Error updating seats: $e');
    }
  }

  // Helper method to determine direction (copied from ReservationService)
  bool _isToUniversityDirection(String pickupPoint, String dropPoint) {
    final pickup = pickupPoint.toLowerCase().trim();
    final drop = dropPoint.toLowerCase().trim();

    // University/campus keywords
    final universityKeywords = ['eui', 'campus', 'university', 'college'];

    // Check if pickup point contains university keywords
    bool pickupIsUniversity =
        universityKeywords.any((keyword) => pickup.contains(keyword));

    // Check if drop point contains university keywords
    bool dropIsUniversity =
        universityKeywords.any((keyword) => drop.contains(keyword));

    // "To University" means going TO the campus (drop point is university, pickup is not)
    return dropIsUniversity && !pickupIsUniversity;
  }

  String _formatTimeRemaining() {
    final tripDateTime = DateTime(
      widget.travelDate.year,
      widget.travelDate.month,
      widget.travelDate.day,
      widget.selectedTime.hour,
      widget.selectedTime.minute,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final travelDay = DateTime(
      tripDateTime.year,
      tripDateTime.month,
      tripDateTime.day,
    );

    // Calculate the difference in days
    final difference = travelDay.difference(today).inDays;

    // Format the time
    final formattedTime = DateFormat('h:mm a').format(tripDateTime);

    // Return relative date with time
    if (difference == 0) {
      return 'Today at $formattedTime';
    } else if (difference == 1) {
      return 'Tomorrow at $formattedTime';
    } else if (difference < 7) {
      return 'In $difference days at $formattedTime';
    } else {
      // For dates more than a week away, show the full date
      final formattedDate = DateFormat('EEE, MMM d, yyyy').format(tripDateTime);
      return '$formattedDate at $formattedTime';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final tripDateTime = DateTime(
      widget.travelDate.year,
      widget.travelDate.month,
      widget.travelDate.day,
      widget.selectedTime.hour,
      widget.selectedTime.minute,
    );
    final deadline = tripDateTime.subtract(const Duration(hours: 2));
    final isReservationClosed = now.isAfter(deadline);

    final isLoadingSeats =
        (_seatsRemaining == 20 && _totalSeats == 20) || (_totalSeats == 0);

    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(12)),
        border: Border.all(
          color: theme.dividerTheme.color ?? const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Time',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(4)),
                      Text(
                        _formatTimeRemaining(),
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: getProportionateScreenWidth(14),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: getProportionateScreenWidth(16)),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Seats Available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: getProportionateScreenHeight(4)),
                      if (isLoadingSeats)
                        SizedBox(
                          width: 24,
                          height: 16,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.primaryColor),
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          '$_seatsRemaining/$_totalSeats',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: getProportionateScreenWidth(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isReservationClosed || _seatsRemaining == 0) ...[
            SizedBox(height: getProportionateScreenHeight(12)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(12),
                vertical: getProportionateScreenHeight(8),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius:
                    BorderRadius.circular(getProportionateScreenWidth(8)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: const Color(0xFFE53935),
                    size: getProportionateScreenWidth(16),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  Expanded(
                    child: Text(
                      isReservationClosed
                          ? 'Reservations close 2 hours before departure time'
                          : 'No seats available for this trip',
                      style: TextStyle(
                        color: const Color(0xFFE53935),
                        fontSize: getProportionateScreenWidth(12),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
