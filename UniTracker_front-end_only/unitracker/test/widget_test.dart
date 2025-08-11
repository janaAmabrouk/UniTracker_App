// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unitracker/main.dart';
import 'package:unitracker/providers/auth_provider.dart';
import 'package:unitracker/services/notification_service.dart';
import 'package:unitracker/services/notification_settings_service.dart';
import 'package:unitracker/services/reservation_service.dart';

void main() {
  group('App Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      // Initialize SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
        'App should initialize with login screen when not authenticated',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(
              create: (_) => NotificationService(),
              lazy: false,
            ),
            ChangeNotifierProvider(
              create: (_) => NotificationSettingsService(prefs),
            ),
            ChangeNotifierProxyProvider2<NotificationService,
                NotificationSettingsService, ReservationService>(
              create: (context) => ReservationService.getInstance(
                context.read<NotificationService>(),
                context.read<NotificationSettingsService>(),
              ),
              update: (context, notificationService, notificationSettings,
                      previous) =>
                  ReservationService.getInstance(
                      notificationService, notificationSettings),
            ),
          ],
          child: const MyApp(),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Verify that login screen is shown
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(TextFormField),
          findsNWidgets(2)); // Email and password fields
      expect(find.byType(ElevatedButton), findsOneWidget); // Login button
    });

    testWidgets('Login form should validate empty fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(
              create: (_) => NotificationService(),
              lazy: false,
            ),
            ChangeNotifierProvider(
              create: (_) => NotificationSettingsService(prefs),
            ),
            ChangeNotifierProxyProvider2<NotificationService,
                NotificationSettingsService, ReservationService>(
              create: (context) => ReservationService.getInstance(
                context.read<NotificationService>(),
                context.read<NotificationSettingsService>(),
              ),
              update: (context, notificationService, notificationSettings,
                      previous) =>
                  ReservationService.getInstance(
                      notificationService, notificationSettings),
            ),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the login button without entering any credentials
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pump();

      // Verify that validation error messages are shown
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Navigation bar should show correct items for student role',
        (WidgetTester tester) async {
      // Set up mock authenticated state for student
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', 'student');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(
              create: (_) => NotificationService(),
              lazy: false,
            ),
            ChangeNotifierProvider(
              create: (_) => NotificationSettingsService(prefs),
            ),
            ChangeNotifierProxyProvider2<NotificationService,
                NotificationSettingsService, ReservationService>(
              create: (context) => ReservationService.getInstance(
                context.read<NotificationService>(),
                context.read<NotificationSettingsService>(),
              ),
              update: (context, notificationService, notificationSettings,
                      previous) =>
                  ReservationService.getInstance(
                      notificationService, notificationSettings),
            ),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify bottom navigation items for student
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
