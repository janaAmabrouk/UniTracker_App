import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../utils/responsive_utils.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../driver/driver_dashboard_screen.dart';
import '../../providers/auth_provider.dart';
import '../../models/driver.dart';
import '../../providers/driver_provider.dart';
import '../../models/driver_stats.dart';
import '../post_auth_splash_screen.dart';
import '../../services/supabase_service.dart';

class SignupScreen extends StatefulWidget {
  final String initialRole;
  final String? selectedUniversity;

  const SignupScreen({
    super.key,
    required this.initialRole,
    this.selectedUniversity,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _driverIdController = TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _licenseExpirationDateController =
      TextEditingController();
  final _imagePicker = ImagePicker();

  late String _selectedRole;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  String? _selectedDepartment;
  DateTime? _licenseExpirationDate;
  String? _licenseImagePath;
  Uint8List? _licenseImageBytes; // For web support
  String? _selectedUniversity;

  final Map<String, List<String>> _universityDepartments = {
    'Egypt University of Informatics (EUI)': [
      'Computer Science',
      'Business Informatics',
      'Digital Arts',
      'Engineering',
    ],
    'The British University in Egypt (BUE)': [
      'Art & Design',
      'Arts & Humanities',
      'Business Administration',
      'Mass Communication',
      'Dentistry',
      'Energy & Environmental Engineering',
      'Engineering',
      'Informatics & Computer Science',
      'Law',
      'Nursing',
      'Pharmacy',
      'Physiotherapy'
    ],
    'Future University in Egypt (FUE)': [
      'Pharmacy',
      'Oral & Dental Medicine',
      'Engineering & Technology',
      'Economics & Political Science',
      'Computers & Information Technology',
      'Commerce & Business Administration'
    ],
    'Misr International University (MIU)': [
      'Al-Alsun',
      'Business Administration',
      'Computer Science',
      'Engineering Sciences & Arts',
      'Pharmacy',
      'Oral & Dental Medicine',
      'Mass Communication'
    ],
    'Coventry University': [
      'Business Administration',
      'Accounting & Finance',
      'Psychology',
      'Software Engineering',
      'Computer Science',
      'Digital Media',
      'graphic Design',
      'Interior Architecture & Design',
      'Product Design'
    ]
  };

  List<String> get _departments {
    final university = widget.selectedUniversity ?? _selectedUniversity;
    if (university == null) return [];
    return _universityDepartments[university] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    if (widget.selectedUniversity != null) {
      _universityController.text = widget.selectedUniversity!;
      _selectedUniversity = widget.selectedUniversity;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize SizeConfig here since MediaQuery.of(context) is now available
    SizeConfig.init(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _driverIdController.dispose();
    _universityController.dispose();
    _licenseNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    _licenseExpirationDateController.dispose();
    super.dispose();
  }

  void _signup() async {
    debugPrint('Signup button pressed');
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == 'driver') {
        debugPrint('Driver signup flow');
        if (_licenseImagePath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload your license image')),
          );
          return;
        }
        if (_licenseExpirationDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please select your license expiration date')),
          );
          return;
        }
        if (_licenseNumberController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your license number')),
          );
          return;
        }
        // Upload the license image before signup
        final supabaseService = SupabaseService.instance;
        String? licenseImageUrl;
        try {
          if (kIsWeb && _licenseImageBytes != null) {
            licenseImageUrl = await supabaseService.uploadDriverLicenseImage(
              driverId: _driverIdController.text,
              filePath: _licenseImagePath!,
              fileBytes: _licenseImageBytes,
            );
          } else {
            licenseImageUrl = await supabaseService.uploadDriverLicenseImage(
              driverId: _driverIdController.text,
              filePath: _licenseImagePath!,
            );
          }
        } catch (e) {
          debugPrint('Image upload error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload license image: $e')),
          );
          return;
        }
        if (licenseImageUrl == null) {
          debugPrint('License image URL is null');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload license image')),
          );
          return;
        }
        debugPrint('Calling authProvider.signup with university: ' +
            _universityController.text +
            ', phone: ' +
            _phoneNumberController.text);
        final authProvider = context.read<AuthProvider>();
        final bool success = await authProvider.signup(
          _nameController.text,
          _selectedRole == 'student' ? _emailController.text : '',
          _passwordController.text,
          _selectedRole,
          studentId: _studentIdController.text,
          university: _selectedUniversity,
          department: _selectedDepartment,
          phoneNumber: _phoneNumberController.text,
          driverId: _driverIdController.text,
          licenseNumber: _licenseNumberController.text,
          licenseExpiration: _licenseExpirationDate?.toIso8601String(),
          licenseImageUrl: licenseImageUrl,
        );
        debugPrint('Signup result: $success');
        if (success) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PostAuthSplashScreen(
                  onFinish: () {
                    final role =
                        Provider.of<AuthProvider>(context, listen: false)
                            .currentUser
                            ?.role;
                    if (role == 'driver') {
                      Navigator.of(context, rootNavigator: true)
                          .pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const DriverDashboardScreen(),
                        ),
                      );
                    } else {
                      Navigator.of(context, rootNavigator: true)
                          .pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          }
        } else {
          debugPrint('Signup failed, showing dialog');
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Signup Failed'),
                  content: Text(authProvider.error ??
                      'An unknown error occurred. Please check your details and try again.'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }
        }
        return;
      }

      final authProvider = context.read<AuthProvider>();
      debugPrint('Calling authProvider.signup with university: ' +
          _universityController.text +
          ', phone: ' +
          _phoneNumberController.text);
      final bool success = await authProvider.signup(
        _nameController.text,
        _selectedRole == 'student' ? _emailController.text : '',
        _passwordController.text,
        _selectedRole,
        studentId: _studentIdController.text,
        university: _selectedUniversity,
        department: _selectedDepartment,
        phoneNumber: _phoneNumberController.text,
        driverId: _driverIdController.text,
        licenseNumber: _licenseNumberController.text,
        licenseExpiration: _licenseExpirationDate?.toIso8601String(),
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PostAuthSplashScreen(
                onFinish: () {
                  final role = Provider.of<AuthProvider>(context, listen: false)
                      .currentUser
                      ?.role;
                  if (role == 'driver') {
                    Navigator.of(context, rootNavigator: true).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const DriverDashboardScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context, rootNavigator: true).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Signup Failed'),
                content: Text(authProvider.error ??
                    'An unknown error occurred. Please check your details and try again.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1920,
                      maxHeight: 1080,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      if (kIsWeb) {
                        // For web, read the image as bytes
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _licenseImagePath = image.name;
                          _licenseImageBytes = bytes;
                        });
                      } else {
                        // For mobile, use the path
                        setState(() {
                          _licenseImagePath = image.path;
                          _licenseImageBytes = null;
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1920,
                      maxHeight: 1080,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      if (kIsWeb) {
                        // For web, read the image as bytes
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _licenseImagePath = image.name;
                          _licenseImageBytes = bytes;
                        });
                      } else {
                        // For mobile, use the path
                        setState(() {
                          _licenseImagePath = image.path;
                          _licenseImageBytes = null;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectLicenseExpirationDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpirationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _licenseExpirationDate) {
      setState(() {
        _licenseExpirationDate = picked;
        _licenseExpirationDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Check if AuthService is available in the widget tree
    assert(Provider.of<AuthProvider>(context, listen: false) != null,
        'AuthService provider is missing above SignupScreen!');

    // Example of correct navigation to SignupScreen:
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (_) => SignupScreen(initialRole: 'student'),
    //   ),
    // );

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
        vertical: getProportionateScreenHeight(16),
      ),
      isDense: true,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: getProportionateScreenWidth(14),
        fontWeight: FontWeight.w400,
      ),
    );

    return ResponsiveScreen(
      backgroundColor:
          Theme.of(context).colorScheme.secondary, // Light blue background
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
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
              vertical: getProportionateScreenHeight(16),
            ),
            isDense: false,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                  fontSize: getProportionateScreenWidth(14),
                ),
          ),
        ),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
          child: Column(
            children: [
              SizedBox(height: getProportionateScreenHeight(60)),

              // Logo and app name (bus_logo + UniTracker)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: getProportionateScreenWidth(50),
                    height: getProportionateScreenWidth(50),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/bus_logo.png',
                        width: getProportionateScreenWidth(30),
                        height: getProportionateScreenWidth(30),
                        fit: BoxFit.contain,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(10)),
                  Text(
                    'UniTracker',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: getProportionateScreenWidth(24),
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              SizedBox(height: getProportionateScreenHeight(32)),

              // Main card
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                ),
                padding: EdgeInsets.all(getProportionateScreenWidth(24)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(getProportionateScreenWidth(33)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Text(
                      'Let\'s Create Your Account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.black87,
                            fontSize: getProportionateScreenWidth(20),
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: getProportionateScreenHeight(8)),
                    Text(
                      'Enter your credentials to access\nyour account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: getProportionateScreenHeight(24)),

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
                    SizedBox(height: getProportionateScreenHeight(24)),

                    // Signup form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full Name
                          Text(
                            'Full Name',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.textTheme.bodyLarge!.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(8)),
                          TextFormField(
                            controller: _nameController,
                            decoration: defaultInputDecoration.copyWith(
                              hintText: 'Enter your full name',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: getProportionateScreenWidth(14),
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: getProportionateScreenHeight(20)),

                          // Email (for students only)
                          if (_selectedRole == 'student') ...[
                            Text(
                              'Email',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.textTheme.bodyLarge!.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            TextFormField(
                              controller: _emailController,
                              decoration: defaultInputDecoration.copyWith(
                                hintText: 'Your.email@university.edu',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: getProportionateScreenWidth(14),
                                  ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('.edu')) {
                                  return 'Please enter a valid university email';
                                }
                                if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(20)),
                          ],

                          // Phone Number (for students only)
                          if (_selectedRole == 'student') ...[
                            Text(
                              'Phone Number',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.textTheme.bodyLarge!.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            TextFormField(
                              controller: _phoneNumberController,
                              decoration: defaultInputDecoration.copyWith(
                                hintText: 'Enter your phone number',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: getProportionateScreenWidth(14),
                                  ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                // Basic validation for a phone number (e.g., must be digits, maybe length check)
                                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(20)),
                          ],

                          // Student ID (only for students)
                          if (_selectedRole == 'student') ...[
                            Text(
                              'Student ID',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.textTheme.bodyLarge!.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            TextFormField(
                              controller: _studentIdController,
                              decoration: defaultInputDecoration.copyWith(
                                hintText: 'S12345678',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: getProportionateScreenWidth(14),
                                  ),
                              validator: (value) {
                                if (_selectedRole == 'student' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter your student ID';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(20)),
                          ],

                          // University (for students)
                          if (_selectedRole == 'student') ...[
                            Text(
                              'University',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.textTheme.bodyLarge!.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            if (widget.selectedUniversity != null)
                              TextFormField(
                                controller: _universityController,
                                readOnly: true,
                                decoration: defaultInputDecoration.copyWith(
                                  prefixIcon: Icon(
                                    Icons.school_outlined,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: getProportionateScreenWidth(14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              )
                            else
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
                                      horizontal:
                                          getProportionateScreenWidth(20),
                                      vertical:
                                          getProportionateScreenHeight(12),
                                    ),
                                    isDense: true,
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize:
                                              getProportionateScreenWidth(14),
                                        ),
                                  ),
                                  menuMaxHeight:
                                      getProportionateScreenHeight(300),
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down,
                                      color: Colors.grey.shade700),
                                  dropdownColor: Colors.white,
                                  alignment: AlignmentDirectional.centerStart,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  value: _selectedUniversity,
                                  items: _universityDepartments.keys
                                      .map((university) {
                                    final isEUI = university.contains(
                                        'Egypt University of Informatics (EUI)');
                                    return DropdownMenuItem(
                                      value: university,
                                      enabled:
                                          isEUI, // Only EUI is enabled for now
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
                                                      getProportionateScreenWidth(
                                                          6),
                                                  vertical:
                                                      getProportionateScreenHeight(
                                                          2),
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
                                                    color:
                                                        Colors.orange.shade700,
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                      _selectedDepartment =
                                          null; // Reset department on new university selection
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Please select a university'
                                      : null,
                                ),
                              ),
                            SizedBox(height: getProportionateScreenHeight(20)),
                          ],

                          // Department (for students)
                          if (_selectedRole == 'student') ...[
                            Text(
                              'Department',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.textTheme.bodyLarge!.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            DropdownButtonFormField<String>(
                              decoration: defaultInputDecoration.copyWith(
                                hintText: 'Select your department',
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
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down,
                                  color: Colors.grey.shade700),
                              dropdownColor: Colors.white,
                              alignment: AlignmentDirectional.centerStart,
                              style: Theme.of(context).textTheme.bodyMedium,
                              value: _selectedDepartment,
                              items: _departments.map((department) {
                                return DropdownMenuItem(
                                  value: department,
                                  child: Text(
                                    department,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize:
                                              getProportionateScreenWidth(14),
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                });
                              },
                              menuMaxHeight: getProportionateScreenHeight(300),
                              validator: (value) {
                                if (_selectedRole == 'student' &&
                                    value == null) {
                                  return 'Please select your department';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(20)),
                          ],

                          // Driver ID (for drivers only)
                          if (_selectedRole == 'driver') ...[
                            Text(
                              'Driver ID',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.textTheme.bodyLarge!.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            TextFormField(
                              controller: _driverIdController,
                              decoration: defaultInputDecoration.copyWith(
                                hintText: 'Enter your driver ID',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: getProportionateScreenWidth(14),
                                  ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your driver ID';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(20)),

                            // Phone Number (for drivers only)
                            Text(
                              'Phone Number',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.textTheme.bodyLarge!.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            TextFormField(
                              controller: _phoneNumberController,
                              keyboardType: TextInputType.phone,
                              decoration: defaultInputDecoration.copyWith(
                                hintText: 'Enter your phone number',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: getProportionateScreenWidth(14),
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(20)),

                            // License Number
                            Text(
                              'License Number',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.textTheme.bodyLarge!.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            TextFormField(
                              controller: _licenseNumberController,
                              decoration: defaultInputDecoration.copyWith(
                                hintText: 'Enter your license number',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: getProportionateScreenWidth(14),
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your license number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(20)),

                            // License Expiration Date
                            Text(
                              'License Expiration Date',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.textTheme.bodyLarge!.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            TextFormField(
                              controller: _licenseExpirationDateController,
                              readOnly: true,
                              onTap: () {
                                _selectLicenseExpirationDate(context);
                              },
                              decoration: defaultInputDecoration.copyWith(
                                hintText: 'Select expiration date',
                                suffixIcon: Padding(
                                  padding: EdgeInsets.only(
                                      right: getProportionateScreenWidth(12)),
                                  child: Icon(
                                    Icons.calendar_today_outlined,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (_selectedRole == 'driver' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please select an expiration date';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(16)),
                          ],

                          // Upload License Image
                          if (_selectedRole == 'driver') ...[
                            _buildLicenseImageUpload(),
                            SizedBox(height: getProportionateScreenHeight(20)),
                          ],

                          // Password
                          Text(
                            'Create Password',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.textTheme.bodyLarge!.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(8)),
                          TextFormField(
                            controller: _passwordController,
                            decoration: defaultInputDecoration.copyWith(
                              hintText: 'Enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: getProportionateScreenWidth(14),
                                ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: getProportionateScreenHeight(20)),

                          // Confirm Password
                          Text(
                            'Confirm Password',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.textTheme.bodyLarge!.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(8)),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: defaultInputDecoration.copyWith(
                              hintText: 'Confirm your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: getProportionateScreenWidth(14),
                                ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: getProportionateScreenHeight(20)),

                          // Remember me
                          Row(
                            children: [
                              SizedBox(
                                height: getProportionateScreenHeight(24),
                                width: getProportionateScreenWidth(24),
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value!;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        getProportionateScreenWidth(4)),
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              SizedBox(width: getProportionateScreenWidth(8)),
                              Text(
                                'Remember me',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.secondaryTextColor,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: getProportionateScreenHeight(24)),

                          // Signup button
                          SizedBox(
                            width: double.infinity,
                            height: getProportionateScreenHeight(50),
                            child: ElevatedButton(
                              onPressed: _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(33)),
                                ),
                              ),
                              child: Text(
                                'Sign Up as ${_selectedRole.capitalize()}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: getProportionateScreenWidth(14),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(24)),

                          // Already have an account
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: AppTheme.secondaryTextColor,
                                    ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => LoginScreen(
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
                                  'Login',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload License Image',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        FormField<String>(
          validator: (_) {
            if (_selectedRole == 'driver' && _licenseImagePath == null) {
              return 'Please upload your license image';
            }
            return null;
          },
          builder: (FormFieldState<String> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: getProportionateScreenHeight(120),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            state.hasError ? Colors.red : Colors.grey.shade300,
                      ),
                    ),
                    child: _licenseImagePath != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb && _licenseImageBytes != null
                                    ? Image.memory(
                                        _licenseImageBytes!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : !kIsWeb
                                        ? Image.file(
                                            File(_licenseImagePath!),
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.image,
                                              size: 50,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _licenseImagePath = null;
                                      _licenseImageBytes = null;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: getProportionateScreenWidth(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_outlined,
                                size: getProportionateScreenWidth(40),
                                color:
                                    state.hasError ? Colors.red : Colors.grey,
                              ),
                              SizedBox(height: getProportionateScreenHeight(8)),
                              Text(
                                'Tap to upload license image',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: state.hasError
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                      fontSize: getProportionateScreenWidth(12),
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: EdgeInsets.only(
                      top: getProportionateScreenHeight(8),
                      left: getProportionateScreenWidth(12),
                    ),
                    child: Text(
                      state.errorText!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                            fontSize: getProportionateScreenWidth(12),
                          ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
