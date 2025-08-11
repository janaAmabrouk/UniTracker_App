import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../../providers/driver_provider.dart';
import '../../models/driver.dart';
import '../../models/driver_stats.dart';
import '../../models/driver_activity.dart';
import '../../services/auth_service.dart';
import '../../services/driver_service.dart';
import '../../services/driver_profile_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../splash_screen.dart';
import '../../services/supabase_service.dart';
import '../../../main.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  // Add TextEditingController for formatting
  final TextEditingController _dateController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverProfile() async {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser != null && currentUser.role == 'driver') {
      await DriverProfileService.instance.loadDriverProfile(currentUser.id);
    }
  }

  // Date formatting method
  String _formatDate(String input) {
    // Remove all non-digit characters
    input = input.replaceAll(RegExp(r'[^0-9]'), '');

    // Allow up to 8 digits (YYYYMMDD)
    if (input.length > 8) {
      input = input.substring(0, 8);
    }

    String formatted = '';

    // Add characters as they are typed
    for (int i = 0; i < input.length; i++) {
      // Add hyphen after YYYY and MM
      if (i == 4 || i == 6) {
        formatted += '-';
      }
      formatted += input[i];
    }

    return formatted;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null && mounted) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          final supabaseService = SupabaseService.instance;
          final authService = context.read<AuthService>();
          final driverId = authService.currentUser!.id;
          final imageUrl = await supabaseService.uploadDriverProfileImage(
            driverId: driverId,
            filePath: image.path,
          );

          if (imageUrl != null && mounted) {
            await supabaseService.updateDriverProfileImage(driverId, imageUrl);
            await DriverProfileService.instance.loadDriverProfile(driverId);
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('Failed to get image URL');
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Failed to upload profile image: \\${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: \\${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickLicenseImage(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          // Upload license image to Supabase
          final supabaseService = SupabaseService.instance;
          final imageUrl = await supabaseService.uploadDriverLicenseImage(
            driverId: context.read<AuthService>().currentUser!.id,
            filePath: image.path,
          );

          if (imageUrl != null && mounted) {
            await DriverProfileService.instance.updateLicenseImagePath(
              context.read<AuthService>().currentUser!.id,
              imageUrl,
            );
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('License image uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('Failed to get image URL');
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Failed to upload license image: \\${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: \\${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(24)),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(33),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: getProportionateScreenWidth(40),
              height: getProportionateScreenHeight(4),
              margin: EdgeInsets.only(bottom: getProportionateScreenHeight(24)),
              decoration: BoxDecoration(
                color: AppTheme.secondaryTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Profile Photo',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: getProportionateScreenHeight(24)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            SizedBox(height: getProportionateScreenHeight(42)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: getProportionateScreenWidth(64),
            height: getProportionateScreenWidth(64),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: getProportionateScreenWidth(32),
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, Driver driver) {
    final profile = DriverProfileService.instance.driverProfile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile not loaded yet. Please try again.')),
      );
      return;
    }
    final nameController =
        TextEditingController(text: profile['fullName'] ?? driver.name);
    final driverIdController =
        TextEditingController(text: profile['driverId'] ?? '');
    final phoneController = TextEditingController(text: profile['phone'] ?? '');
    final licenseController = TextEditingController(
        text: profile['licenseNumber'] ?? driver.licenseNumber);
    final licenseImagePath = profile['licenseImagePath'] ?? '';
    if (profile['licenseExpiry'] != null &&
        profile['licenseExpiry'].toString().isNotEmpty) {
      _dateController.text = profile['licenseExpiry'];
    } else if (driver.licenseExpirationDate != null) {
      _dateController.text =
          DateFormat('yyyy-MM-dd').format(driver.licenseExpirationDate!);
    } else {
      _dateController.text = '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(getProportionateScreenWidth(33)),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.only(bottom: getProportionateScreenHeight(16)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(20),
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
                        SizedBox(height: getProportionateScreenHeight(20)),
                        // Profile Image with Edit Icon
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: getProportionateScreenWidth(80),
                                height: getProportionateScreenWidth(80),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.secondaryColor,
                                ),
                                child: _buildProfileImage(driver),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _showImageSourceSheet,
                                  child: Container(
                                    padding: EdgeInsets.all(
                                        getProportionateScreenWidth(8)),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryColor,
                                        width: getProportionateScreenWidth(2),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: AppTheme.primaryColor,
                                      size: getProportionateScreenWidth(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(20)),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            contentPadding: EdgeInsets.zero,
                            border: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: getProportionateScreenWidth(2),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(16)),
                        TextField(
                          controller: driverIdController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Driver ID',
                            contentPadding: EdgeInsets.zero,
                            border: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: getProportionateScreenWidth(2),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(16)),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            contentPadding: EdgeInsets.zero,
                            border: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: getProportionateScreenWidth(2),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(16)),
                        TextField(
                          controller: licenseController,
                          decoration: InputDecoration(
                            labelText: 'License Number',
                            contentPadding: EdgeInsets.zero,
                            border: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: getProportionateScreenWidth(2),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(16)),
                        TextField(
                          controller: _dateController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final formatted = _formatDate(value);
                            _dateController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          },
                          maxLength: 10,
                          decoration: InputDecoration(
                            labelText: 'License Expiry (YYYY-MM-DD)',
                            contentPadding: EdgeInsets.zero,
                            border: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: getProportionateScreenWidth(2),
                              ),
                            ),
                            counterText: '',
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(20)),
                        // License Image Upload Section
                        Text(
                          'License Image',
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(16),
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(8)),
                        Container(
                          width: double.infinity,
                          padding:
                              EdgeInsets.all(getProportionateScreenWidth(16)),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              if (licenseImagePath.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  height: getProportionateScreenWidth(120),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade100,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      licenseImagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.image_not_supported,
                                        size: getProportionateScreenWidth(40),
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(
                                  height: getProportionateScreenHeight(12)),
                              ElevatedButton.icon(
                                onPressed: () => _pickLicenseImage(context),
                                icon: Icon(
                                  Icons.upload_file,
                                  size: getProportionateScreenWidth(16),
                                  color: Colors.white,
                                ),
                                label: Text(
                                  licenseImagePath.isNotEmpty
                                      ? 'Change License Image'
                                      : 'Upload License Image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: getProportionateScreenWidth(14),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: getProportionateScreenWidth(16),
                                    vertical: getProportionateScreenHeight(8),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(32)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppTheme.secondaryTextColor,
                                  fontSize: getProportionateScreenWidth(14),
                                ),
                              ),
                            ),
                            SizedBox(width: getProportionateScreenWidth(16)),
                            ElevatedButton(
                              onPressed: () async {
                                final provider = Provider.of<DriverProvider>(
                                    context,
                                    listen: false);
                                provider.updateProfile(
                                  name: nameController.text,
                                  licenseNumber: licenseController.text,
                                  licenseExpirationDate:
                                      DateTime.tryParse(_dateController.text),
                                );
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(20),
                                  vertical: getProportionateScreenHeight(8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(20)),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: getProportionateScreenWidth(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    if (_isLoggingOut) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final isTablet = SizeConfig.screenWidth > 600;
    final padding = getProportionateScreenWidth(isTablet ? 24 : 16);

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.currentUser;
        if (user == null || user.role != 'driver') {
          return const Center(child: Text('No driver profile found.'));
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            DriverService.instance,
            DriverProfileService.instance,
            Provider.of<DriverProvider>(context),
          ]),
          builder: (context, child) {
            final driverService = DriverService.instance;
            final profileService = DriverProfileService.instance;
            final stats = driverService.driverStats;
            final activities = driverService.tripHistory;
            final profile = profileService.driverProfile;
            final provider =
                Provider.of<DriverProvider>(context, listen: false);
            final driver = provider.driver;

            if (driverService.isLoading || profileService.isLoading) {
              return Scaffold(
                backgroundColor: AppTheme.backgroundColor,
                appBar: AppBar(
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'Profile',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (profileService.error != null) {
              return Scaffold(
                backgroundColor: AppTheme.backgroundColor,
                appBar: AppBar(
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'Profile',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${profileService.error}'),
                      ElevatedButton(
                        onPressed: _loadDriverProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              appBar: AppBar(
                backgroundColor: AppTheme.primaryColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  'Profile',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          children: [
                            _buildDriverProfileCard(context, user, profile,
                                stats, isTablet, driver),
                            SizedBox(height: getProportionateScreenHeight(16)),
                            if (activities.isNotEmpty)
                              _buildRecentActivityCard(
                                  context, activities, isTablet),
                            if (activities.isNotEmpty)
                              SizedBox(
                                  height: getProportionateScreenHeight(16)),
                            if (stats != null)
                              _buildPerformanceStatsCard(
                                  context, stats, isTablet),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDriverProfileCard(
      BuildContext context,
      user,
      Map<String, dynamic>? profile,
      DriverStats? stats,
      bool isTablet,
      Driver? driver) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(getProportionateScreenWidth(24)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(33),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: getProportionateScreenWidth(80),
            height: getProportionateScreenWidth(80),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: getProportionateScreenWidth(4),
              ),
            ),
            child: Icon(
              Icons.person_outline,
              color: Colors.white,
              size: getProportionateScreenWidth(40),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          // Driver Name
          Text(
            profile?['fullName'] ?? user.name,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          // Driver Email
          if (profile?['email'] != null)
            Text(
              profile!['email'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
            ),
          if (profile?['email'] != null)
            SizedBox(height: getProportionateScreenHeight(4)),
          // Driver License
          if (profile?['licenseNumber'] != null)
            Text(
              'License: ${profile!['licenseNumber']}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
            ),
          if (profile?['licenseNumber'] != null)
            SizedBox(height: getProportionateScreenHeight(4)),
          // Joined Date
          if (profile?['joinedDate'] != null)
            Text(
              'Joined: ${_formatJoinedDate(DateTime.parse(profile!['joinedDate']))}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
            ),
          SizedBox(height: getProportionateScreenHeight(20)),
          // Quick Stats Row
          if (stats != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickStat(
                  context,
                  'Trips',
                  '${stats.completedTrips}',
                  Icons.route,
                  isTablet,
                ),
                _buildQuickStat(
                  context,
                  'Rating',
                  '${stats.rating.toStringAsFixed(1)}',
                  Icons.star,
                  isTablet,
                ),
                _buildQuickStat(
                  context,
                  'On Time',
                  '${stats.onTimePerformance.toStringAsFixed(0)}%',
                  Icons.schedule,
                  isTablet,
                ),
              ],
            ),
          SizedBox(height: getProportionateScreenHeight(20)),
          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Create a Driver object from user data if provider.driver is null
                final driverToEdit = driver ??
                    Driver(
                      id: user.id,
                      name: user.name,
                      driverId: user.driverId ?? '',
                      licenseNumber: profile?['licenseNumber'] ?? '',
                      licenseExpirationDate: profile?['licenseExpiry'] != null
                          ? DateTime.tryParse(profile!['licenseExpiry']) ??
                              DateTime.now().add(const Duration(days: 365))
                          : DateTime.now().add(const Duration(days: 365)),
                      licenseImagePath: profile?['licenseImagePath'] ?? '',
                      profileImage: profile?['profileImage'],
                      isAvailable: true,
                      currentRouteId: null,
                      currentBusId: null,
                      isLocalImage: false,
                    );
                _showEditProfileDialog(context, driverToEdit);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(33),
                ),
                elevation: 0,
              ),
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(24)),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: Icon(
                Icons.logout,
                color: Colors.white,
                size: getProportionateScreenWidth(20),
              ),
              label: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: getProportionateScreenWidth(16),
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(16),
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(33),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value,
      IconData icon, bool isTablet) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatJoinedDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  void _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      setState(() => _isLoggingOut = true);
      await Provider.of<AuthProvider>(context, listen: false).logout();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(initialRole: 'driver'),
          ),
          (route) => false,
        );
      });
    }
  }

  Widget _buildProfileImage(Driver driver) {
    if (driver.profileImage != null && driver.profileImage!.isNotEmpty) {
      if (driver.isLocalImage == true) {
        // Display local image file
        return ClipOval(
          child: Image.file(
            File(driver.profileImage!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.person_outline,
              size: getProportionateScreenWidth(40),
              color: Colors.grey[400],
            ),
          ),
        );
      } else {
        // Display network image
        return ClipOval(
          child: Image.network(
            driver.profileImage!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.person_outline,
              size: getProportionateScreenWidth(40),
              color: Colors.grey[400],
            ),
          ),
        );
      }
    }
    return Icon(
      Icons.person_outline,
      size: getProportionateScreenWidth(40),
      color: Colors.grey[400],
    );
  }

  Widget _buildRecentActivityCard(
    BuildContext context,
    List<DriverActivity> activities,
    bool isTablet,
  ) {
    final padding = getProportionateScreenWidth(isTablet ? 20 : 24);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(33),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: getProportionateScreenHeight(isTablet ? 16 : 12)),
            ...activities
                .map((activity) => Padding(
                      padding: EdgeInsets.only(
                        bottom: getProportionateScreenHeight(isTablet ? 8 : 10),
                      ),
                      child: _buildActivityItem(context, activity, isTablet),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    DriverActivity activity,
    bool isTablet,
  ) {
    final iconSize = getProportionateScreenWidth(isTablet ? 16 : 20);
    final padding = getProportionateScreenWidth(isTablet ? 12 : 16);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _getActivityBackgroundColor(activity.status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(padding * 0.6),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(33),
            ),
            child: Icon(
              _activityIcon(activity.type),
              color: _activityColor(activity.status),
              size: iconSize,
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textColor,
                      ),
                ),
                SizedBox(height: getProportionateScreenHeight(2)),
                Text(
                  DateFormat('MMM dd, yyyy h:mm a').format(activity.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStatsCard(
    BuildContext context,
    DriverStats stats,
    bool isTablet,
  ) {
    // Determine performance label and color
    String performanceLabel;
    Color performanceColor;
    final onTime = stats.onTimePerformance;
    final safety = stats.safetyScore;
    final satisfaction = stats.customerSatisfaction;

    if (onTime >= 90 && safety >= 90 && satisfaction >= 90) {
      performanceLabel = 'Excellent';
      performanceColor = AppTheme.successColor;
    } else if (onTime >= 75 && safety >= 75 && satisfaction >= 75) {
      performanceLabel = 'Good';
      performanceColor = AppTheme.infoColor;
    } else if (onTime >= 50 && safety >= 50 && satisfaction >= 50) {
      performanceLabel = 'Average';
      performanceColor = AppTheme.warningColor;
    } else {
      performanceLabel = 'Needs Improvement';
      performanceColor = AppTheme.errorColor;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(33),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Performance Stats',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: getProportionateScreenHeight(8)),
            // Right-aligned label below title
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(12),
                    vertical: getProportionateScreenHeight(4),
                  ),
                  decoration: BoxDecoration(
                    color: performanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    performanceLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: performanceColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: getProportionateScreenHeight(24)),
            _buildPerformanceItem(
              context,
              'On-time Performance',
              onTime / 100.0,
              '${onTime.toStringAsFixed(0)}%',
              AppTheme.successColor,
              isTablet,
            ),
            SizedBox(height: getProportionateScreenHeight(16)),
            _buildPerformanceItem(
              context,
              'Safety Score',
              safety / 100.0,
              '${safety.toStringAsFixed(0)}%',
              AppTheme.infoColor,
              isTablet,
            ),
            SizedBox(height: getProportionateScreenHeight(16)),
            _buildPerformanceItem(
              context,
              'Customer Satisfaction',
              satisfaction / 100.0,
              '${satisfaction.toStringAsFixed(0)}%',
              AppTheme.warningColor,
              isTablet,
            ),
            SizedBox(height: getProportionateScreenHeight(24)),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _showFullReportSheet(context, stats),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(
                    vertical: getProportionateScreenHeight(16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(33),
                  ),
                ),
                child: Text(
                  'View Full Report',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(
    BuildContext context,
    String label,
    double value,
    String percentage,
    Color color,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              percentage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        ClipRRect(
          borderRadius: BorderRadius.circular(33),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: getProportionateScreenHeight(10),
          ),
        ),
      ],
    );
  }

  Color _getActivityBackgroundColor(DriverActivityStatus status) {
    switch (status) {
      case DriverActivityStatus.completed:
        return AppTheme.successColor.withOpacity(0.1);
      case DriverActivityStatus.inProgress:
        return AppTheme.infoColor.withOpacity(0.1);
      case DriverActivityStatus.scheduled:
        return AppTheme.warningColor.withOpacity(0.1);
      case DriverActivityStatus.cancelled:
        return AppTheme.errorColor.withOpacity(0.1);
      default:
        return AppTheme.secondaryColor;
    }
  }

  IconData _activityIcon(DriverActivityType type) {
    // Implementation of _activityIcon method
    // This is a placeholder and should be replaced with the actual implementation
    return Icons.help; // Placeholder return, actual implementation needed
  }

  Color _activityColor(DriverActivityStatus status) {
    switch (status) {
      case DriverActivityStatus.completed:
        return AppTheme.successColor;
      case DriverActivityStatus.inProgress:
        return AppTheme.infoColor;
      case DriverActivityStatus.scheduled:
        return AppTheme.warningColor;
      case DriverActivityStatus.cancelled:
        return AppTheme.errorColor;
      default:
        return AppTheme.secondaryTextColor;
    }
  }

  void _showFullReportSheet(BuildContext context, DriverStats stats) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(33)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Full Performance Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text('Completed Trips: ${stats.completedTrips}'),
            Text('Rating: ${stats.rating.toStringAsFixed(1)}/5'),
            Text(
                'On-time Performance: ${stats.onTimePerformance.toStringAsFixed(1)}%'),
            Text('Safety Score: ${stats.safetyScore.toStringAsFixed(1)}%'),
            Text(
                'Customer Satisfaction: ${stats.customerSatisfaction.toStringAsFixed(1)}%'),
            Text('Joined: ${_formatJoinedDate(stats.joinedDate)}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(33),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
