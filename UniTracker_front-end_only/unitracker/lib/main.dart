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
import 'package:unitracker/services/supabase_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fsdopmaaeqkxmirbvheu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzZG9wbWFhZXFreG1pcmJ2aGV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxNTE4NTMsImV4cCI6MjA2NDcyNzg1M30.2rAeKQFEDUsLB9X3XqtoBp9b7Twen_cVBU0JLvwI65s',
  );

  final prefs = await SharedPreferences.getInstance();

  OneSignal.initialize("ff8d1b56-045a-470c-bb92-4d0c921d0b56");

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
        // StudentProfileService provider removed - not needed
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
      child: Builder(
        builder: (context) {
          return const MyApp();
        },
      ),
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
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}

Future<void> uploadPlayerIdToSupabase() async {
  String? playerId = OneSignal.User.pushSubscription.id;
  String? userId = Supabase.instance.client.auth.currentUser?.id;
  print('DEBUG: playerId=$playerId, userId=$userId');
  if (playerId != null && userId != null) {
    await Supabase.instance.client.from('user_devices').upsert(
      {'user_id': userId, 'onesignal_id': playerId},
      onConflict: 'user_id',
    );
    print('DEBUG: Uploaded playerId to Supabase');
  } else {
    print('DEBUG: playerId or userId is null');
  }
}
