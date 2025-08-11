import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../utils/responsive_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _waitForAuthProvider();
  }

  Future<void> _waitForAuthProvider() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Wait until AuthProvider finishes loading
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => const LoginScreen(initialRole: 'student')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AuthProvider changes
    final authProvider = Provider.of<AuthProvider>(context);

    // If user is not authenticated and we're not loading, redirect to login
    if (!authProvider.isLoading && !authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => const LoginScreen(initialRole: 'student')),
          );
        }
      });
    }

    // Initialize responsive utils if needed
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(16),
            vertical: getProportionateScreenHeight(32),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(), // Top spacer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: getProportionateScreenWidth(80),
                    height: getProportionateScreenWidth(80),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/bus_logo.png',
                        width: getProportionateScreenWidth(46),
                        height: getProportionateScreenWidth(46),
                        fit: BoxFit.contain,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(16)),
                  Text(
                    'UniTracker',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: getProportionateScreenWidth(36),
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Padding(
                padding:
                    EdgeInsets.only(bottom: getProportionateScreenHeight(24)),
                child: Text(
                  'Know your bus, save your time',
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(16),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
