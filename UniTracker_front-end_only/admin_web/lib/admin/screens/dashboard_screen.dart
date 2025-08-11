import 'package:flutter/material.dart';
import 'package:admin_web/admin/screens/modern_buses_screen.dart';
import 'package:admin_web/admin/screens/modern_routes_screen.dart';
import 'package:admin_web/admin/screens/modern_schedule_screen.dart';
import 'package:admin_web/admin/screens/modern_drivers_screen.dart';
import 'package:admin_web/admin/screens/modern_settings_screen.dart';
import 'package:admin_web/admin/screens/modern_reservations_screen.dart';
import 'package:admin_web/admin/screens/modern_dashboard_screen.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/admin/widgets/modern_top_bar.dart';
import 'package:admin_web/admin/widgets/modern_sidebar.dart';

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
    'Reservations',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Row(
        children: [
          ModernSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            navItems: _navItems,
          ),
          Expanded(
            child: Column(
              children: [
                ModernTopBar(
                  title: _navItems[_selectedIndex],
                  onSearch: (query) {
                    // Handle search functionality
                    print('Search: $query');
                  },
                  onProfileTap: () {
                    // Navigate to settings screen for profile
                    setState(() {
                      _selectedIndex = 6; // Settings index
                    });
                  },
                ),
                Expanded(
                  child: _getSelectedScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const ModernDashboardScreen();
      case 1:
        return const ModernBusesScreen();
      case 2:
        return const ModernRoutesScreen();
      case 3:
        return const ModernScheduleScreen();
      case 4:
        return const ModernDriversScreen();
      case 5:
        return const ModernReservationsScreen();
      case 6:
        return const ModernSettingsScreen();
      default:
        return const ModernDashboardScreen();
    }
  }
}
