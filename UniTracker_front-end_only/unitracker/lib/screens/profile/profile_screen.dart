import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unitracker/utils/responsive_utils.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/services/reservation_service.dart';
import 'package:unitracker/services/auth_service.dart';
import 'package:unitracker/models/user.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:unitracker/screens/auth/login_screen.dart';
import 'package:unitracker/services/notification_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unitracker/services/notification_service.dart';
import 'package:unitracker/services/supabase_service.dart';
import 'package:unitracker/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unitracker/screens/profile/input_formatters.dart';
import 'package:flutter/services.dart';
import '../../models/driver_stats.dart';
import '../../models/driver_activity.dart';
import '../../services/driver_stats_service.dart';
import '../../services/payment_history_service.dart';
import '../../models/payment_history.dart';

class NotificationSettingsDialog extends StatelessWidget {
  const NotificationSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<NotificationSettingsService>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(33)),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: getProportionateScreenWidth(400)),
        padding: EdgeInsets.fromLTRB(
            getProportionateScreenWidth(24),
            getProportionateScreenHeight(24),
            getProportionateScreenWidth(24),
            getProportionateScreenHeight(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: getProportionateScreenHeight(24)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Route Delays'),
              value: settings.routeDelaysEnabled,
              onChanged: (bool value) {
                settings.setRouteDelaysEnabled(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reservation Updates'),
              value: settings.reservationUpdatesEnabled,
              onChanged: (bool value) {
                settings.setReservationUpdatesEnabled(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Schedule Changes'),
              value: settings.scheduleChangesEnabled,
              onChanged: (bool value) {
                settings.setScheduleChangesEnabled(value);
              },
            ),
            SizedBox(height: getProportionateScreenHeight(16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(8),
                        vertical: getProportionateScreenHeight(4)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(16),
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  List<Map<String, String>> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
    // Load driver stats when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final authProvider = context.read<AuthProvider>();
      debugPrint('ProfileScreen: Loading user profile...');
      debugPrint(
          'ProfileScreen: Current user: ${authProvider.currentUser?.name}');

      if (authProvider.currentUser == null) {
        debugPrint('ProfileScreen: No user found, attempting to load...');
        await authProvider.loadUserProfile();
      }

      _updateUserData();
      debugPrint('ProfileScreen: Profile loaded successfully');
    } catch (e) {
      debugPrint('ProfileScreen: Error loading profile: $e');
    }
  }

  void _updateUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    debugPrint('ProfileScreen _updateUserData: user = $user');
    debugPrint('ProfileScreen _updateUserData: user name = ${user?.name}');

    if (user != null) {
      // Initialize controllers with real user data
      setState(() {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _studentIdController.text = user.studentId;
        _universityController.text = user.university;
        _departmentController.text = user.department;
      });

      if (user.role == 'driver') {
        context.read<DriverStatsService>().loadDriverStats(user.id);
      }
    } else {
      debugPrint('ProfileScreen _updateUserData: User is null!');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) return;

      final response = await SupabaseService.instance.client
          .from('user_payment_cards')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      final cardsData = response as List<dynamic>? ?? [];

      setState(() {
        _cards = cardsData
            .map((card) => {
                  'id': card['id'] as String,
                  'cardNumber':
                      '**** **** **** ${card['card_number_encrypted'].substring(card['card_number_encrypted'].length - 4)}',
                  'cardHolder': card['card_holder_name'] as String,
                  'expiryMonth': card['expiry_month'] as String,
                  'expiryYear': card['expiry_year'] as String,
                  'cardType': card['card_type'] as String,
                  'isDefault':
                      (card['is_default'] as bool? ?? false).toString(),
                })
            .toList();
      });

      debugPrint('✅ Loaded ${_cards.length} payment cards from Supabase');
    } catch (e) {
      debugPrint('❌ Error loading payment cards: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load payment cards: $e')),
      );
    }
  }

  Future<void> _addCard(Map<String, String> card) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Simple encryption (in production, use proper encryption)
      final encryptedCardNumber = card['cardNumber']!.replaceAll(' ', '');

      final response = await SupabaseService.instance.client
          .from('user_payment_cards')
          .insert({
            'user_id': currentUser.id,
            'card_number_encrypted': encryptedCardNumber,
            'card_holder_name': card['cardHolder']!,
            'expiry_month': card['expiryMonth']!,
            'expiry_year': card['expiryYear']!,
            'card_type': card['cardType']!,
            'is_default': card['isDefault'] == 'true',
          })
          .select()
          .single();

      // Add to local list with masked card number
      final newCard = {
        'id': response['id'] as String,
        'cardNumber':
            '**** **** **** ${encryptedCardNumber.substring(encryptedCardNumber.length - 4)}',
        'cardHolder': card['cardHolder']!,
        'expiryMonth': card['expiryMonth']!,
        'expiryYear': card['expiryYear']!,
        'cardType': card['cardType']!,
        'isDefault': card['isDefault']!,
      };

      setState(() {
        _cards.add(newCard);
      });

      // Add a demo payment record for the new card
      try {
        final paymentHistoryService = PaymentHistoryService();
        await paymentHistoryService.addPaymentRecord(
          userId: currentUser.id,
          cardId: response['id'] as String,
          amount: 0.00, // Demo amount
          currency: 'EGP',
          status: 'completed',
          description: 'Card verification',
        );
      } catch (e) {
        debugPrint('❌ Error adding demo payment record: $e');
        // Don't fail the card addition if payment record fails
      }

      debugPrint('✅ Payment card added to Supabase');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment card added successfully')),
      );
    } catch (e) {
      debugPrint('❌ Error adding payment card: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add payment card: $e')),
      );
    }
  }

  Future<void> _removeCard(int index) async {
    try {
      final cardId = _cards[index]['id'];
      if (cardId == null) return;

      await SupabaseService.instance.client
          .from('user_payment_cards')
          .delete()
          .eq('id', cardId);

      setState(() {
        _cards.removeAt(index);
      });

      debugPrint('✅ Payment card removed from Supabase');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment card removed successfully')),
      );
    } catch (e) {
      debugPrint('❌ Error removing payment card: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove payment card: $e')),
      );
    }
  }

  Future<void> _setDefaultCard(int index) async {
    try {
      final cardId = _cards[index]['id'];
      if (cardId == null) return;

      // Update all cards to set is_default to false
      await SupabaseService.instance.client
          .from('user_payment_cards')
          .update({'is_default': false}).eq(
              'user_id', context.read<AuthProvider>().currentUser!.id);

      // Set the selected card as default
      await SupabaseService.instance.client
          .from('user_payment_cards')
          .update({'is_default': true}).eq('id', cardId);

      // Update local state
      setState(() {
        for (int i = 0; i < _cards.length; i++) {
          _cards[i]['isDefault'] = (i == index).toString();
        }
      });

      debugPrint('✅ Default card updated');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default payment method updated')),
      );
    } catch (e) {
      debugPrint('❌ Error setting default card: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update default card: $e')),
      );
    }
  }

  IconData _getCardTypeIcon(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'american express':
        return Icons.credit_card;
      case 'discover':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }

  Color _getCardTypeColor(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.orange;
      case 'american express':
        return Colors.green;
      case 'discover':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _detectCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.startsWith('4')) {
      return 'Visa';
    } else if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) {
      return 'Mastercard';
    } else if (cleanNumber.startsWith('3')) {
      return 'American Express';
    } else if (cleanNumber.startsWith('6')) {
      return 'Discover';
    }
    return 'Unknown';
  }

  bool _validateCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.length != 16) return false;

    // Luhn algorithm validation
    int sum = 0;
    bool isEven = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 == 0;
  }

  bool _validateExpiryDate(String expiry) {
    if (expiry.length != 5 || !expiry.contains('/')) return false;

    final parts = expiry.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    final currentYear = DateTime.now().year % 100;
    final currentMonth = DateTime.now().month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return false;
    }

    return true;
  }

  Widget _buildImageSourceOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: getProportionateScreenWidth(60),
            height: getProportionateScreenWidth(60),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(getProportionateScreenWidth(20)),
            ),
            child: Icon(
              icon,
              size: getProportionateScreenWidth(30),
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Text(
            label,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(getProportionateScreenWidth(20)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: getProportionateScreenWidth(10),
                  spreadRadius: getProportionateScreenWidth(0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin:
                        EdgeInsets.only(top: getProportionateScreenHeight(8)),
                    height: getProportionateScreenWidth(4),
                    width: getProportionateScreenWidth(40),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius:
                          BorderRadius.circular(getProportionateScreenWidth(2)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(24),
                      vertical: getProportionateScreenHeight(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Choose Profile Photo',
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(18),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(24)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildImageSourceOption(
                              context,
                              Icons.camera_alt,
                              'Camera',
                              () async {
                                Navigator.pop(context);
                                try {
                                  final XFile? image = await _picker.pickImage(
                                    source: ImageSource.camera,
                                    preferredCameraDevice: CameraDevice.front,
                                    maxWidth: 1024,
                                    maxHeight: 1024,
                                    imageQuality: 85,
                                  );
                                  if (image != null && mounted) {
                                    setState(() {
                                      _profileImage = File(image.path);
                                    });
                                    // Upload image immediately
                                    await _uploadProfileImage(image.path);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to access camera: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            _buildImageSourceOption(
                              context,
                              Icons.photo_library,
                              'Gallery',
                              () async {
                                Navigator.pop(context);
                                try {
                                  final XFile? image = await _picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1024,
                                    maxHeight: 1024,
                                    imageQuality: 85,
                                  );
                                  if (image != null && mounted) {
                                    setState(() {
                                      _profileImage = File(image.path);
                                    });
                                    // Upload image immediately
                                    await _uploadProfileImage(image.path);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to access gallery: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: getProportionateScreenHeight(24)),
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

  Future<void> _uploadProfileImage(String imagePath) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      if (!authProvider.isAuthenticated) {
        throw Exception('Authentication required. Please log in again.');
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading profile image...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Upload image to Supabase
      final imageUrl =
          await authProvider.uploadProfileImage(currentUser.id, imagePath);

      // Update profile with the new image URL
      await authProvider.updateProfile(
        profileImage: imageUrl,
      );

      // Refresh the UI to show the new image
      setState(() {
        // Clear the local image since we now have the network image
        _profileImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image uploaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Upload error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _uploadProfileImage(imagePath),
            ),
          ),
        );
      }
    }
  }

  // Add this method to handle name capitalization
  String _capitalizeNames(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _handleEditProfile(BuildContext context, User user) {
    // Initialize with capitalized name
    final nameController =
        TextEditingController(text: _capitalizeNames(user.name));
    final emailController = TextEditingController(text: user.email);
    final studentIdController = TextEditingController(text: user.studentId);
    final universityController = TextEditingController(text: user.university);
    final departmentController = TextEditingController(text: user.department);

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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: getProportionateScreenHeight(20)),
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: getProportionateScreenWidth(100),
                          height: getProportionateScreenWidth(100),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[100],
                            border: Border.all(
                              color: Colors.white,
                              width: getProportionateScreenWidth(3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: getProportionateScreenWidth(8),
                                spreadRadius: getProportionateScreenWidth(0),
                                offset:
                                    Offset(0, getProportionateScreenHeight(2)),
                              ),
                            ],
                          ),
                          child: _profileImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _profileImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : (user.profileImage != null &&
                                      user.profileImage!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        user.profileImage! +
                                            '?v=${DateTime.now().millisecondsSinceEpoch}',
                                        key: ValueKey(user.profileImage),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                          Icons.person_outline,
                                          size: getProportionateScreenWidth(35),
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.person_outline,
                                      size: getProportionateScreenWidth(35),
                                      color: AppTheme.primaryColor,
                                    ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: EdgeInsets.all(
                                  getProportionateScreenWidth(8)),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: getProportionateScreenWidth(2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: getProportionateScreenWidth(4),
                                    spreadRadius:
                                        getProportionateScreenWidth(0),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: getProportionateScreenWidth(16),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(24)),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      contentPadding: EdgeInsets.zero,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      contentPadding: EdgeInsets.zero,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                    controller: studentIdController,
                    decoration: InputDecoration(
                      labelText: 'Student ID',
                      contentPadding: EdgeInsets.zero,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                    controller: universityController,
                    decoration: InputDecoration(
                      labelText: 'University',
                      contentPadding: EdgeInsets.zero,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                    controller: departmentController,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      contentPadding: EdgeInsets.zero,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: getProportionateScreenWidth(2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(24)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(16),
                            vertical: getProportionateScreenHeight(8),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: getProportionateScreenWidth(16),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final authProvider = context.read<AuthProvider>();
                            await authProvider.updateProfile(
                              name: _capitalizeNames(nameController.text),
                              email: emailController.text,
                              studentId: studentIdController.text,
                              university: universityController.text,
                              department: departmentController.text,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update profile: $e'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1A237E), // Deep purple color
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(32),
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
                  SizedBox(height: getProportionateScreenHeight(16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationSettings(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final notificationSettingsService = NotificationSettingsService(prefs);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangeNotifierProvider.value(
          value: notificationSettingsService,
          child: const NotificationSettingsDialog(),
        );
      },
    );
  }

  void _handlePaymentMethods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(getProportionateScreenWidth(33)),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar at top
                    Container(
                      width: getProportionateScreenWidth(40),
                      height: getProportionateScreenHeight(4),
                      margin:
                          EdgeInsets.only(top: getProportionateScreenHeight(8)),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(2)),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        getProportionateScreenWidth(24),
                        getProportionateScreenHeight(16),
                        getProportionateScreenWidth(24),
                        getProportionateScreenHeight(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment Methods',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(20),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                          SizedBox(height: getProportionateScreenHeight(24)),
                          // Add New Card Button
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _showAddCardDialog(context);
                            },
                            child: Container(
                              padding: EdgeInsets.all(
                                  getProportionateScreenWidth(16)),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(
                                    getProportionateScreenWidth(12)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                        getProportionateScreenWidth(10)),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  SizedBox(
                                      width: getProportionateScreenWidth(16)),
                                  Text(
                                    'Add New Card',
                                    style: TextStyle(
                                      fontSize: getProportionateScreenWidth(16),
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_cards.isNotEmpty) ...[
                            SizedBox(height: getProportionateScreenHeight(24)),
                            Text(
                              'Saved Cards',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(16)),
                            ..._cards.asMap().entries.map((entry) => Padding(
                                  padding: EdgeInsets.only(
                                      bottom: getProportionateScreenHeight(8)),
                                  child: _buildSavedCard(
                                    context,
                                    entry.value['cardNumber'] ?? '',
                                    '${entry.value['cardType'] ?? 'Card'} • Expires ${entry.value['expiryMonth'] ?? ''}/${entry.value['expiryYear']?.substring(2) ?? ''}',
                                    _getCardTypeIcon(
                                        entry.value['cardType'] ?? ''),
                                    onRemove: () {
                                      Navigator.pop(context);
                                      _removeCard(entry.key);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Card removed successfully'),
                                        ),
                                      );
                                    },
                                    isDefault:
                                        entry.value['isDefault'] == 'true',
                                    onSetDefault: () {
                                      Navigator.pop(context);
                                      _setDefaultCard(entry.key);
                                    },
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onRemove,
    bool isDefault = false,
    VoidCallback? onSetDefault,
  }) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(12)),
        color: isDefault ? Colors.blue.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(10)),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: getProportionateScreenWidth(16),
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (isDefault)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: getProportionateScreenWidth(8),
                          vertical: getProportionateScreenHeight(4),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(12),
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: getProportionateScreenHeight(4)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!isDefault && onSetDefault != null)
            IconButton(
              onPressed: onSetDefault,
              icon: const Icon(Icons.star_outline),
              color: Colors.orange,
              tooltip: 'Set as default',
            ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              tooltip: 'Remove card',
            ),
        ],
      ),
    );
  }

  void _showAddCardDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final nameController = TextEditingController();
    bool _isLoading = false;
    String _detectedCardType = '';

    // Listen for card number changes to detect card type
    cardNumberController.addListener(() {
      final cardNumber = cardNumberController.text.replaceAll(' ', '');
      if (cardNumber.length >= 4) {
        _detectedCardType = _detectCardType(cardNumber);
      } else {
        _detectedCardType = '';
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(getProportionateScreenWidth(33)),
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar at top
                        Container(
                          width: getProportionateScreenWidth(40),
                          height: getProportionateScreenHeight(4),
                          margin: EdgeInsets.only(
                              top: getProportionateScreenHeight(8)),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(2)),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            getProportionateScreenWidth(24),
                            getProportionateScreenHeight(16),
                            getProportionateScreenWidth(24),
                            getProportionateScreenHeight(16),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Add New Card',
                                      style: TextStyle(
                                        fontSize:
                                            getProportionateScreenWidth(20),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.close),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(24)),
                                TextFormField(
                                  controller: cardNumberController,
                                  decoration: InputDecoration(
                                    labelText: 'Card Number',
                                    hintText: '4242 4242 4242 4242',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          getProportionateScreenWidth(12)),
                                    ),
                                    suffixIcon: _detectedCardType.isNotEmpty
                                        ? Container(
                                            margin: EdgeInsets.all(
                                                getProportionateScreenWidth(8)),
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  getProportionateScreenWidth(
                                                      8),
                                              vertical:
                                                  getProportionateScreenHeight(
                                                      4),
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getCardTypeColor(
                                                      _detectedCardType)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _detectedCardType,
                                              style: TextStyle(
                                                fontSize:
                                                    getProportionateScreenWidth(
                                                        12),
                                                color: _getCardTypeColor(
                                                    _detectedCardType),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(16),
                                    CardNumberInputFormatter(),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter card number';
                                    }
                                    final cleanNumber =
                                        value.replaceAll(' ', '');
                                    if (cleanNumber.length != 16) {
                                      return 'Card number must be 16 digits';
                                    }
                                    if (!_validateCardNumber(value)) {
                                      return 'Invalid card number';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(16)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: expiryController,
                                        decoration: InputDecoration(
                                          labelText: 'Expiry Date',
                                          hintText: 'MM/YY',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                getProportionateScreenWidth(
                                                    12)),
                                          ),
                                        ),
                                        inputFormatters: [
                                          CardExpiryInputFormatter()
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          if (!_validateExpiryDate(value)) {
                                            return 'Invalid expiry date';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                        width: getProportionateScreenWidth(16)),
                                    Expanded(
                                      child: TextFormField(
                                        controller: cvvController,
                                        decoration: InputDecoration(
                                          labelText: 'CVV',
                                          hintText: '123',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                getProportionateScreenWidth(
                                                    12)),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(3),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          if (value.length != 3) {
                                            return 'CVV must be 3 digits';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(16)),
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Card Holder Name',
                                    hintText: 'John Doe',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          getProportionateScreenWidth(12)),
                                    ),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter name on card';
                                    }
                                    if (value.trim().split(' ').length < 2) {
                                      return 'Please enter full name';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(24)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => Navigator.pop(context),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize:
                                                getProportionateScreenWidth(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                        width: getProportionateScreenWidth(16)),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () async {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  setState(
                                                      () => _isLoading = true);
                                                  await Future.delayed(
                                                      const Duration(
                                                          seconds: 1));
                                                  if (context.mounted) {
                                                    Navigator.pop(context);

                                                    // Parse expiry date
                                                    final expiryParts =
                                                        expiryController.text
                                                            .split('/');
                                                    final expiryMonth =
                                                        expiryParts.isNotEmpty
                                                            ? expiryParts[0]
                                                            : '01';
                                                    final expiryYear = expiryParts
                                                                .length >
                                                            1
                                                        ? '20${expiryParts[1]}'
                                                        : '2025';

                                                    // Use detected card type
                                                    final cardNumber =
                                                        cardNumberController
                                                            .text
                                                            .replaceAll(
                                                                ' ', '');
                                                    final cardType =
                                                        _detectedCardType
                                                                .isNotEmpty
                                                            ? _detectedCardType
                                                            : 'Unknown';

                                                    await _addCard({
                                                      'cardNumber': cardNumber,
                                                      'cardHolder':
                                                          nameController.text,
                                                      'expiryMonth':
                                                          expiryMonth,
                                                      'expiryYear': expiryYear,
                                                      'cardType': cardType,
                                                      'isDefault': _cards
                                                              .isEmpty
                                                          ? 'true'
                                                          : 'false', // Set as default if first card
                                                    });
                                                  }
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          padding: EdgeInsets.symmetric(
                                              vertical:
                                                  getProportionateScreenHeight(
                                                      12)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                getProportionateScreenWidth(
                                                    33)),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? SizedBox(
                                                width:
                                                    getProportionateScreenWidth(
                                                        20),
                                                height:
                                                    getProportionateScreenWidth(
                                                        20),
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                'Add Card',
                                                style: TextStyle(
                                                  fontSize:
                                                      getProportionateScreenWidth(
                                                          16),
                                                  color: Colors.white,
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
                      ],
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

  void _handleHelpSupport(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Contact Support'),
              onTap: () async {
                Navigator.pop(context);
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'support@unitracker.com',
                  query:
                      'subject=Support Request&body=Describe your issue here.',
                );
                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri,
                      mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open email app.'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('FAQs'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Frequently Asked Questions'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Q: How do I add a new card?'),
                          Text('A: Tap "Add New Card" in Payment Methods.'),
                          SizedBox(height: getProportionateScreenHeight(12)),
                          Text('Q: How do I contact support?'),
                          Text('A: Tap "Contact Support" in Help & Support.'),
                          SizedBox(height: getProportionateScreenHeight(12)),
                          Text('Q: How do I change my password?'),
                          Text(
                              'A: Tap "Change Password" in your profile menu.'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About UniTracker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'UniTracker v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: getProportionateScreenHeight(8)),
            const Text(
              'A university bus tracking and reservation system that helps students manage their daily commute efficiently.',
            ),
            SizedBox(height: getProportionateScreenHeight(16)),
            Text(
              '© 2024 UniTracker. All rights reserved.',
              style: TextStyle(fontSize: getProportionateScreenWidth(12)),
            ),
          ],
        ),
      ),
    );
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
      await Provider.of<AuthProvider>(context, listen: false).logout();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const LoginScreen(initialRole: 'student')),
        (route) => false,
      );
    }
  }

  void _handleChangePassword(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool _obscureCurrentPassword = true;
    bool _obscureNewPassword = true;
    bool _obscureConfirmPassword = true;
    bool _isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(getProportionateScreenWidth(20)),
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          getProportionateScreenWidth(24),
                          getProportionateScreenHeight(16),
                          getProportionateScreenWidth(24),
                          getProportionateScreenHeight(16)),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle bar at top
                            Center(
                              child: Container(
                                width: getProportionateScreenWidth(40),
                                height: getProportionateScreenHeight(4),
                                margin: EdgeInsets.only(
                                    bottom: getProportionateScreenHeight(16)),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(2)),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(20),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.close),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                              ],
                            ),
                            SizedBox(height: getProportionateScreenHeight(24)),
                            TextFormField(
                              controller: currentPasswordController,
                              obscureText: _obscureCurrentPassword,
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureCurrentPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscureCurrentPassword =
                                          !_obscureCurrentPassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12)),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your current password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(16)),
                            TextFormField(
                              controller: newPasswordController,
                              obscureText: _obscureNewPassword,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNewPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscureNewPassword =
                                          !_obscureNewPassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12)),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a new password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(16)),
                            TextFormField(
                              controller: confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12)),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your new password';
                                }
                                if (value != newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(24)),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          vertical:
                                              getProportionateScreenHeight(12)),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize:
                                            getProportionateScreenWidth(16),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: getProportionateScreenWidth(16)),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              setState(() => _isLoading = true);
                                              try {
                                                await context
                                                    .read<AuthService>()
                                                    .changePassword(
                                                      currentPassword:
                                                          currentPasswordController
                                                              .text,
                                                      newPassword:
                                                          newPasswordController
                                                              .text,
                                                    );
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Password changed successfully')),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content:
                                                            Text(e.toString())),
                                                  );
                                                }
                                                setState(
                                                    () => _isLoading = false);
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      padding: EdgeInsets.symmetric(
                                          vertical:
                                              getProportionateScreenHeight(12)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            getProportionateScreenWidth(33)),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width:
                                                getProportionateScreenWidth(20),
                                            height:
                                                getProportionateScreenWidth(20),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Change Password',
                                            style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      16),
                                              color: Colors.white,
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handlePaymentHistory(BuildContext context) async {
    final paymentHistoryService = PaymentHistoryService();
    final currentUser = context.read<AuthProvider>().currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to view payment history')),
      );
      return;
    }

    try {
      await paymentHistoryService.loadPaymentHistory(currentUser.id);
      final recentPayments = paymentHistoryService.getRecentPayments(limit: 10);
      final totalSpent = paymentHistoryService.getTotalSpent();

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(getProportionateScreenWidth(33)),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: getProportionateScreenWidth(40),
                      height: getProportionateScreenHeight(4),
                      margin:
                          EdgeInsets.only(top: getProportionateScreenHeight(8)),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(2)),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        getProportionateScreenWidth(24),
                        getProportionateScreenHeight(16),
                        getProportionateScreenWidth(24),
                        getProportionateScreenHeight(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment History',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(20),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                          SizedBox(height: getProportionateScreenHeight(16)),
                          // Total spent summary
                          Container(
                            padding:
                                EdgeInsets.all(getProportionateScreenWidth(16)),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(12)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: AppTheme.primaryColor,
                                  size: getProportionateScreenWidth(24),
                                ),
                                SizedBox(
                                    width: getProportionateScreenWidth(12)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Spent',
                                      style: TextStyle(
                                        fontSize:
                                            getProportionateScreenWidth(14),
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'EGP ${totalSpent.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize:
                                            getProportionateScreenWidth(18),
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(24)),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: getProportionateScreenWidth(48),
                                  color: Colors.grey[400],
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(16)),
                                Text(
                                  'No payment history yet',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(16),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(8)),
                                Text(
                                  'Your payment transactions will appear here',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(14),
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load payment history: $e')),
        );
      }
    }
  }

  Widget _buildPaymentHistoryItem(PaymentHistory payment) {
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(12)),
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(12)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(10)),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(payment.status).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPaymentStatusIcon(payment.status),
              color: _getPaymentStatusColor(payment.status),
              size: getProportionateScreenWidth(20),
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.description,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(16),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(4)),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(payment.createdAt),
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'EGP ${payment.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(16),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(4)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(8),
                  vertical: getProportionateScreenHeight(4),
                ),
                decoration: BoxDecoration(
                  color:
                      _getPaymentStatusColor(payment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payment.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(12),
                    color: _getPaymentStatusColor(payment.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final user = context.read<AuthProvider>().currentUser;
    // Debug print to verify user data
    print('ProfileScreen user: ${user?.toJson()}');

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            'Profile',
            style: TextStyle(
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              fontSize: getProportionateScreenWidth(20),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final user = authProvider.currentUser;
                if (user == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Please sign in to view your profile',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: getProportionateScreenHeight(16)),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const LoginScreen(initialRole: 'student'),
                              ),
                            );
                          },
                          child: Text('Sign In'),
                        ),
                      ],
                    ),
                  );
                }

                // --- SWITCH UI BASED ON ROLE ---
                if (user.role == 'driver') {
                  // DRIVER PROFILE UI (dynamic, no mock data)
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: getProportionateScreenHeight(24)),
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: getProportionateScreenWidth(110),
                                height: getProportionateScreenWidth(110),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: getProportionateScreenWidth(4),
                                  ),
                                ),
                                child: _profileImage != null
                                    ? ClipOval(
                                        child: Image.file(
                                          _profileImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: getProportionateScreenWidth(60),
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
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
                                      size: getProportionateScreenWidth(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(20)),
                        Text(
                          _capitalizeNames(user.name),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(6)),
                        Text(
                          'Driver ID: ${user.driverId ?? '-'}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.secondaryTextColor,
                                  ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(16)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(32)),
                          child: Column(
                            children: [
                              _buildDriverInfoField(
                                  'License Number', user.licenseNumber ?? '-'),
                              SizedBox(
                                  height: getProportionateScreenHeight(12)),
                              _buildDriverInfoField('License Expiration',
                                  user.licenseExpiration ?? '-'),
                            ],
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(24)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(32)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Status',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(10)),
                              Row(
                                children: [
                                  Text(
                                    'Availability:',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  SizedBox(
                                      width: getProportionateScreenWidth(10)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          getProportionateScreenWidth(16),
                                      vertical: getProportionateScreenHeight(6),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[400],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Busy', // You can update this if you add availability to User
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(32)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(32)),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              minimumSize: Size(double.infinity,
                                  getProportionateScreenHeight(48)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _handleLogout(context),
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(24)),
                      ],
                    ),
                  );
                }

                // STUDENT PROFILE UI (existing)
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(context, user),
                      _buildProfileStats(context),
                      _buildProfileMenu(context),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.lightTheme.dividerTheme.color!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: getProportionateScreenWidth(70),
                height: getProportionateScreenWidth(70),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: getProportionateScreenWidth(3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: getProportionateScreenWidth(8),
                      spreadRadius: getProportionateScreenWidth(0),
                    ),
                  ],
                ),
                child: _profileImage != null
                    ? ClipOval(
                        child: Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : (user.profileImage != null &&
                            user.profileImage!.isNotEmpty)
                        ? ClipOval(
                            child: Image.network(
                              user.profileImage! +
                                  '?v=${DateTime.now().millisecondsSinceEpoch}',
                              key: ValueKey(user.profileImage),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                Icons.person_outline,
                                size: getProportionateScreenWidth(35),
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person_outline,
                            size: getProportionateScreenWidth(35),
                            color: AppTheme.primaryColor,
                          ),
              ),
              SizedBox(width: getProportionateScreenWidth(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _capitalizeNames(user.name),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _handleEditProfile(context, user),
                          icon: Icon(
                            Icons.edit_outlined,
                            color: AppTheme.primaryColor,
                            size: getProportionateScreenWidth(20),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: getProportionateScreenHeight(4)),
                    Text(
                      'Student ID: ${user.studentId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(4)),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats(BuildContext context) {
    final reservationService = context.watch<ReservationService>();
    final currentReservations =
        reservationService.getCurrentReservations() ?? [];
    final reservationHistory = reservationService.getReservationHistory() ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: getProportionateScreenHeight(16),
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.lightTheme.dividerTheme.color!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Current\nReservations',
              currentReservations.length.toString(),
              Icons.event_seat_outlined,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Past\nReservations',
              reservationHistory.length.toString(),
              Icons.history_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: getProportionateScreenWidth(24),
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryColor,
              ),
        ),
        SizedBox(height: getProportionateScreenHeight(4)),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.cardColor,
      child: Column(
        children: [
          _buildMenuItem(
            context,
            'Personal Information',
            Icons.person_outline,
            () => _handleEditProfile(
                context, context.read<AuthService>().currentUser!),
          ),
          _buildMenuItem(
            context,
            'Change Password',
            Icons.lock_outline,
            () => _handleChangePassword(context),
          ),
          _buildMenuItem(
            context,
            'Notification Settings',
            Icons.notifications_outlined,
            () => _handleNotificationSettings(context),
          ),
          _buildMenuItem(
            context,
            'Payment Methods',
            Icons.payment_outlined,
            () => _handlePaymentMethods(context),
          ),
          _buildMenuItem(
            context,
            'Payment History',
            Icons.history_outlined,
            () => _handlePaymentHistory(context),
          ),
          _buildMenuItem(
            context,
            'Help & Support',
            Icons.help_outline,
            () => _handleHelpSupport(context),
          ),
          _buildMenuItem(
            context,
            'About',
            Icons.info_outline,
            () => _handleAbout(context),
          ),
          _buildMenuItem(
            context,
            'Logout',
            Icons.logout,
            () => _handleLogout(context),
            textColor: AppTheme.lightTheme.colorScheme.error,
            iconColor: AppTheme.lightTheme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(20),
          vertical: getProportionateScreenHeight(16),
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.lightTheme.dividerTheme.color!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppTheme.primaryColor,
              size: getProportionateScreenWidth(24),
            ),
            SizedBox(width: getProportionateScreenWidth(16)),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor ?? AppTheme.primaryColor,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textColor ?? AppTheme.primaryColor,
              size: getProportionateScreenWidth(24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoField(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            color: AppTheme.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: getProportionateScreenWidth(10)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
