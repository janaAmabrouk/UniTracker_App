import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../../providers/driver_provider.dart';
import '../../models/driver.dart';
import '../../models/driver_stats.dart';
import '../../models/driver_activity.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  // Add TextEditingController for formatting
  final TextEditingController _dateController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
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
        final provider = Provider.of<DriverProvider>(context, listen: false);
        // Store the local file path temporarily for immediate display
        setState(() {
          provider.updateProfile(profileImage: image.path, isLocalImage: true);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture'),
            backgroundColor: AppTheme.errorColor,
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
            SizedBox(height: getProportionateScreenHeight(24)),
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
    final nameController = TextEditingController(text: driver.name);
    final licenseController = TextEditingController(text: driver.licenseNumber);

    if (driver.licenseExpirationDate != null) {
      _dateController.text =
          DateFormat('yyyy-MM-dd').format(driver.licenseExpirationDate!);
    } else {
      _dateController.text = '';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(33),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: getProportionateScreenHeight(24)),
                // Profile Photo Section
                Center(
                  child: Column(
                    children: [
                      Stack(
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
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: getProportionateScreenWidth(32),
                              height: getProportionateScreenWidth(32),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => _showImageSourceSheet(),
                                icon: Icon(
                                  Icons.camera_alt_rounded,
                                  size: getProportionateScreenWidth(16),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(
                                    getProportionateScreenWidth(4)),
                                constraints: BoxConstraints(
                                  minWidth: getProportionateScreenWidth(26),
                                  minHeight: getProportionateScreenWidth(26),
                                ),
                                splashRadius: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: getProportionateScreenHeight(8)),
                      Text(
                        'Change Profile Photo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(24)),
                Text(
                  'Name',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                SizedBox(height: getProportionateScreenHeight(4)),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    filled: true,
                    fillColor: AppTheme.secondaryColor.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(16),
                      vertical: getProportionateScreenHeight(12),
                    ),
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(16)),
                Text(
                  'License Number',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                SizedBox(height: getProportionateScreenHeight(4)),
                TextField(
                  controller: licenseController,
                  decoration: InputDecoration(
                    hintText: 'Enter license number',
                    filled: true,
                    fillColor: AppTheme.secondaryColor.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(16),
                      vertical: getProportionateScreenHeight(12),
                    ),
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(16)),
                Text(
                  'License Expiry',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                SizedBox(height: getProportionateScreenHeight(4)),
                TextField(
                  controller: _dateController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final formatted = _formatDate(value);
                    _dateController.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  },
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: 'YYYY-MM-DD',
                    filled: true,
                    fillColor: AppTheme.secondaryColor.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(16),
                      vertical: getProportionateScreenHeight(12),
                    ),
                    counterText: '',
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(32)),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: getProportionateScreenHeight(16),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(33),
                            side: BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: getProportionateScreenWidth(16)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final provider = Provider.of<DriverProvider>(context,
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
                            vertical: getProportionateScreenHeight(16),
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(33),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final isTablet = SizeConfig.screenWidth > 600;
    final padding = getProportionateScreenWidth(isTablet ? 24 : 16);

    return Consumer<DriverProvider>(
      builder: (context, provider, _) {
        final driver = provider.driver;
        final stats = provider.stats;
        if (driver == null) {
          return const Center(child: Text('No driver profile found.'));
        }
        if (stats == null) {
          return const Center(child: CircularProgressIndicator());
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
                        _buildProfileCard(context, driver, stats, isTablet),
                        SizedBox(height: getProportionateScreenHeight(16)),
                        _buildRecentActivityCard(
                            context, provider.activities, isTablet),
                        SizedBox(height: getProportionateScreenHeight(16)),
                        _buildPerformanceStatsCard(context, stats, isTablet),
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
  }

  Widget _buildProfileCard(
      BuildContext context, Driver driver, DriverStats stats, bool isTablet) {
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
          // Profile Image with Edit Button
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showEditProfileDialog(context, driver),
                child: Container(
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenWidth(80),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.secondaryColor,
                  ),
                  child: _buildProfileImage(driver),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: getProportionateScreenWidth(32),
                  height: getProportionateScreenWidth(32),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _showEditProfileDialog(context, driver),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: getProportionateScreenWidth(16),
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.all(getProportionateScreenWidth(4)),
                    constraints: BoxConstraints(
                      minWidth: getProportionateScreenWidth(26),
                      minHeight: getProportionateScreenWidth(26),
                    ),
                    splashRadius: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          // Driver Name
          Text(
            driver.name,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          // Driver ID
          Text(
            'Driver ID: ${driver.driverId}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          // Joined Date
          Text(
            'Joined: ${_formatJoinedDate(stats.joinedDate)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(24)),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Total Trips
              Expanded(
                child: Container(
                  margin:
                      EdgeInsets.only(right: getProportionateScreenWidth(8)),
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(12),
                    vertical: getProportionateScreenHeight(16),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        stats.totalTrips.toString(),
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(4)),
                      Text(
                        'Total Trips',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.secondaryTextColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              // Rating
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: getProportionateScreenWidth(8)),
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(12),
                    vertical: getProportionateScreenHeight(16),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${stats.rating.toStringAsFixed(1)}/5',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(4)),
                      Text(
                        'Rating',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.secondaryTextColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  String _formatJoinedDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
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
            Text('Total Trips: ${stats.totalTrips}'),
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

  void _handleLogout(BuildContext context) async {
    print('Logout dialog confirmed');
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
      print('Calling AuthProvider.logout()...');
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => const LoginScreen(initialRole: 'driver')),
          (route) => false,
        );
      }
    }
  }
}
