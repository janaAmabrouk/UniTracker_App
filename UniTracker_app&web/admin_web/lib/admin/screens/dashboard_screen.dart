import 'package:flutter/material.dart';
import 'package:admin_web/admin/screens/buses_screen.dart';
import 'package:admin_web/admin/screens/routes_screen.dart';
import 'package:admin_web/admin/screens/schedule_screen.dart';
import 'package:admin_web/admin/screens/drivers_screen.dart';
import 'package:admin_web/admin/screens/settings_screen.dart';
import 'package:admin_web/admin/screens/reservation_slot_management_screen.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/admin/widgets/top_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _navItems = [
    'Dashboard',
    'Buses',
    'Routes',
    'Schedule',
    'Drivers',
    'Settings',
    'Reservations',
  ];
  final List<IconData> _navIcons = [
    Icons.bar_chart_outlined,
    Icons.directions_bus_outlined,
    Icons.alt_route_outlined,
    Icons.calendar_today_outlined,
    Icons.people_outline,
    Icons.settings_outlined,
    Icons.event_seat,
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: isWide ? null : Drawer(child: _buildDrawerContent(isWide)),
      body: Row(
        children: [
          if (isWide)
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                border: Border(
                  right: BorderSide(color: AppTheme.dividerColor, width: 1),
                ),
              ),
              child: _buildDrawerContent(isWide),
            ),
          Expanded(
            child: Column(
              children: [
                AdminTopBar(title: _navItems[_selectedIndex]),
                Expanded(
                  child: _selectedIndex == 6
                      ? const ReservationSlotManagementScreen()
                      : _selectedIndex == 5
                          ? const AdminSettingsScreen()
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 24),
                              child: _selectedIndex == 0
                                  ? const _DashboardContent()
                                  : _selectedIndex == 1
                                      ? const AdminBusesScreen()
                                      : _selectedIndex == 2
                                          ? const RoutesScreen()
                                          : _selectedIndex == 3
                                              ? const AdminScheduleScreen()
                                              : const AdminDriversScreen(),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerContent(bool isWide) {
    return Column(
      children: [
        const SizedBox(height: 16),
        ...List.generate(_navItems.length, (index) {
          final selected = _selectedIndex == index;
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                if (!isWide) Navigator.of(context).pop();
              },
              child: Container(
                height: 48,
                decoration: selected
                    ? BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(
                      _navIcons[index],
                      color:
                          selected ? AppTheme.cardColor : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 18),
                    Text(
                      _navItems[index],
                      style: TextStyle(
                        color:
                            selected ? AppTheme.cardColor : AppTheme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Dashboard',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            _StatCardsWrap(),
            const SizedBox(height: 24),
            // Only use Row if screen is very wide
            screenWidth > 1200
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(flex: 5, child: _LiveBusTrackingCard()),
                      const SizedBox(width: 16),
                      Flexible(flex: 4, child: _RecentAlertsCard()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LiveBusTrackingCard(),
                      const SizedBox(height: 16),
                      _RecentAlertsCard(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatCardsWrap extends StatelessWidget {
  const _StatCardsWrap();
  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'title': 'Active Buses',
        'value': '12',
        'icon': Icons.directions_bus,
        'description': 'Out of 15 total',
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'Active Routes',
        'value': '8',
        'icon': Icons.alt_route,
        'description': 'Across campus',
        'color': AppTheme.infoColor,
      },
      {
        'title': 'On-Time Rate',
        'value': '94%',
        'icon': Icons.access_time,
        'description': 'Last 24 hours',
        'color': AppTheme.successColor,
      },
      {
        'title': 'Issues',
        'value': '2',
        'icon': Icons.warning_amber_rounded,
        'description': 'Require attention',
        'color': AppTheme.errorColor,
      },
    ];
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      // Always fit in the same row on wide screens
      return Row(
        children: stats
            .map((stat) => Expanded(child: _StatCard(stat: stat)))
            .toList(),
      );
    } else if (screenWidth > 700) {
      // Two cards per row
      return Wrap(
        spacing: 24,
        runSpacing: 16,
        children: stats
            .map((stat) => SizedBox(
                  width: (screenWidth - 3 * 24) / 2,
                  child: _StatCard(stat: stat),
                ))
            .toList(),
      );
    } else {
      // Stack vertically
      return Column(
        children: stats
            .map((stat) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _StatCard(stat: stat),
                ))
            .toList(),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> stat;
  const _StatCard({required this.stat});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(stat['icon'] as IconData,
                      color: stat['color'] as Color, size: 24),
                ),
                Spacer(),
                Text(stat['value'] as String,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor)),
              ],
            ),
            SizedBox(height: 12),
            Text(stat['title'] as String,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.textColor)),
            SizedBox(height: 4),
            Text(stat['description'] as String,
                style: TextStyle(
                    color: AppTheme.secondaryTextColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _LiveBusTrackingCard extends StatefulWidget {
  const _LiveBusTrackingCard();
  @override
  State<_LiveBusTrackingCard> createState() => _LiveBusTrackingCardState();
}

class _LiveBusTrackingCardState extends State<_LiveBusTrackingCard> {
  LatLng? _currentPosition;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        setState(() {
          _locationError = 'Location services are disabled.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          setState(() {
            _locationError = 'Location permissions are denied.';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied.');
        setState(() {
          _locationError = 'Location permissions are permanently denied.';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _locationError = null;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _locationError = 'Error getting location: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth < 600
        ? 140.0
        : screenWidth < 900
            ? 180.0
            : 260.0;
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(screenWidth < 600 ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Bus Tracking',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth < 400 ? 16 : 20,
                    color: AppTheme.textColor)),
            SizedBox(height: 2),
            Text('Real-time location of all university buses',
                style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: screenWidth < 400 ? 12 : 14)),
            SizedBox(height: screenWidth < 600 ? 10 : 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: _currentPosition != null
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition!,
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('me'),
                            position: _currentPosition!,
                            infoWindow: const InfoWindow(title: 'You are here'),
                          ),
                        },
                      )
                    : _locationError != null
                        ? Center(
                            child: Text(_locationError!,
                                textAlign: TextAlign.center))
                        : const Center(child: CircularProgressIndicator()),
              ),
            ),
            SizedBox(height: screenWidth < 600 ? 10 : 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bus Status',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                OutlinedButton(
                  onPressed: () {},
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(80, 36)),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _BusStatusList(),
          ],
        ),
      ),
    );
  }
}

class _BusStatusList extends StatelessWidget {
  const _BusStatusList();
  @override
  Widget build(BuildContext context) {
    final buses = [
      {
        'name': 'Bus 101',
        'route': 'North Campus',
        'status': 'On Time',
        'color': Colors.green
      },
      {
        'name': 'Bus 102',
        'route': 'South Campus',
        'status': 'On Time',
        'color': Colors.green
      },
      {
        'name': 'Bus 103',
        'route': 'East Campus',
        'status': 'Delayed',
        'color': Colors.amber
      },
      {
        'name': 'Bus 104',
        'route': 'West Campus',
        'status': 'On Time',
        'color': Colors.green
      },
    ];
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: buses.map((bus) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: bus['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text('${bus['name']}',
                    style: TextStyle(
                        fontSize: screenWidth < 400 ? 12 : 15,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(width: 8),
              Flexible(
                flex: 3,
                child: Text('${bus['route']}',
                    style: TextStyle(
                        fontSize: screenWidth < 400 ? 11 : 14,
                        color: AppTheme.secondaryTextColor),
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text('${bus['status']}',
                    style: TextStyle(
                        fontSize: screenWidth < 400 ? 11 : 14,
                        color: bus['color'] as Color,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecentAlertsCard extends StatelessWidget {
  const _RecentAlertsCard();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(screenWidth < 600 ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Alerts',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth < 400 ? 16 : 20,
                    color: AppTheme.textColor)),
            SizedBox(height: 2),
            Text('Latest notifications and issues',
                style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: screenWidth < 400 ? 12 : 14)),
            SizedBox(height: screenWidth < 600 ? 10 : 18),
            _RecentAlerts(),
          ],
        ),
      ),
    );
  }
}

class _RecentAlerts extends StatefulWidget {
  const _RecentAlerts();
  @override
  State<_RecentAlerts> createState() => _RecentAlertsState();
}

class _RecentAlertsState extends State<_RecentAlerts> {
  List<Map<String, dynamic>> alerts = [
    {
      'id': 1,
      'title': 'Bus 103 Delayed',
      'description': 'Mechanical issue, estimated 15 min delay',
      'timestamp': '10:23 AM',
      'severity': 'warning',
      'resolved': false,
    },
    {
      'id': 2,
      'title': 'Route Diversion',
      'description': 'Construction on Main St, buses rerouted via College Ave',
      'timestamp': '9:15 AM',
      'severity': 'info',
      'resolved': false,
    },
    {
      'id': 3,
      'title': 'Bus 105 Out of Service',
      'description': 'Maintenance required, replacement bus dispatched',
      'timestamp': 'Yesterday',
      'severity': 'error',
      'resolved': true,
    },
    {
      'id': 4,
      'title': 'Schedule Change',
      'description': 'Weekend schedule adjusted for campus event',
      'timestamp': 'Yesterday',
      'severity': 'info',
      'resolved': true,
    },
  ];
  String filter = 'all';

  List<Map<String, dynamic>> get filteredAlerts {
    if (filter == 'all') return alerts;
    if (filter == 'active') return alerts.where((a) => !a['resolved']).toList();
    if (filter == 'resolved')
      return alerts.where((a) => a['resolved']).toList();
    return alerts;
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'error':
        return AppTheme.errorColor;
      case 'warning':
        return AppTheme.warningColor;
      case 'info':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'error':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Use Wrap for filter buttons
        Wrap(
          spacing: 8,
          children: [
            _filterButton('All', 'all'),
            _filterButton('Active', 'active'),
            _filterButton('Resolved', 'resolved'),
          ],
        ),
        const SizedBox(height: 16),
        if (filteredAlerts.isEmpty)
          Column(
            children: [
              Icon(Icons.check_circle, color: Colors.grey, size: 40),
              SizedBox(height: 8),
              Text('No alerts to display',
                  style: TextStyle(color: Colors.grey)),
            ],
          )
        else
          Column(
            children: filteredAlerts.map((alert) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_severityIcon(alert['severity']),
                        color: _severityColor(alert['severity']), size: 28),
                    const SizedBox(width: 14),
                    // Use Flexible for all text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(alert['title'].toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: AppTheme.textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (alert['resolved'])
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dividerColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Resolved',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.secondaryTextColor)),
                                ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(alert['description'].toString(),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.secondaryTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          SizedBox(height: 2),
                          Text(alert['timestamp'].toString(),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondaryTextColor
                                      .withOpacity(0.6)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (!alert['resolved'])
                      Flexible(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              alert['resolved'] = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Resolve',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _filterButton(String label, String value) {
    final selected = filter == value;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppTheme.primaryColor : AppTheme.cardColor,
        foregroundColor: selected ? AppTheme.cardColor : AppTheme.primaryColor,
        side: BorderSide(
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor),
        minimumSize: const Size(80, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        setState(() {
          filter = value;
        });
      },
      child: Text(label,
          style: TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}
