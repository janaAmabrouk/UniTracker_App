import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitracker/utils/responsive_utils.dart';
import 'package:unitracker/screens/schedules/schedules_screen.dart';
import 'package:unitracker/screens/reservations/reservations_screen.dart';
import 'package:unitracker/screens/notifications/notifications_screen.dart';
import 'package:unitracker/screens/profile/profile_screen.dart';
import 'package:unitracker/services/reservation_service.dart';
import 'package:unitracker/services/notification_service.dart';
import 'package:unitracker/services/notification_settings_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unitracker/services/location_service.dart';
import 'package:unitracker/screens/map/map_screen.dart';
import 'package:unitracker/models/bus_route.dart';
import 'package:unitracker/services/map_service.dart';
import 'package:unitracker/providers/route_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>();
      context.read<NotificationSettingsService>();
    });
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const HomeContent();
      case 1:
        return const SchedulesScreen();
      case 2:
        return const ReservationsScreen();
      case 3:
        return const NotificationsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeContent();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // If notifications tab is selected, mark all notifications as read
    if (index == 3) {
      final notificationService = context.read<NotificationService>();
      for (var notification in notificationService.notifications) {
        if (!notification.isRead) {
          notificationService.markAsRead(notification.id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final theme = Theme.of(context);
    final reservationService = context.watch<ReservationService>();
    final notificationService = context.watch<NotificationService>();

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.white,
              foregroundColor: Colors.black,
              automaticallyImplyLeading: false,
              title: Container(
                height: getProportionateScreenHeight(40),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius:
                      BorderRadius.circular(getProportionateScreenWidth(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search routes, stops, or destinations...',
                    border: InputBorder.none,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(
                          left: getProportionateScreenWidth(4), right: 0),
                      child: Icon(Icons.search, color: Colors.grey[600]),
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: getProportionateScreenWidth(32),
                      minHeight: getProportionateScreenHeight(32),
                    ),
                    contentPadding: EdgeInsets.only(
                      left: 0,
                      top: getProportionateScreenHeight(8),
                      bottom: getProportionateScreenHeight(8),
                    ),
                  ),
                  style: TextStyle(fontSize: getProportionateScreenWidth(12)),
                ),
              ),
            )
          : null,
      backgroundColor: Colors.white,
      body: _getScreen(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(0),
            vertical: getProportionateScreenHeight(4),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: theme.primaryColor,
            unselectedItemColor: Colors.grey[600],
            selectedFontSize: getProportionateScreenWidth(11),
            unselectedFontSize: getProportionateScreenWidth(10),
            iconSize: getProportionateScreenWidth(20),
            backgroundColor: Colors.white,
            elevation: 0,
            showUnselectedLabels: true,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.2,
              fontSize: getProportionateScreenWidth(11),
              letterSpacing: -0.3,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.2,
              fontSize: getProportionateScreenWidth(10),
              letterSpacing: -0.3,
            ),
            landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
            items: List.generate(5, (index) {
              final items = [
                {
                  'icon': Icons.home_outlined,
                  'selectedIcon': Icons.home,
                  'label': 'Home'
                },
                {
                  'icon': Icons.calendar_today_outlined,
                  'selectedIcon': Icons.calendar_today,
                  'label': 'Schedules'
                },
                {
                  'icon': Icons.event_seat_outlined,
                  'selectedIcon': Icons.event_seat,
                  'label': 'Reservations'
                },
                {
                  'icon': Icons.notifications_outlined,
                  'selectedIcon': Icons.notifications,
                  'label': 'Notifications'
                },
                {
                  'icon': Icons.person_outline,
                  'selectedIcon': Icons.person,
                  'label': 'Profile'
                },
              ];

              final isSelected = _selectedIndex == index;

              if (index == 3 && notificationService.unreadCount > 0) {
                return BottomNavigationBarItem(
                  icon: SizedBox(
                    width: getProportionateScreenWidth(32),
                    height: getProportionateScreenHeight(24),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Icon(
                            isSelected
                                ? items[index]['selectedIcon'] as IconData
                                : items[index]['icon'] as IconData,
                            color: isSelected
                                ? theme.primaryColor
                                : Colors.grey[600],
                          ),
                        ),
                        Positioned(
                          right: -getProportionateScreenWidth(2),
                          top: -getProportionateScreenHeight(2),
                          child: Container(
                            padding:
                                EdgeInsets.all(getProportionateScreenWidth(2)),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: getProportionateScreenWidth(1.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: getProportionateScreenWidth(4),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                              minWidth: getProportionateScreenWidth(18),
                              minHeight: getProportionateScreenHeight(18),
                            ),
                            child: Center(
                              child: Text(
                                '${notificationService.unreadCount}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: getProportionateScreenWidth(11),
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  label: items[index]['label'] as String,
                  backgroundColor: Colors.transparent,
                );
              }

              return BottomNavigationBarItem(
                icon: Icon(
                  isSelected
                      ? items[index]['selectedIcon'] as IconData
                      : items[index]['icon'] as IconData,
                  color: isSelected ? theme.primaryColor : Colors.grey[600],
                ),
                label: items[index]['label'] as String,
                backgroundColor: Colors.transparent,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _selectedRouteId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final locationService = context.read<LocationService>();
      final mapService = context.read<MapService>();
      final routeProvider = context.read<RouteProvider>();

      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize location service
      await locationService.initialize();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to initialize map services. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocationService, MapService, RouteProvider>(
      builder: (context, locationService, mapService, routeProvider, child) {
        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeServices,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!locationService.hasPermission) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Location permission is required to show the map.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => locationService.initialize(),
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          );
        }

        if (locationService.currentLocation == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Getting your location...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return MapScreen(
          routes: routeProvider.routes,
          selectedRouteId: _selectedRouteId,
          onRouteSelect: (String? routeId) {
            setState(() {
              _selectedRouteId = routeId;
            });
          },
        );
      },
    );
  }
}
