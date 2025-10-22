import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/admin/screens/admin_login_screen.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class AdminTopBar extends StatelessWidget {
  final String title;

  const AdminTopBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Logo and UniTracker Title
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/bus_logo.png',
                    width: screenWidth < 400 ? 24 : 32,
                    height: screenWidth < 400 ? 24 : 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'UniTracker',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth < 400 ? 16 : 22,
                      color: AppTheme.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Center: Search Bar
          Expanded(
            flex: 3,
            child: Center(
              child: SizedBox(
                width: 300,
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Right: Notification, Avatar, Admin Dropdown
          Flexible(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: AppTheme.primaryColor,
                  onPressed: () {
                    // Handle notifications
                  },
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  offset: const Offset(0, 40),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person_outline,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                      ),
                    ],
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline),
                          SizedBox(width: 8),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        // Handle profile
                        break;
                      case 'logout':
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const AdminLoginScreen()),
                          (route) => false,
                        );
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
