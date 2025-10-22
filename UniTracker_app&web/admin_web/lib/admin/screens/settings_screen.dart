import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import '../widgets/admin_layout.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _currentTabIndex = 0;
  io.File? _profileImage;
  String? _webImageUrl;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  String? _role;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Controllers for System tab fields
  final _universityNameController = TextEditingController();
  final _systemNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _refreshIntervalController = TextEditingController();
  String? _timezone;
  final _systemFormKey = GlobalKey<FormState>();
  // Map tab state
  final _zoomLevelController = TextEditingController();
  String? _mapProvider;
  bool _showBusStops = true;
  bool _showRoutes = true;
  final _mapRefreshRateController = TextEditingController();
  String? _trackingAccuracy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    int newTabIndex = 0;
    if (args != null && args['tab'] is int) {
      newTabIndex = args['tab'];
    }
    if (_tabController == null || _currentTabIndex != newTabIndex) {
      _tabController?.dispose();
      _tabController =
          TabController(length: 4, vsync: this, initialIndex: newTabIndex);
      _currentTabIndex = newTabIndex;
      setState(() {}); // Force rebuild with new controller
    }
  }

  @override
  void initState() {
    super.initState();
    // TabController will be initialized in didChangeDependencies
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _universityNameController.dispose();
    _systemNameController.dispose();
    _contactEmailController.dispose();
    _supportPhoneController.dispose();
    _refreshIntervalController.dispose();
    _zoomLevelController.dispose();
    _mapRefreshRateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        setState(() {
          _webImageUrl = pickedFile.path;
        });
        print('Web image URL: \\${pickedFile.path}');
      } else {
        final file = io.File(pickedFile.path);
        setState(() {
          _profileImage = file;
        });
        print('Desktop image path: \\${pickedFile.path}');
      }
    } else {
      print('No image picked.');
    }
  }

  void _removeImage() {
    setState(() {
      _profileImage = null;
      _webImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return SizedBox.shrink();
    }
    return Container(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController!,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.black54,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'System'),
              Tab(text: 'Notifications'),
              Tab(text: 'Map'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: [
                _buildProfileTab(context),
                _buildSystemTab(),
                _buildNotificationsTab(),
                _buildMapTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your account information and preferences.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),
            // Profile picture row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppTheme.secondaryColor,
                  backgroundImage: kIsWeb
                      ? (_webImageUrl != null
                          ? NetworkImage(_webImageUrl!)
                              as ImageProvider<Object>?
                          : null)
                      : (_profileImage != null
                          ? FileImage(_profileImage!) as ImageProvider<Object>?
                          : null),
                  child: (kIsWeb
                          ? (_webImageUrl == null)
                          : (_profileImage == null))
                      ? const Text('AD',
                          style: TextStyle(fontSize: 36, color: Colors.black54))
                      : null,
                ),
                const SizedBox(width: 32),
                // Label and buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile Picture',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 18)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                          ),
                          child: const Text('Upload New'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _removeImage,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                          ),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),
            // All fields in a single column
            _buildLabeledField('Full Name', _nameController),
            const SizedBox(height: 20),
            _buildLabeledField('Email', _emailController,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildLabeledField('Phone', _phoneController,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            _buildLabeledField('Department', _departmentController),
            const SizedBox(height: 20),
            _buildLabeledDropdown('Role', _role, [
              'Administrator',
              'Manager',
              'Scheduler',
              'Dispatcher',
              'Viewer'
            ], (value) {
              if (value != null) setState(() => _role = value);
            }),
            const SizedBox(height: 32),
            const Text('Change Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _buildLabeledPasswordField('New Password', _passwordController),
            const SizedBox(height: 12),
            _buildLabeledPasswordField(
                'Confirm New Password', _confirmPasswordController),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Save logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile updated successfully')),
                    );
                  }
                },
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      String? hintText,
      Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: hintText ??
                (label == 'Full Name'
                    ? 'Enter your full name'
                    : label == 'Email'
                        ? 'Enter your email'
                        : label == 'Phone'
                            ? 'Enter your phone number'
                            : label == 'Department'
                                ? 'Enter your department'
                                : ''),
            hintStyle: TextStyle(color: AppTheme.secondaryTextColor),
            suffixIcon: suffix,
          ),
          keyboardType: keyboardType,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (label == 'Contact Email' || label == 'Email') {
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLabeledDropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: AppTheme.cardColor,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: 'Choose your role',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLabeledPasswordField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: label == 'New Password'
                ? 'Enter new password'
                : label == 'Confirm New Password'
                    ? 'Confirm new password'
                    : '',
            hintStyle: TextStyle(color: AppTheme.secondaryTextColor),
          ),
          obscureText: true,
          validator: (value) {
            if (label == 'Confirm New Password' &&
                value != _passwordController.text) {
              return 'Passwords do not match';
            }
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (label == 'New Password' && value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Form(
          key: _systemFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Settings',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure system-wide settings for the bus tracking application.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 32),
              _buildLabeledField('University Name', _universityNameController,
                  hintText: 'Enter university name'),
              const SizedBox(height: 20),
              _buildLabeledField('System Name', _systemNameController,
                  hintText: 'Enter system name'),
              const SizedBox(height: 20),
              _buildLabeledField('Contact Email', _contactEmailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'Enter contact email'),
              const SizedBox(height: 20),
              _buildLabeledField('Support Phone', _supportPhoneController,
                  keyboardType: TextInputType.phone,
                  hintText: 'Enter support phone'),
              const SizedBox(height: 20),
              _buildLabeledField(
                  'Data Refresh Interval (seconds)', _refreshIntervalController,
                  keyboardType: TextInputType.number, hintText: 'e.g. 30'),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Timezone',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _timezone,
                    dropdownColor: AppTheme.cardColor,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      hintText: 'Select timezone',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    items: [
                      'Eastern Time (ET)',
                      'Central Time (CT)',
                      'Mountain Time (MT)',
                      'Pacific Time (PT)',
                      'Alaska Time (AKT)',
                      'Hawaii Time (HT)',
                    ]
                        .map((item) =>
                            DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) => setState(() => _timezone = value),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Database Backup Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Automatic Backups',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('System will backup data every 24 hours',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 15)),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Backup started successfully')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryColor),
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 10),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Run Backup Now'),
                      ),
                    ),
                  ],
                ),
              ),
              // System Maintenance Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Schedule Maintenance',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('Put the system in maintenance mode',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 15)),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('System maintenance scheduled')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryColor),
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 10),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Schedule'),
                      ),
                    ),
                  ],
                ),
              ),
              // Save Changes Button
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_systemFormKey.currentState!.validate()) {
                      // Save logic for system settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('System settings updated successfully')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Save Changes',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Configure how and when you receive notifications.',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 32),
            _buildNotificationToggle(
              'Email Alerts',
              'Receive important alerts via email',
              _emailAlerts,
              (val) => setState(() => _emailAlerts = val),
            ),
            const SizedBox(height: 16),
            _buildNotificationToggle(
              'Push Notifications',
              'Receive alerts on your device',
              _pushNotifications,
              (val) => setState(() => _pushNotifications = val),
            ),
            const SizedBox(height: 16),
            _buildNotificationToggle(
              'Delay Notifications',
              'Get notified when buses are delayed',
              _delayNotifications,
              (val) => setState(() => _delayNotifications = val),
            ),
            const SizedBox(height: 16),
            _buildNotificationToggle(
              'Maintenance Alerts',
              'Get notified about bus maintenance',
              _maintenanceAlerts,
              (val) => setState(() => _maintenanceAlerts = val),
            ),
            const SizedBox(height: 16),
            _buildNotificationToggle(
              'Driver Updates',
              'Get notified about driver status changes',
              _driverUpdates,
              (val) => setState(() => _driverUpdates = val),
            ),
            const SizedBox(height: 16),
            _buildNotificationToggle(
              'Weekly Reports',
              'Receive weekly summary reports',
              _weeklyReports,
              (val) => setState(() => _weeklyReports = val),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Important',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 2),
                        Text(
                            'Make sure your email address is correct in your profile settings to receive email notifications.',
                            style:
                                TextStyle(color: Colors.black87, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Save logic for notification settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Notification settings updated successfully')),
                  );
                },
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Notification toggles state
  bool _emailAlerts = true;
  bool _pushNotifications = true;
  bool _delayNotifications = true;
  bool _maintenanceAlerts = true;
  bool _driverUpdates = false;
  bool _weeklyReports = true;

  Widget _buildNotificationToggle(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 17)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 15)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildMapTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map Settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Configure map display and tracking settings.',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 32),
            // Google Map widget
            SizedBox(
              height: 300,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(37.7749,
                      -122.4194), // Replace with your campus coordinates
                  zoom: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Default Zoom Level with stepper inside the field
            _buildLabeledField(
              'Default Zoom Level',
              _zoomLevelController,
              keyboardType: TextInputType.number,
              hintText: 'Enter zoom level (1-20)',
              suffix: SizedBox(
                width: 36,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      constraints: BoxConstraints(minHeight: 18, minWidth: 36),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_drop_up, size: 18),
                      onPressed: () {
                        int value =
                            int.tryParse(_zoomLevelController.text) ?? 1;
                        if (value < 20) {
                          value++;
                          setState(() {
                            _zoomLevelController.text = value.toString();
                          });
                        }
                      },
                    ),
                    IconButton(
                      constraints: BoxConstraints(minHeight: 18, minWidth: 36),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      onPressed: () {
                        int value =
                            int.tryParse(_zoomLevelController.text) ?? 1;
                        if (value > 1) {
                          value--;
                          setState(() {
                            _zoomLevelController.text = value.toString();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Values between 1-20, higher numbers zoom in closer',
                style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Map Provider',
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _mapProvider,
                  dropdownColor: AppTheme.cardColor,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    hintText: 'Select map provider',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  items: [
                    'Google Maps',
                    'Mapbox',
                    'OpenStreetMap',
                  ]
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setState(() => _mapProvider = value),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMapToggle(
                'Show Bus Stops',
                'Display all bus stops on the map',
                _showBusStops,
                (val) => setState(() => _showBusStops = val)),
            const SizedBox(height: 20),
            _buildMapToggle('Show Routes', 'Display route paths on the map',
                _showRoutes, (val) => setState(() => _showRoutes = val)),
            const SizedBox(height: 20),
            _buildLabeledField(
                'Map Refresh Rate (seconds)', _mapRefreshRateController,
                keyboardType: TextInputType.number, hintText: 'e.g. 10'),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tracking Accuracy',
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _trackingAccuracy,
                  dropdownColor: AppTheme.cardColor,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    hintText: 'Select tracking accuracy',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  items: [
                    'High (Most Accurate)',
                    'Medium',
                    'Low (Battery Saver)',
                  ]
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _trackingAccuracy = value),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Map Style Preview',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Color(0xF5F8FAFF),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text('Map preview would appear here',
                  style: TextStyle(color: Colors.black38, fontSize: 18)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Save logic for map settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Map settings updated successfully')),
                  );
                },
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapToggle(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 17)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 15)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }
}
