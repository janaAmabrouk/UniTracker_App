import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitracker/utils/responsive_utils.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/models/reservation.dart';
import 'package:unitracker/services/reservation_service.dart';
import 'package:intl/intl.dart';

import 'make_reservation_screen.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTab = 'current';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index == 0 ? 'current' : 'history';
      });
    });

    // Add test reservations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationService>().addTestReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildReservationCard(Reservation reservation, ThemeData theme) {
    final dateTime = DateTime.parse(reservation.date);
    final time = DateFormat('h:mm a').format(dateTime);
    final date = DateFormat('E, MMM d, yyyy').format(dateTime);

    // Calculate relative time for the circle indicator
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reservationDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    String circleText;
    if (reservationDate == today) {
      circleText = 'Today';
    } else if (reservationDate == today.add(const Duration(days: 1))) {
      circleText = 'Tomorrow';
    } else {
      circleText = DateFormat('E, MMM d, yyyy').format(dateTime);
    }

    final bool isCancelled = reservation.status == 'cancelled';
    final bool isPast = dateTime.isBefore(DateTime.now());

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(24),
        vertical: getProportionateScreenHeight(8),
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(16)),
        border: Border.all(
          color: theme.dividerTheme.color ?? const Color(0xFFEEEEEE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, getProportionateScreenHeight(2)),
            blurRadius: getProportionateScreenWidth(4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF${reservation.route.iconColor}')),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(getProportionateScreenWidth(16)),
                topRight: Radius.circular(getProportionateScreenWidth(16)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_bus_outlined,
                  color: theme.primaryColor,
                ),
                SizedBox(width: getProportionateScreenWidth(8)),
                Expanded(
                  child: Text(
                    reservation.route.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(12),
                    vertical: getProportionateScreenHeight(4),
                  ),
                  decoration: BoxDecoration(
                    color: isCancelled ? Colors.red : theme.primaryColor,
                    borderRadius:
                        BorderRadius.circular(getProportionateScreenWidth(33)),
                  ),
                  child: Text(
                    isCancelled ? 'Cancelled' : circleText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            child: Column(
              children: [
                _buildInfoRow(
                  theme,
                  Icons.calendar_today_rounded,
                  'Date',
                  date,
                ),
                SizedBox(height: getProportionateScreenHeight(12)),
                _buildInfoRow(
                  theme,
                  Icons.access_time_rounded,
                  'Time',
                  time,
                ),
                SizedBox(height: getProportionateScreenHeight(12)),
                _buildInfoRow(
                  theme,
                  Icons.location_on_outlined,
                  'From',
                  reservation.pickupPoint,
                ),
                SizedBox(height: getProportionateScreenHeight(12)),
                _buildInfoRow(
                  theme,
                  Icons.location_on,
                  'To',
                  reservation.dropPoint,
                ),
                if (!isCancelled && !isPast) ...[
                  SizedBox(height: getProportionateScreenHeight(16)),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () async {
                        final reservationService =
                            context.read<ReservationService>();
                        try {
                          // Show confirmation dialog
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Cancel Reservation'),
                                content: Text(
                                    'Are you sure you want to cancel this reservation?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text(
                                      'Yes',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            await reservationService
                                .cancelReservation(reservation.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Reservation cancelled successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Cancel Reservation'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: getProportionateScreenWidth(20),
          color: theme.primaryColor,
        ),
        SizedBox(width: getProportionateScreenWidth(8)),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        SizedBox(width: getProportionateScreenWidth(8)),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationsList(List<Reservation> reservations) {
    if (reservations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: getProportionateScreenHeight(16)),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        return _buildReservationCard(reservations[index], Theme.of(context));
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_seat_outlined,
            size: getProportionateScreenWidth(64),
            color: Colors.grey[400],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Text(
            'No Reservations',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(20),
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Text(
            'You haven\'t made any reservations yet',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(14),
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(24)),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MakeReservationScreen(),
                ),
              ).then((_) => setState(() {}));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(24),
                vertical: getProportionateScreenHeight(12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(33),
              ),
            ),
            child: Text(
              'Make a Reservation',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(16),
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRelativeTimeText(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    final today = DateTime(now.year, now.month, now.day);
    final reservationDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (reservationDate == today) {
      return 'Today';
    } else if (reservationDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${difference}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservationService = context.watch<ReservationService>();

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.primaryColor,
        titleSpacing: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            'My Reservations',
            style: TextStyle(
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              fontSize: getProportionateScreenWidth(20),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: AppTheme.lightTheme.colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MakeReservationScreen(),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.lightTheme.primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_seat,
                        color: Colors.white,
                        size: getProportionateScreenWidth(24),
                      ),
                      SizedBox(width: getProportionateScreenWidth(8)),
                      Text(
                        'Current',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: getProportionateScreenWidth(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        color: Colors.white,
                        size: getProportionateScreenWidth(24),
                      ),
                      SizedBox(width: getProportionateScreenWidth(8)),
                      Text(
                        'History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: getProportionateScreenWidth(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReservationsList(
                    reservationService.getCurrentReservations()),
                _buildReservationsList(
                    reservationService.getReservationHistory()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
