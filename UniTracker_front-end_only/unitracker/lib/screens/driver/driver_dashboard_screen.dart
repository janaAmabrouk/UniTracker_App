import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import 'driver_route_screen.dart';
import 'driver_notifications_screen.dart';
import 'driver_profile_screen.dart';
import 'package:unitracker/models/driver_notification.dart';
import 'package:unitracker/services/notification_service.dart';
import 'package:provider/provider.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  final List<String> _titles = [
    'Driver Dashboard',
    'Notifications',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      const DriverRouteScreen(),
      const DriverNotificationsScreen(),
      const DriverProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _screens[_selectedIndex],
      bottomNavigationBar: Consumer<NotificationService>(
        builder: (context, notificationService, _) => BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.route_outlined,
                  size: getProportionateScreenWidth(24)),
              activeIcon:
                  Icon(Icons.route, size: getProportionateScreenWidth(24)),
              label: 'Route',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: getProportionateScreenWidth(24)),
                  if (notificationService.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Center(
                          child: Text(
                            '${notificationService.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                children: [
                  Icon(Icons.notifications,
                      size: getProportionateScreenWidth(24)),
                  if (notificationService.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Center(
                          child: Text(
                            '${notificationService.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline,
                  size: getProportionateScreenWidth(24)),
              activeIcon:
                  Icon(Icons.person, size: getProportionateScreenWidth(24)),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF2B2087),
          selectedFontSize: getProportionateScreenWidth(14),
          unselectedFontSize: getProportionateScreenWidth(12),
          iconSize: getProportionateScreenWidth(24),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
