import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../utils/responsive_utils.dart';
import '../widgets/toggle_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreen();
}

class _OnboardingScreen extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedRole = 'student';

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Track Buses in Real-Time',
      'description':
          'See exactly where your university buses are and when they\'ll arrive at your stop.',
      'icon': Icons.directions_bus,
    },
    {
      'title': 'View Bus Schedules',
      'description':
          'Check all bus routes and schedules to plan your journey ahead of time.',
      'icon': Icons.calendar_today_sharp,
    },
    {
      'title': 'Reserve Your Seat',
      'description':
          'Book your seat in advance to ensure a comfortable journey.',
      'icon': Icons.event_seat,
    },
    {
      'title': 'Find Nearby Stops',
      'description': 'Locate the closest bus stops to your current location.',
      'icon': Icons.near_me_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to signup screen when "Get Started" is pressed
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SignupScreen(initialRole: _selectedRole),
        ),
      );
    }
  }

  void _skipToLogin() {
    // Navigate to login screen when "Login" is pressed
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(initialRole: _selectedRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure status bar is visible and styled
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // or your preferred color
        statusBarIconBrightness:
            Brightness.dark, // or Brightness.light for light backgrounds
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
                height: getProportionateScreenHeight(
                    84)), // Top space (moved logo lower)

            // App branding - bus icon and UniTracker name
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/bus_logo.png',
                    width: getProportionateScreenWidth(42),
                    height: getProportionateScreenWidth(42),
                    fit: BoxFit.contain,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: getProportionateScreenWidth(12)),
                  Text(
                    'UniTracker',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: getProportionateScreenWidth(30),
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Expanded area for slide content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(24),
                      vertical: getProportionateScreenHeight(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large circular bus icon
                        Container(
                          width: getProportionateScreenWidth(
                              100), // Reduced from 120
                          height: getProportionateScreenHeight(
                              100), // Reduced from 120
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _slides[index]['icon'],
                              size: getProportionateScreenWidth(
                                  48), // Reduced from 64
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: getProportionateScreenHeight(
                                32)), // Reduced from 40
                        // Title text
                        Text(
                          _slides[index]['title'],
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(
                                18), // Reduced from 20
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                            height: getProportionateScreenHeight(
                                12)), // Reduced from 16
                        // Description text
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(16),
                          ),
                          child: Text(
                            _slides[index]['description'],
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(
                                  14), // Reduced from 16
                              color: Colors.grey[600],
                              height: 1.4, // Reduced from 1.5
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                            height: getProportionateScreenHeight(
                                20)), // Reduced from 23
                        // Indicator dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _slides.length,
                            (i) => Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                      3)), // Reduced from 4
                              width: getProportionateScreenWidth(
                                  6), // Reduced from 8
                              height: getProportionateScreenHeight(
                                  6), // Reduced from 8
                              decoration: BoxDecoration(
                                color: i == _currentPage
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(
                                    getProportionateScreenWidth(
                                        3)), // Reduced from 4
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom navigation buttons
            Transform.translate(
              offset: Offset(
                  0, -getProportionateScreenHeight(40)), // Move buttons upward
              child: Padding(
                padding: EdgeInsets.all(getProportionateScreenWidth(24)),
                child: Column(
                  children: [
                    // Role selection buttons (only on last slide)
                    if (_currentPage == _slides.length - 1)
                      ToggleButtonPair(
                        firstText: 'Student',
                        firstIcon: Icons.person_outline,
                        secondText: 'Driver',
                        secondIcon: Icons.directions_bus_outlined,
                        isFirstSelected: _selectedRole == 'student',
                        onToggle: (isFirst) {
                          setState(() {
                            _selectedRole = isFirst ? 'student' : 'driver';
                          });
                        },
                      ),

                    if (_currentPage == _slides.length - 1)
                      SizedBox(height: getProportionateScreenHeight(16)),

                    // Next or Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: getProportionateScreenHeight(50),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(30)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _slides.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: getProportionateScreenWidth(8)),
                            Icon(Icons.arrow_forward,
                                color: Colors.white,
                                size: getProportionateScreenWidth(20)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(16)),
                    // Skip text button or Login link
                    TextButton(
                      onPressed: _skipToLogin,
                      child: _currentPage == _slides.length - 1
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(14),
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  'Login',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            )
                          : Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(14),
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
