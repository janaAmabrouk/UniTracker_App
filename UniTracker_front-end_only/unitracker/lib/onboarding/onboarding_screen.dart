import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../utils/responsive_utils.dart';
import '../widgets/toggle_button.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreen();
}

class _OnboardingScreen extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedRole = 'student';
  String? _selectedUniversity;

  final List<String> _universities = [
    'Egypt University of Informatics (EUI)',
    'The British University in Egypt (BUE)',
    'Future University in Egypt (FUE)',
    'Misr International University (MIU)',
    'Coventry University'
  ];

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
    {
      'title': 'Select University',
      'description':
          'Select your university for personalized bus routes and schedules.',
      'icon': Icons.school,
    },
    {
      'title': 'What\'s your role?',
      'description': 'Tell us how you\'ll be using UniTracker',
      'icon': Icons.rocket_launch,
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
          builder: (_) => SignupScreen(
            initialRole: _selectedRole,
            selectedUniversity: _selectedUniversity ?? '',
          ),
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

    // Use the same defaultInputDecoration as in signup_screen.dart
    final defaultInputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(33),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(33),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(33),
        borderSide:
            BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(33),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(33),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: getProportionateScreenHeight(12),
      ),
      isDense: true,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: getProportionateScreenWidth(14),
        fontWeight: FontWeight.w400,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
              // Container area for slide content
              Container(
                height: getProportionateScreenHeight(400),
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
                        children: [
                          const Spacer(flex: 2),
                          // Large circular icon with consistent size
                          Container(
                            width: getProportionateScreenWidth(100),
                            height: getProportionateScreenHeight(100),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                _slides[index]['icon'],
                                size: getProportionateScreenWidth(48),
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(24)),

                          // Title text in a container with a fixed height
                          Container(
                            height: getProportionateScreenHeight(50),
                            alignment: Alignment.center,
                            child: Text(
                              _slides[index]['title'],
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(18),
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                height: 1.2,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(12)),

                          // Description text in a container with a fixed height
                          Container(
                            height: getProportionateScreenHeight(70),
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(16),
                              ),
                              child: Text(
                                _slides[index]['description'],
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(14),
                                  color: Colors.grey[600],
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          const Spacer(flex: 1),

                          // Indicator dots with consistent styling
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _slides.length,
                              (i) => Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: getProportionateScreenWidth(3)),
                                width: getProportionateScreenWidth(6),
                                height: getProportionateScreenHeight(6),
                                decoration: BoxDecoration(
                                  color: i == _currentPage
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(3)),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(flex: 2),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom navigation buttons
              Transform.translate(
                offset: Offset(0,
                    -getProportionateScreenHeight(40)), // Move buttons upward
                child: Padding(
                  padding: EdgeInsets.all(getProportionateScreenWidth(24)),
                  child: Column(
                    children: [
                      // Add Dropdown for slide 5 here
                      if (_currentPage == 4)
                        Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: PopupMenuThemeData(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            decoration: defaultInputDecoration.copyWith(
                              hintText: 'Select your university',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(20),
                                vertical: getProportionateScreenHeight(12),
                              ),
                              isDense: true,
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: getProportionateScreenWidth(14),
                                  ),
                            ),
                            menuMaxHeight: getProportionateScreenHeight(300),
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down,
                                color: Colors.grey.shade700),
                            dropdownColor: Colors.white,
                            alignment: AlignmentDirectional.centerStart,
                            style: Theme.of(context).textTheme.bodyMedium,
                            value: _selectedUniversity,
                            items: _universities.map((university) {
                              final isEUI = university.contains(
                                  'Egypt University of Informatics (EUI)');
                              return DropdownMenuItem(
                                value: university,
                                enabled: isEUI, // Only EUI is enabled for now
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                      horizontal:
                                          getProportionateScreenWidth(4)),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          university,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize:
                                                    getProportionateScreenWidth(
                                                        14),
                                                color: isEUI
                                                    ? Colors.black87
                                                    : Colors.grey,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      if (!isEUI)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal:
                                                getProportionateScreenWidth(6),
                                            vertical:
                                                getProportionateScreenHeight(2),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Coming Soon',
                                            style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      9),
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null &&
                                  !value.contains(
                                      'Egypt University of Informatics (EUI)')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '$value registration is coming soon! Currently only EUI students can register.'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                _selectedUniversity = value;
                              });
                            },
                          ),
                        ),

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
                      // Add space after dropdown OR toggle
                      if (_currentPage == 4 ||
                          _currentPage == _slides.length - 1)
                        SizedBox(height: getProportionateScreenHeight(16)),

                      // Next or Get Started button
                      SizedBox(
                        width: double.infinity,
                        height: getProportionateScreenHeight(50),
                        child: ElevatedButton(
                          onPressed:
                              (_currentPage == 4 && _selectedUniversity == null)
                                  ? null
                                  : _nextPage,
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
      ),
    );
  }
}
