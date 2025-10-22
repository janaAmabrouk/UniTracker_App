import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'side_nav.dart';
import 'top_bar.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String selectedRoute;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
    required this.selectedRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation
          SideNav(selectedRoute: selectedRoute),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                AdminTopBar(title: title),

                // Main Content Area
                Expanded(
                  child: Container(
                    color: AppTheme.lightTheme.scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
