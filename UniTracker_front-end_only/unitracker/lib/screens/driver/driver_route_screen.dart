import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../../services/driver_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/modern_widgets.dart';
import '../driver/driver_notifications_screen.dart';

class DriverRouteScreen extends StatefulWidget {
  const DriverRouteScreen({super.key});

  @override
  State<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends State<DriverRouteScreen> {
  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      debugPrint(
          '🚗 DriverRouteScreen: Current user: ${currentUser?.name}, Role: ${currentUser?.role}, ID: ${currentUser?.id}');

      if (currentUser != null && currentUser.role == 'driver') {
        debugPrint(
            '🚗 DriverRouteScreen: Loading driver data for ID: ${currentUser.id}');
        await DriverService.instance.loadDriverData(currentUser.id);
      } else {
        debugPrint('⚠️ DriverRouteScreen: No driver user found or wrong role');
      }
    } catch (e) {
      debugPrint('❌ DriverRouteScreen: Error loading driver data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DriverService.instance,
      builder: (context, child) {
        final driverService = DriverService.instance;

        if (driverService.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                'Driver Dashboard',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            body: const Center(
              child: ModernLoadingIndicator(size: 60),
            ),
          );
        }

        if (driverService.error != null) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                'Driver Dashboard',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${driverService.error}'),
                  ElevatedButton(
                    onPressed: _loadDriverData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (driverService.assignedRoute == null) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                'Driver Dashboard',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Route Assigned',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please contact your supervisor for route assignment.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!driverService.hasScheduleToday) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                'Driver Dashboard',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Schedule Today',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your route "${driverService.assignedRoute!.name}" is not scheduled for ${_getDayName(DateTime.now().weekday)}.',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scheduled days: ${_getShortScheduledDays(driverService.scheduledDays)}',
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return _buildDriverDashboard(context, driverService);
      },
    );
  }

  Widget _buildDriverDashboard(
      BuildContext context, DriverService driverService) {
    SizeConfig.init(context);
    final isTablet = SizeConfig.screenWidth > 600;
    final padding = getProportionateScreenWidth(isTablet ? 24 : 16);

    final route = driverService.assignedRoute!;
    final stops = driverService.routeStops;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Driver Dashboard',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DriverNotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (notificationService.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${notificationService.unreadCount}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Route Info Card
            AnimatedSlideIn(
              index: 0,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B2087),
                                ),
                              ),
                              Text(
                                '${route.pickup} → ${route.drop}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(33),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: AppTheme.successColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Active',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Schedule',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Start Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'End Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getShortScheduledDays(
                                    driverService.scheduledDays),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                softWrap: true,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                route.startTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                route.endTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Route Progress Section
            if (driverService.isTripInProgress) ...[
              AnimatedSlideIn(
                index: 1,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(33),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Route Progress',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B2087),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(33),
                                  ),
                                  child: Text(
                                    '${_calculateProgress(driverService)}%',
                                    style: const TextStyle(
                                      color: Color(0xFF2B2087),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Stack(
                              children: [
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor:
                                      _calculateProgress(driverService) / 100,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2B2087),
                                          Color(0xFF4B42A9),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(33),
                            bottomRight: Radius.circular(33),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.location_on_outlined,
                                          size: 12,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Wrap(
                                          children: [
                                            Text(
                                              'Current',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppTheme.secondaryTextColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _getCurrentStopName(
                                                  driverService),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey[300],
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.location_on_outlined,
                                          size: 12,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Wrap(
                                          children: [
                                            Text(
                                              'Next',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _getNextStopName(driverService),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey[300],
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.schedule,
                                          size: 12,
                                          color: AppTheme.successColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'On Time',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Current Stop Card (if trip is in progress)
            if (driverService.isTripInProgress) ...[
              AnimatedSlideIn(
                index: 2,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(33),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Stop',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B2087),
                                  ),
                                ),
                                Text(
                                  driverService.routeStops.isNotEmpty &&
                                          driverService.currentStopIndex <
                                              driverService.routeStops.length
                                      ? driverService
                                              .routeStops[driverService
                                                  .currentStopIndex]
                                              .name ??
                                          'No current stop'
                                      : 'No current stop',
                                  style: TextStyle(
                                    color: AppTheme.secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(33),
                            ),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: AppTheme.primaryColor,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Scheduled:',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      driverService.routeStops.isNotEmpty &&
                                              driverService.currentStopIndex <
                                                  driverService
                                                      .routeStops.length
                                          ? (driverService
                                                  .routeStops[driverService
                                                      .currentStopIndex]
                                                  .arrivalTime ??
                                              '--:--')
                                          : '--:--',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _buildTripActionButton(context, driverService),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Trip Action Button when not in progress
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTripActionButton(context, driverService),
              ),
              const SizedBox(height: 16),
            ],

            // Route Stops
            AnimatedSlideIn(
              index: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(33),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.format_list_bulleted,
                              color: Color(0xFF2B2087),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Route Stops',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B2087),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: stops.length,
                      itemBuilder: (context, index) => _buildStopItem(
                          context, driverService, stops[index], index),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStopItem(BuildContext context, DriverService driverService,
      dynamic stop, int index) {
    try {
      final stopCheckIns = driverService.stopCheckIns;
      final isCheckedIn = index < stopCheckIns.length && stopCheckIns[index];
      final isCurrentStop = driverService.isTripInProgress &&
          index == driverService.currentStopIndex;
      final isPastStop = index < driverService.currentStopIndex;
      final isUpcoming = index > driverService.currentStopIndex;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCurrentStop
                    ? AppTheme.primaryColor
                    : AppTheme.secondaryColor.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentStop
                      ? AppTheme.primaryColor
                      : AppTheme.secondaryColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrentStop ? Colors.white : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name ?? 'Stop ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stop.arrivalTime ?? '--:--',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isCurrentStop
                    ? AppTheme.secondaryColor
                    : _getStatusColor(isCheckedIn, isCurrentStop, isUpcoming)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(33),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCurrentStop) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                            isCheckedIn, isCurrentStop, isUpcoming),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _getStatusText(isCheckedIn, isCurrentStop, isUpcoming),
                    style: TextStyle(
                      color: _getStatusColor(
                          isCheckedIn, isCurrentStop, isUpcoming),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error building stop item: $e');
      return Container();
    }
  }

  Color _getStatusColor(bool isCheckedIn, bool isCurrentStop, bool isUpcoming) {
    if (isCheckedIn) {
      return Colors.green;
    } else if (isCurrentStop) {
      return AppTheme.primaryColor;
    } else {
      return Colors.grey;
    }
  }

  String _getStatusText(bool isCheckedIn, bool isCurrentStop, bool isUpcoming) {
    if (isCheckedIn) {
      return 'Completed';
    } else if (isCurrentStop) {
      return 'Current';
    } else {
      return 'Upcoming';
    }
  }

  Widget _buildTripActionButton(
      BuildContext context, DriverService driverService) {
    try {
      // Check if trip is completed today
      if (driverService.isTripCompletedToday) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Trip Completed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        );
      }

      if (driverService.canStartTrip) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleStartTrip(context, driverService),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(33),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Start Trip',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }

      if (driverService.isTripInProgress) {
        final currentIndex = driverService.currentStopIndex;
        final stops = driverService.routeStops;

        if (currentIndex < stops.length) {
          final isLastStop = currentIndex >= stops.length - 1;
          final currentStop = stops[currentIndex];

          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleCheckIn(
                  context, driverService, currentIndex, isLastStop),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(33),
                ),
                elevation: 0,
              ),
              child: Text(
                isLastStop ? 'Complete Trip' : 'Mark as Arrived',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Text(
          'No Trip Available',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building trip action button: $e');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Text(
          'Error',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      );
    }
  }

  Future<void> _handleStartTrip(
      BuildContext context, DriverService driverService) async {
    try {
      await driverService.startTrip();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Trip started! Check in at each stop.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(33),
            ),
            duration: const Duration(seconds: 2),
            elevation: 0,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting trip: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(33),
            ),
            elevation: 0,
          ),
        );
      }
    }
  }

  Future<void> _handleCheckIn(BuildContext context, DriverService driverService,
      int stopIndex, bool isLastStop) async {
    try {
      await driverService.checkInAtStop(stopIndex);
      if (mounted) {
        final stopName = driverService.routeStops[stopIndex].name;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isLastStop
                        ? 'Trip completed successfully!'
                        : 'Marked as arrived at stop',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(33),
            ),
            duration: const Duration(seconds: 2),
            elevation: 0,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(33),
            ),
            elevation: 0,
          ),
        );
      }
    }
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  int _calculateProgress(DriverService driverService) {
    if (!driverService.isTripInProgress || driverService.routeStops.isEmpty) {
      return 0;
    }

    final totalStops = driverService.routeStops.length;
    final completedStops = driverService.currentStopIndex;

    if (completedStops >= totalStops) {
      return 100;
    }

    return ((completedStops / totalStops) * 100).round();
  }

  String _getCurrentStopName(DriverService driverService) {
    if (!driverService.isTripInProgress ||
        driverService.currentStopIndex >= driverService.routeStops.length) {
      return 'No current stop';
    }

    final currentStop =
        driverService.routeStops[driverService.currentStopIndex];
    return currentStop.name ?? 'Stop ${driverService.currentStopIndex + 1}';
  }

  String _getNextStopName(DriverService driverService) {
    final nextIndex = driverService.currentStopIndex + 1;

    if (!driverService.isTripInProgress ||
        nextIndex >= driverService.routeStops.length) {
      return 'Trip End';
    }

    final nextStop = driverService.routeStops[nextIndex];
    return nextStop.name ?? 'Stop ${nextIndex + 1}';
  }

  void _showCompleteTrip(BuildContext context, DriverService driverService) {
    final passengerCountController = TextEditingController();
    final notesController = TextEditingController();
    bool onTime = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passengerCountController,
              decoration: const InputDecoration(
                labelText: 'Passenger Count',
                hintText: 'Enter number of passengers',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => CheckboxListTile(
                title: const Text('Trip completed on time'),
                value: onTime,
                onChanged: (value) => setState(() => onTime = value ?? true),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Any additional notes...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final passengerCount =
                    int.tryParse(passengerCountController.text) ?? 0;

                await driverService.completeTrip(
                  passengerCount: passengerCount,
                  distanceKm: 45.5,
                  onTime: onTime,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );

                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trip completed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error completing trip: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[dayOfWeek];
  }

  String _getShortScheduledDays(String days) {
    return days
        .replaceAll('Sunday', 'Sun')
        .replaceAll('Monday', 'Mon')
        .replaceAll('Tuesday', 'Tue')
        .replaceAll('Wednesday', 'Wed')
        .replaceAll('Thursday', 'Thu')
        .replaceAll('Friday', 'Fri')
        .replaceAll('Saturday', 'Sat');
  }

  String _getTripActionButtonText(DriverService driverService) {
    if (driverService.isTripCompletedToday) {
      return 'Trip Completed';
    } else if (driverService.canStartTrip) {
      return 'Start Trip';
    } else if (driverService.isTripInProgress) {
      final currentIndex = driverService.currentStopIndex;
      final stops = driverService.routeStops;
      final isLastStop = currentIndex >= stops.length - 1;
      return isLastStop ? 'Complete Trip' : 'Mark as Arrived';
    } else {
      return 'No Trip Available';
    }
  }
}
