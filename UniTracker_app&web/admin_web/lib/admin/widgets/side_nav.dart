import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';

class SideNav extends StatelessWidget {
  final String selectedRoute;
  const SideNav({Key? key, required this.selectedRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: const Text(
              'UniTracker Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildNavItem(context, Icons.dashboard, 'Dashboard', '/'),
          _buildNavItem(context, Icons.directions_bus, 'Buses', '/admin/buses'),
          _buildNavItem(context, Icons.map, 'Routes', '/admin/routes'),
          _buildNavItem(
              context, Icons.calendar_today, 'Schedule', '/admin/schedule'),
          _buildNavItem(context, Icons.people, 'Drivers', '/admin/drivers'),
          _buildNavItem(context, Icons.settings, 'Settings', '/admin/settings'),
          _buildNavItem(context, Icons.event_seat, 'Reservations',
              '/admin/reservation-slots'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String title, String route) {
    final bool isSelected = selectedRoute == route;
    return ListTile(
      leading:
          Icon(icon, color: isSelected ? Colors.white : AppTheme.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? AppTheme.primaryColor : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: () {
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushReplacementNamed(context, route);
        } else {
          Navigator.pop(context);
        }
      },
    );
  }
}
