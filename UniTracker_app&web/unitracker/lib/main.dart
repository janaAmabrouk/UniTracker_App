import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unitracker/screens/auth/login_screen.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/services/auth_service.dart';
import 'package:unitracker/services/notification_service.dart';
import 'package:unitracker/services/notification_settings_service.dart';
import 'package:unitracker/services/reservation_service.dart';
import 'package:unitracker/services/driver_stats_service.dart';
import 'package:unitracker/providers/auth_provider.dart';
import 'package:unitracker/providers/route_provider.dart';
import 'package:unitracker/providers/driver_provider.dart';
import 'onboarding/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'package:unitracker/services/location_service.dart';
import 'services/map_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationSettingsService(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => DriverStatsService(),
        ),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(
          create: (_) => MapService(),
        ),
        ChangeNotifierProxyProvider2<NotificationService,
            NotificationSettingsService, ReservationService>(
          create: (context) => ReservationService.getInstance(
            context.read<NotificationService>(),
            context.read<NotificationSettingsService>(),
          ),
          update:
              (context, notificationService, notificationSettings, previous) =>
                  ReservationService.getInstance(
                      notificationService, notificationSettings),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniTracker',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(),
    );
  }
}
