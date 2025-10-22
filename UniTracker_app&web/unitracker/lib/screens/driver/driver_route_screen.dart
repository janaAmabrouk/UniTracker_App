import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/route.dart';
import '../../models/bus.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import 'package:provider/provider.dart';
import '../../models/driver_activity.dart';
import '../../providers/driver_provider.dart';
import '../../services/notification_service.dart';
import '../../screens/driver/driver_notifications_screen.dart';

class DriverRouteScreen extends StatefulWidget {
  const DriverRouteScreen({super.key});

  @override
  State<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends State<DriverRouteScreen> {
  bool _isLoading = true;
  bool _isMapVisible = true;
  BusRoute? _currentRoute;
  Bus? _currentBus;
  double _routeProgress = 0.0;

  final List<Map<String, dynamic>> stops = [
    {
      'id': 1,
      'name': 'Cornishe El Maadi',
      'status': 'current',
      'scheduledTime': '07:30 AM',
      'arrived': false,
      'departed': false,
    },
    {
      'id': 2,
      'name': 'El Horia Square',
      'status': 'upcoming',
      'scheduledTime': '07:40 AM',
      'arrived': false,
      'departed': false,
    },
    {
      'id': 3,
      'name': 'Victoria Square',
      'status': 'upcoming',
      'scheduledTime': '07:50 AM',
      'arrived': false,
      'departed': false,
    },
    {
      'id': 4,
      'name': 'Maadi Grand Mall',
      'status': 'upcoming',
      'scheduledTime': '08:05 AM',
      'arrived': false,
      'departed': false,
    },
    {
      'id': 5,
      'name': 'Watanya Gas Station',
      'status': 'upcoming',
      'scheduledTime': '08:20 AM',
      'arrived': false,
      'departed': false,
    },
    {
      'id': 6,
      'name': 'EUI Campus',
      'status': 'upcoming',
      'scheduledTime': '08:50 AM',
      'arrived': false,
      'departed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    setState(() => _isLoading = true);
    // TODO: Load route data from your data provider
    setState(() => _isLoading = false);
  }

  void _handleMarkAsArrived(int stopId) {
    setState(() {
      int completedStops = 0;
      for (var stop in stops) {
        if (stop['id'] == stopId) {
          stop['status'] = 'completed';
          stop['arrived'] = true;
        }
        // Count completed stops for progress calculation
        if (stop['status'] == 'completed') {
          completedStops++;
        }
        // Update next stop status
        if (!stop['arrived'] && stop['status'] != 'completed') {
          stop['status'] = 'current';
          break;
        }
      }

      // Calculate progress percentage
      _routeProgress = (completedStops / stops.length) * 100;
    });

    // Add recent activity if trip is completed
    if (_isRouteFullyCompleted()) {
      final provider = Provider.of<DriverProvider>(context, listen: false);
      provider.addActivity(
        DriverActivity(
          id: DateTime.now().toIso8601String(),
          type: DriverActivityType.tripCompleted,
          description: 'Trip completed successfully',
          timestamp: DateTime.now(),
          status: DriverActivityStatus.completed,
        ),
      );
    }

    // Show confirmation snackbar
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
              child: Icon(
                Icons.check,
                color: Colors.green[700],
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Marked as arrived at stop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(33),
        ),
      ),
    );
  }

  // Add method to check if the stop is current
  bool isCurrentStop(Map<String, dynamic> stop) {
    return stop['status'] == 'current';
  }

  // Add method to get current stop
  Map<String, dynamic>? getCurrentStop() {
    return stops.firstWhere(
      (stop) => stop['status'] == 'current',
      orElse: () => stops.last,
    );
  }

  // Helper to check if current stop is the last stop
  bool isLastStop() {
    final current = getCurrentStop();
    return current != null && stops.indexOf(current) == stops.length - 1;
  }

  // Add this helper method to check if trip has started
  bool _hasTripStarted() {
    return stops.any(
        (stop) => stop['status'] == 'completed' || stop['status'] == 'current');
  }

  // Add this helper method to check if we're at first stop
  bool _isAtFirstStop() {
    return stops.first['status'] == 'current' &&
        !stops.any((stop) => stop['status'] == 'completed');
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppTheme.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // For iOS
      ),
    );
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          // Custom AppBar
          Container(
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.only(
              right: 10,
              top: 4,
              bottom: 4,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Driver Dashboard',
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      fontSize: getProportionateScreenWidth(20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Consumer<NotificationService>(
                    builder: (context, notificationService, _) => Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const DriverNotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        if (notificationService.unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  '${notificationService.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 4),
                      // Route Card with Map Preview
                      Stack(
                        children: [
                          Container(
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
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.directions_bus_outlined,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Maadi Route',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textColor,
                                              ),
                                            ),
                                            Wrap(
                                              spacing: 4,
                                              children: [
                                                Text(
                                                  'Cornishe El Maadi',
                                                  style: TextStyle(
                                                    color: AppTheme
                                                        .secondaryTextColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.arrow_forward,
                                                      size: 12,
                                                      color: AppTheme
                                                          .secondaryTextColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'EUI Campus',
                                                      style: TextStyle(
                                                        color: AppTheme
                                                            .secondaryTextColor,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor,
                                          borderRadius:
                                              BorderRadius.circular(33),
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
                                ),
                                if (_isMapVisible)
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(33),
                                        bottomRight: Radius.circular(33),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        const Center(
                                          child: Text('Map View'),
                                        ),
                                        Positioned(
                                          right: 16,
                                          bottom: 16,
                                          child: FloatingActionButton.small(
                                            onPressed: () {
                                              setState(() {
                                                _isMapVisible = false;
                                              });
                                            },
                                            backgroundColor: Colors.white,
                                            child: const Icon(
                                              Icons.close,
                                              color: Color(0xFF2B2087),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (!_isMapVisible) ...[
                        const SizedBox(height: 16),
                        // Map Toggle Button
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(33),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.10),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(33),
                                onTap: () {
                                  setState(() {
                                    _isMapVisible = true;
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.map_outlined,
                                        color: AppTheme.primaryColor,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Show Map View',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Route Progress Section
                      Container(
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(33),
                                        ),
                                        child: Text(
                                          '${_routeProgress.toInt()}%',
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
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: _routeProgress / 100,
                                        child: Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF2B2087),
                                                Color(0xFF4B42A9),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(3),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                      color: AppTheme
                                                          .secondaryTextColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    getCurrentStop()?['name'] ??
                                                        '',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _getNextStopName(),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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

                      const SizedBox(height: 24),

                      // Current Stop Section
                      Container(
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
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              getCurrentStop()?['name'] ??
                                                  'No current stop',
                                              style: TextStyle(
                                                color:
                                                    AppTheme.secondaryTextColor,
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
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.3),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(33),
                                        ),
                                        child: Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 4,
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 12,
                                              color: AppTheme.primaryColor,
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Scheduled:',
                                                      style: TextStyle(
                                                        color: AppTheme
                                                            .primaryColor,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      getCurrentStop()?[
                                                              'scheduledTime'] ??
                                                          '--:--',
                                                      style: TextStyle(
                                                        color: AppTheme
                                                            .primaryColor,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
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
                                    child: ElevatedButton(
                                      onPressed: getCurrentStop() != null &&
                                              !_isRouteFullyCompleted()
                                          ? () {
                                              if (isLastStop()) {
                                                // Mark the last stop as completed
                                                _handleMarkAsArrived(
                                                    getCurrentStop()!['id']);
                                              } else {
                                                _handleMarkAsArrived(
                                                    getCurrentStop()!['id']);
                                              }
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(33),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        !_hasTripStarted()
                                            ? 'Start Trip'
                                            : _isAtFirstStop()
                                                ? 'Trip Started'
                                                : isLastStop()
                                                    ? 'Trip Completed'
                                                    : 'Mark as Arrived',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Route Stops Section
                      Container(
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
                            _buildStopsList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopsList() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stops.length,
      separatorBuilder: (context, index) => Divider(
        color: AppTheme.dividerColor,
        height: 1,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final stop = stops[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: stop['status'] == 'current'
                      ? AppTheme.primaryColor
                      : AppTheme.secondaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stop['status'] == 'current'
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: stop['status'] == 'current'
                          ? Colors.white
                          : AppTheme.primaryColor,
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
                      stop['name'],
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
                          stop['scheduledTime'],
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
                  color: stop['status'] == 'current'
                      ? AppTheme.secondaryColor
                      : _getStatusColor(stop['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(33),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stop['status'] == 'current') ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusColor(stop['status']),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _getStatusText(stop['status']),
                      style: TextStyle(
                        color: _getStatusColor(stop['status']),
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
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'current':
        return AppTheme.primaryColor;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'current':
        return 'Current';
      case 'completed':
        return 'Completed';
      default:
        return 'Upcoming';
    }
  }

  // Helper methods for next stop
  String _getNextStopName() {
    final currentIndex =
        stops.indexWhere((stop) => stop['status'] == 'current');
    if (currentIndex != -1 && currentIndex + 1 < stops.length) {
      return stops[currentIndex + 1]['name'];
    }
    return '—';
  }

  String _getNextStopTime() {
    final currentIndex =
        stops.indexWhere((stop) => stop['status'] == 'current');
    if (currentIndex != -1 && currentIndex + 1 < stops.length) {
      return stops[currentIndex + 1]['scheduledTime'];
    }
    return '—';
  }

  bool _isRouteFullyCompleted() {
    // All stops are completed if none are current
    return !stops.any((stop) => stop['status'] == 'current');
  }
}
