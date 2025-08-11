import 'package:flutter/material.dart';
import 'package:admin_web/admin/screens/dashboard_screen.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/admin/screens/reservation_slot_management_screen.dart';
import 'package:admin_web/admin/screens/reservations_management_screen.dart';
import 'package:admin_web/admin/screens/modern_buses_screen.dart';
import 'package:admin_web/admin/screens/routes_screen_simple.dart';
import 'package:admin_web/admin/screens/drivers_screen_simple.dart';
import 'package:admin_web/admin/screens/admin_login_screen.dart';
import 'package:admin_web/admin/screens/modern_settings_screen.dart';
import 'package:admin_web/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

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
        '/admin/login': (context) =>
            const AdminLoginScreen(),
        '/admin/dashboard': (context) =>
            const AdminDashboardScreen(),
        '/admin/reservations': (context) =>
            const ReservationsManagementScreen(),
        '/admin/reservation-slots': (context) =>
            const ReservationSlotManagementScreen(),
        '/admin/buses': (context) =>
            const ModernBusesScreen(),
        '/admin/routes': (context) =>
            const SimpleRoutesScreen(),
        '/admin/drivers': (context) =>
            const SimpleDriversScreen(),
        '/admin/settings': (context) =>
            const ModernSettingsScreen(),
      },
    );
  }
}
