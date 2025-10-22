import 'package:flutter/material.dart';
import 'package:admin_web/admin/screens/dashboard_screen.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/admin/screens/reservation_slot_management_screen.dart';
import 'package:admin_web/admin/screens/admin_login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AdminLoginScreen(),
      routes: {
        '/admin/reservation-slots': (context) =>
            const ReservationSlotManagementScreen(),
      },
    );
  }
}
