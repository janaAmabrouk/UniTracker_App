import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitracker/utils/responsive_utils.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/models/reservation.dart';
import 'package:unitracker/services/reservation_service.dart';
import 'package:unitracker/widgets/modern_widgets.dart';
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

  final List<Color> _cardColors = [
    const Color(0xFFE9EFFC), // Light Blue
    const Color(0xFFE1F6EF), // Light Teal
    const Color(0xFFFFF3CD), // Light Yellow
    const Color(0xFFFDE8E8), // Light Red
    const Color(0xFFEDE7F6), // Light Purple
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index == 0 ? 'current' : 'history';
      });
    });

    // Load real reservations from Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationService>().loadReservations();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh reservations when screen becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationService>().loadReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildReservationCard(
      Reservation reservation, ThemeData theme, int index) {
    final cardColor = _cardColors[index % _cardColors.length];

    // Prefer slotDate/slotTime if available
    String date = reservation.slotDate ?? reservation.date;
    String time = reservation.slotTime ?? '';
    String direction = reservation.slotDirection ?? '';
    String capacity = reservation.slotCapacity != null
        ? reservation.slotCapacity.toString()
        : '';
    // Format date for display
    String displayDate = '';
    try {
      displayDate = DateFormat('E, MMM d, yyyy').format(DateTime.parse(date));
    } catch (_) {
      displayDate = date;
    }

    // Format time for display (12-hour only)
    String displayTime = time;
    try {
      if (time.isNotEmpty) {
        final parsed = DateFormat('HH:mm:ss').parse(time);
        displayTime = DateFormat('h:mm a').format(parsed);
      }
    } catch (_) {}

    // Calculate relative time for the circle indicator
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? reservationDate;
    try {
      reservationDate = DateTime.parse(date);
    } catch (_) {
      reservationDate = null;
    }
    String circleText = '';
    if (reservationDate != null) {
      if (reservationDate == today) {
        circleText = 'Today';
      } else if (reservationDate == today.add(const Duration(days: 1))) {
        circleText = 'Tomorrow';
      } else {
        circleText = DateFormat('E, MMM d, yyyy').format(reservationDate);
      }
    }

    final bool isCancelled = reservation.status == 'cancelled';
    final bool isPast = reservationDate != null
        ? reservationDate.isBefore(DateTime.now())
        : false;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(16),
        vertical: getProportionateScreenHeight(8),
      ),
      child: ModernCard(
        borderRadius: 33,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(getProportionateScreenWidth(16)),
              decoration: BoxDecoration(
                color: cardColor,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(33)),
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
                    displayDate,
                  ),
                  SizedBox(height: getProportionateScreenHeight(12)),
                  _buildInfoRow(
                    theme,
                    Icons.access_time_rounded,
                    'Time',
                    displayTime,
                  ),
                  if (direction.isNotEmpty) ...[
                    SizedBox(height: getProportionateScreenHeight(12)),
                    _buildInfoRow(
                      theme,
                      Icons.compare_arrows_rounded,
                      'Direction',
                      direction,
                    ),
                  ],
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
                    ModernButton(
                      text: 'Cancel Reservation',
                      isPrimary: false,
                      width: double.infinity,
                      borderRadius: 33,
                      textColor: AppTheme.errorColor,
                      borderColor: AppTheme.errorColor,
                      onPressed: () async {
                        final reservationService =
                            context.read<ReservationService>();
                        try {
                          // Show confirmation dialog
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(16),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        getProportionateScreenWidth(33)),
                                    boxShadow: AppTheme.cardShadow,
                                  ),
                                  padding: EdgeInsets.all(
                                      getProportionateScreenWidth(24)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Cancel Reservation',
                                            style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      20),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            icon: const Icon(Icons.close),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                          height:
                                              getProportionateScreenHeight(16)),
                                      Text(
                                        'Are you sure you want to cancel this reservation?',
                                        style: TextStyle(
                                          fontSize:
                                              getProportionateScreenWidth(16),
                                          color: AppTheme.secondaryTextColor,
                                        ),
                                      ),
                                      SizedBox(
                                          height:
                                              getProportionateScreenHeight(24)),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: Text(
                                              'No',
                                              style: TextStyle(
                                                fontSize:
                                                    getProportionateScreenWidth(
                                                        16),
                                                color:
                                                    AppTheme.secondaryTextColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      16)),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: Text(
                                              'Yes, Cancel',
                                              style: TextStyle(
                                                fontSize:
                                                    getProportionateScreenWidth(
                                                        16),
                                                color: AppTheme.errorColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
        final reservation = reservations[index];
        // We need the original index from the full list for consistent coloring
        final originalIndex = context
            .read<ReservationService>()
            .reservations
            .indexOf(reservation);
        return _buildReservationCard(
            reservation, Theme.of(context), originalIndex);
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
