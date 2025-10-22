import 'package:flutter/material.dart';
import 'package:unitracker/screens/auth/signup_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../home/home_screen.dart';
import '../driver/driver_dashboard_screen.dart';
import '../../widgets/toggle_button.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../post_auth_splash_screen.dart';

class LoginScreen extends StatefulWidget {
  final String initialRole;
  const LoginScreen({super.key, required this.initialRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _driverIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _driverIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // Show post-auth splash screen, then navigate
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostAuthSplashScreen(
            onFinish: () {
              if (_selectedRole == 'student') {
                Navigator.of(context, rootNavigator: true).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              } else {
                Navigator.of(context, rootNavigator: true).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const DriverDashboardScreen(),
                  ),
                );
              }
            },
          ),
        ),
      );
    }
  }

  void _handleForgotPassword() {
    final forgotPasswordFormKey = GlobalKey<FormState>();
    final resetEmailController = TextEditingController();
    final resetDriverIdController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final screenHeight = MediaQuery.of(context).size.height;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.8, // 80% of screen height
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(getProportionateScreenWidth(33)),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          getProportionateScreenWidth(24),
                          getProportionateScreenHeight(24),
                          getProportionateScreenWidth(24),
                          getProportionateScreenHeight(20),
                        ),
                        child: Form(
                          key: forgotPasswordFormKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reset Password',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(16)),
                              Text(
                                _selectedRole == 'student'
                                    ? 'Enter your email address to receive a password reset link.'
                                    : 'Enter your driver ID to receive a password reset link.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(24)),
                              TextFormField(
                                controller: _selectedRole == 'student'
                                    ? resetEmailController
                                    : resetDriverIdController,
                                enabled: !isLoading,
                                decoration: InputDecoration(
                                  hintText: _selectedRole == 'student'
                                      ? 'Enter your email'
                                      : 'Enter your driver ID',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        getProportionateScreenWidth(33)),
                                  ),
                                ),
                                keyboardType: _selectedRole == 'student'
                                    ? TextInputType.emailAddress
                                    : TextInputType.text,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return _selectedRole == 'student'
                                        ? 'Please enter your email'
                                        : 'Please enter your driver ID';
                                  }
                                  if (_selectedRole == 'student') {
                                    if (!value.contains('.edu')) {
                                      return 'Please enter a valid university email';
                                    }
                                    if (!RegExp(
                                            r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(24)),
                              SizedBox(
                                width: double.infinity,
                                height: getProportionateScreenHeight(50),
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (forgotPasswordFormKey
                                              .currentState!
                                              .validate()) {
                                            setState(() {
                                              isLoading = true;
                                            });

                                            try {
                                              final authService =
                                                  context.read<AuthService>();
                                              await authService.resetPassword(
                                                email:
                                                    resetEmailController.text,
                                                driverId:
                                                    resetDriverIdController
                                                        .text,
                                                role: _selectedRole,
                                              );

                                              if (context.mounted) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      _selectedRole == 'student'
                                                          ? 'Password reset link sent to your email'
                                                          : 'Password reset instructions sent',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(e
                                                        .toString()
                                                        .replaceAll(
                                                            'Exception: ', '')),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            } finally {
                                              if (mounted) {
                                                setState(() {
                                                  isLoading = false;
                                                });
                                              }
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A237E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(33),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Reset Password',
                                          style: TextStyle(
                                            fontSize:
                                                getProportionateScreenWidth(16),
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultInputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(33)),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(33)),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(33)),
        borderSide:
            BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(33)),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(33)),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: getProportionateScreenHeight(16),
      ),
      isDense: false,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: getProportionateScreenWidth(15),
        fontWeight: FontWeight.w400,
      ),
    );

    return ResponsiveScreen(
      backgroundColor: AppTheme.secondaryColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(20),
          ),
          child: Column(
            children: [
              SizedBox(height: getProportionateScreenHeight(32)),

              // Logo and app name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: getProportionateScreenWidth(50),
                    height: getProportionateScreenWidth(50),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/bus_logo.png',
                        width: getProportionateScreenWidth(30),
                        height: getProportionateScreenWidth(30),
                        fit: BoxFit.contain,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(10)),
                  Text(
                    'UniTracker1',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: getProportionateScreenWidth(24),
                      color: AppTheme.textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              SizedBox(height: getProportionateScreenHeight(40)),

              // Main card
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: getProportionateScreenWidth(400),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(24),
                  vertical: getProportionateScreenHeight(24),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius:
                      BorderRadius.circular(getProportionateScreenWidth(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: getProportionateScreenWidth(10),
                      offset: Offset(0, getProportionateScreenHeight(4)),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(24),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(8)),
                    Text(
                      'Enter your credentials to access your account',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: getProportionateScreenWidth(14),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: getProportionateScreenHeight(32)),

                    // Role selection
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(33)),
                      ),
                      child: Row(
                        children: [
                          // Student button
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedRole = 'student';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: getProportionateScreenHeight(12)),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'student'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(33)),
                                  boxShadow: _selectedRole == 'student'
                                      ? [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: _selectedRole == 'student'
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey,
                                      size: getProportionateScreenWidth(20),
                                    ),
                                    SizedBox(
                                        width: getProportionateScreenWidth(8)),
                                    Text(
                                      'Student',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: _selectedRole == 'student'
                                                ? Theme.of(context).primaryColor
                                                : AppTheme.secondaryTextColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Driver button
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedRole = 'driver';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: getProportionateScreenHeight(12)),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'driver'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(33)),
                                  boxShadow: _selectedRole == 'driver'
                                      ? [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_bus_outlined,
                                      color: _selectedRole == 'driver'
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey,
                                      size: getProportionateScreenWidth(20),
                                    ),
                                    SizedBox(
                                        width: getProportionateScreenWidth(8)),
                                    Text(
                                      'Driver',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: _selectedRole == 'driver'
                                                ? Theme.of(context).primaryColor
                                                : AppTheme.secondaryTextColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: getProportionateScreenHeight(32)),

                    // Form fields
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedRole == 'student' ? 'Email' : 'Driver ID',
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(14),
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor,
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(8)),
                          TextFormField(
                            controller: _selectedRole == 'student'
                                ? _emailController
                                : _driverIdController,
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(14),
                              color: AppTheme.textColor,
                            ),
                            keyboardType: _selectedRole == 'student'
                                ? TextInputType.emailAddress
                                : TextInputType.text,
                            decoration: InputDecoration(
                              hintText: _selectedRole == 'student'
                                  ? 'Enter your email'
                                  : 'Enter your driver ID',
                              hintStyle: TextStyle(
                                fontSize: getProportionateScreenWidth(14),
                                color: AppTheme.secondaryTextColor,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(20),
                                vertical: getProportionateScreenHeight(16),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(28),
                                ),
                                borderSide:
                                    BorderSide(color: AppTheme.dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(28),
                                ),
                                borderSide:
                                    BorderSide(color: AppTheme.dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(28),
                                ),
                                borderSide:
                                    BorderSide(color: AppTheme.primaryColor),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _selectedRole == 'student'
                                    ? 'Please enter your email'
                                    : 'Please enter your driver ID';
                              }
                              if (_selectedRole == 'student') {
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: getProportionateScreenHeight(16)),

                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(14),
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor,
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(8)),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(14),
                              color: AppTheme.textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(
                                fontSize: getProportionateScreenWidth(14),
                                color: AppTheme.secondaryTextColor,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(20),
                                vertical: getProportionateScreenHeight(16),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(28),
                                ),
                                borderSide:
                                    BorderSide(color: AppTheme.dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(28),
                                ),
                                borderSide:
                                    BorderSide(color: AppTheme.dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(28),
                                ),
                                borderSide:
                                    BorderSide(color: AppTheme.primaryColor),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: getProportionateScreenWidth(20),
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          SizedBox(height: getProportionateScreenHeight(8)),

                          // Remember me and Forgot password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: getProportionateScreenHeight(20),
                                    width: getProportionateScreenWidth(20),
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value!;
                                        });
                                      },
                                      activeColor: AppTheme.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          getProportionateScreenWidth(4),
                                        ),
                                      ),
                                      side: BorderSide(
                                        color: AppTheme.dividerColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      width: getProportionateScreenWidth(6)),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontSize: getProportionateScreenWidth(14),
                                      color: AppTheme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _handleForgotPassword,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(13),
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: getProportionateScreenHeight(24)),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: getProportionateScreenHeight(48),
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    getProportionateScreenWidth(24),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Login as ${_selectedRole.capitalize()}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: getProportionateScreenWidth(15),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(24)),

                          // Don't have an account
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(13),
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => SignupScreen(
                                          initialRole: _selectedRole),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: getProportionateScreenWidth(13),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: getProportionateScreenHeight(12)),

                          // Admin login link
                          // Removed admin login link as AdminLoginScreen is deleted
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
