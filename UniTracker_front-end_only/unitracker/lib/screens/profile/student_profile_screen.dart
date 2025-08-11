import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitracker/utils/responsive_utils.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/providers/auth_provider.dart';
import 'package:unitracker/services/auth_service.dart';
import 'package:unitracker/services/reservation_service.dart';
import 'package:unitracker/screens/auth/login_screen.dart';
import 'package:unitracker/models/user.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:unitracker/services/notification_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unitracker/services/payment_history_service.dart';
import 'package:unitracker/services/supabase_service.dart';
import 'package:unitracker/screens/profile/input_formatters.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/payment_history.dart';
import 'notification_settings_dialog.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  List<Map<String, String>> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
    // Load user profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.loadUserProfile();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

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
            child: authProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : user == null
                    ? Center(
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
                                    builder: (_) => const LoginScreen(
                                        initialRole: 'student'),
                                  ),
                                );
                              },
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUserProfile,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              _buildProfileHeader(context),
                              _buildProfileStats(context),
                              _buildProfileMenu(context),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    print('Profile image URL: [32m${user?.profileImage}[0m');
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
                child: (user != null &&
                        user.profileImage != null &&
                        user.profileImage!.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          user.profileImage! +
                              '?v=${DateTime.now().millisecondsSinceEpoch}',
                          key: ValueKey(user.profileImage),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
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
                            user != null ? _capitalizeNames(user.name) : '',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _handleEditProfile(context, user!),
                          icon: Icon(
                            Icons.edit_outlined,
                            color: AppTheme.primaryColor,
                            size: getProportionateScreenWidth(20),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: getProportionateScreenHeight(4)),
                    Text(
                      'Student ID: ${user?.studentId ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(4)),
                    Text(
                      user?.email ?? '',
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
                context, context.read<AuthProvider>().currentUser!),
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

  String _capitalizeNames(String name) {
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _handleEditProfile(BuildContext context, User user) {
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
          child: _EditProfileBottomSheet(user: user),
        ),
      ),
    );
  }

  void _handleChangePassword(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? currentPasswordError;
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(16),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(getProportionateScreenWidth(33)),
                ),
                padding: EdgeInsets.fromLTRB(
                  getProportionateScreenWidth(24),
                  getProportionateScreenHeight(24),
                  getProportionateScreenWidth(24),
                  getProportionateScreenHeight(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      SizedBox(height: getProportionateScreenHeight(24)),
                      Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: currentPasswordController,
                              obscureText: obscureCurrentPassword,
                              onChanged: (_) {
                                if (currentPasswordError != null) {
                                  setState(() {
                                    currentPasswordError = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                hintText: 'Enter your current password',
                                errorText: currentPasswordError,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureCurrentPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscureCurrentPassword =
                                          !obscureCurrentPassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12)),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your current password.';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(16)),
                            TextFormField(
                              controller: newPasswordController,
                              obscureText: obscureNewPassword,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                hintText: 'Enter your new password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureNewPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscureNewPassword = !obscureNewPassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12)),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a new password.';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters long.';
                                }
                                if (value == currentPasswordController.text) {
                                  return 'New password must be different from the old one.';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getProportionateScreenHeight(16)),
                            TextFormField(
                              controller: confirmPasswordController,
                              obscureText: obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password',
                                hintText: 'Confirm your new password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscureConfirmPassword =
                                          !obscureConfirmPassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12)),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your new password.';
                                }
                                if (value != newPasswordController.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(16)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          SizedBox(width: getProportionateScreenWidth(8)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    getProportionateScreenWidth(33)),
                              ),
                            ),
                            onPressed: () async {
                              // Clear previous server error when attempting to submit again
                              if (currentPasswordError != null) {
                                setState(() {
                                  currentPasswordError = null;
                                });
                              }
                              if (formKey.currentState!.validate()) {
                                try {
                                  final authProvider =
                                      context.read<AuthProvider>();
                                  await authProvider.changePassword(
                                    currentPassword:
                                        currentPasswordController.text,
                                    newPassword: newPasswordController.text,
                                  );
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Password changed successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (dialogContext.mounted) {
                                    setState(() {
                                      currentPasswordError =
                                          'Incorrect current password.';
                                    });
                                  }
                                }
                              }
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleNotificationSettings(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final notificationSettingsService = NotificationSettingsService(prefs);
    // Force reload from Supabase to get the latest settings
    await notificationSettingsService.reloadFromSupabase();
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
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              SizedBox(
                                  height: getProportionateScreenHeight(24)),
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
                                    border:
                                        Border.all(color: Colors.grey[300]!),
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
                                          width:
                                              getProportionateScreenWidth(16)),
                                      Text(
                                        'Add New Card',
                                        style: TextStyle(
                                          fontSize:
                                              getProportionateScreenWidth(16),
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_cards.isNotEmpty) ...[
                                SizedBox(
                                    height: getProportionateScreenHeight(24)),
                                Text(
                                  'Saved Cards',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(16)),
                                ..._cards.asMap().entries.map((entry) =>
                                    Padding(
                                      padding: EdgeInsets.only(
                                          bottom:
                                              getProportionateScreenHeight(8)),
                                      child: _buildSavedCard(
                                        context,
                                        entry.value['cardNumber'] ?? '',
                                        '${entry.value['cardType'] ?? 'Card'} • Expires ${entry.value['expiryMonth'] ?? ''}/${entry.value['expiryYear']?.substring(2) ?? ''}',
                                        _getCardTypeIcon(
                                            entry.value['cardType'] ?? ''),
                                        isDefault:
                                            entry.value['isDefault'] == 'true',
                                        onRemove: () {
                                          _removeCard(entry.key).then((_) {
                                            setState(
                                                () {}); // Rebuild the bottom sheet
                                          });
                                        },
                                        onSetDefault: () {
                                          _setDefaultCard(entry.key).then((_) {
                                            setState(
                                                () {}); // Rebuild the bottom sheet
                                          });
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
                                    height: getProportionateScreenHeight(8)),
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Card Holder Name',
                                    hintText: 'John Doe',
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
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
                                            color: AppTheme.secondaryTextColor,
                                            fontSize:
                                                getProportionateScreenWidth(14),
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
                                                debugPrint(
                                                    'Save button pressed. University: ' +
                                                        _universityController
                                                            .text +
                                                        ', Phone: ' +
                                                        _phoneNumberController
                                                            .text);
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
                          if (recentPayments.isNotEmpty) ...[
                            Text(
                              'Recent Transactions',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(16)),
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: getProportionateScreenHeight(400),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: recentPayments.length,
                                itemBuilder: (context, index) {
                                  final payment = recentPayments[index];
                                  return _buildPaymentHistoryItem(payment);
                                },
                              ),
                            ),
                          ] else ...[
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
                          _buildFaqItem(
                            context,
                            'How do I make a reservation?',
                            'Go to the \'Schedules\' screen, select your desired route and time, and tap \'Reserve Seat\'. You can see your active reservations on the \'Reservations\' screen.',
                          ),
                          _buildFaqItem(
                            context,
                            'Can I track the bus in real-time?',
                            'Yes! Once a trip is active, you can go to the \'Home\' or \'Map\' screen to see the live location of your bus.',
                          ),
                          _buildFaqItem(
                            context,
                            'How do I cancel a reservation?',
                            'You can cancel a reservation from the \'Reservations\' screen. Please note that cancellations may be subject to a deadline, typically 1 hour before the scheduled departure.',
                          ),
                          _buildFaqItem(
                            context,
                            'How can I manage my notifications?',
                            'You can customize your notification preferences from your profile. Tap on \'Notification Settings\' to enable or disable alerts for route delays, reservation updates, and schedule changes.',
                          ),
                          _buildFaqItem(
                            context,
                            'Is my payment information secure?',
                            'We take your security seriously. Your payment card information is securely handled and is not stored directly on our servers. We use a trusted, PCI-compliant payment processor.',
                          ),
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

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
          ),
        ],
      ),
    );
  }

  void _handleAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(getProportionateScreenWidth(20)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/bus_logo.png',
              height: getProportionateScreenHeight(60),
            ),
            SizedBox(height: getProportionateScreenHeight(16)),
            Text(
              'UniTracker',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: getProportionateScreenHeight(4)),
            const Text('Version 1.0.0'),
            SizedBox(height: getProportionateScreenHeight(16)),
            Text(
              'A university bus tracking and reservation system designed to help students and staff manage their daily commute efficiently.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: getProportionateScreenHeight(24)),
            Text(
              '© 2024 UniTracker. All Rights Reserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
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
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => const LoginScreen(initialRole: 'student')),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
}

// New StatefulWidget for the Edit Profile Bottom Sheet
class _EditProfileBottomSheet extends StatefulWidget {
  final User user;

  const _EditProfileBottomSheet({Key? key, required this.user})
      : super(key: key);

  @override
  __EditProfileBottomSheetState createState() =>
      __EditProfileBottomSheetState();
}

class __EditProfileBottomSheetState extends State<_EditProfileBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _studentIdController;
  late TextEditingController _universityController;
  late TextEditingController _departmentController;
  late TextEditingController _phoneNumberController;
  File? _profileImage; // Local state for the selected image
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _studentIdController = TextEditingController(text: widget.user.studentId);
    _universityController = TextEditingController(text: widget.user.university);
    _departmentController = TextEditingController(text: widget.user.department);
    _phoneNumberController =
        TextEditingController(text: widget.user.phoneNumber ?? '');
    // _profileImage should only be set when a new image is picked from local storage.
    // We do NOT initialize it with a network URL here.
    _profileImage = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      debugPrint('Picked image: \\${pickedFile.path}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Picked image, starting upload...')),
        );
      }
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      // Upload image to Supabase Storage and update profile
      try {
        final authProvider = context.read<AuthProvider>();
        debugPrint(
            'DEBUG: _getImage - authProvider.isAuthenticated: \\${authProvider.isAuthenticated}');
        debugPrint(
            'DEBUG: _getImage - authProvider.currentUser.id: \\${authProvider.currentUser?.id}');
        final imageUrl = await authProvider.uploadProfileImage(
            widget.user.id, pickedFile.path);

        // Update profile with the new image URL and existing text field values
        debugPrint('Sending university to updateProfile: ' +
            _universityController.text);
        await authProvider.updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          studentId: _studentIdController.text,
          university: _universityController.text,
          department: _departmentController.text,
          profileImage: imageUrl,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image updated successfully')),
          );
        }
      } catch (e) {
        debugPrint('Upload error: \\${e.toString()}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to upload profile image: \\${e.toString()}')),
          );
        }
      }
    } else {
      debugPrint('No image picked.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(getProportionateScreenWidth(33)),
        ),
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
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: getProportionateScreenWidth(100),
                            height: getProportionateScreenWidth(100),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: getProportionateScreenWidth(1),
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
                                : (widget.user.profileImage != null &&
                                        widget.user.profileImage!.isNotEmpty)
                                    ? ClipOval(
                                        child: Image.network(
                                          widget.user.profileImage! +
                                              '?v=${DateTime.now().millisecondsSinceEpoch}',
                                          key: ValueKey(
                                              widget.user.profileImage),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                            Icons.person_outline,
                                            size:
                                                getProportionateScreenWidth(50),
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person_outline,
                                        size: getProportionateScreenWidth(50),
                                        color: AppTheme.primaryColor,
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
                      controller: _nameController,
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
                      controller: _emailController,
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
                      controller: _studentIdController,
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
                      controller: _universityController,
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
                      controller: _departmentController,
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
                    SizedBox(height: getProportionateScreenHeight(16)),
                    TextField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
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
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(
                        height: getProportionateScreenHeight(
                            32)), // Space before buttons
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
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              debugPrint('Save button pressed. University: ' +
                                  _universityController.text +
                                  ', Phone: ' +
                                  _phoneNumberController.text);
                              try {
                                final authProvider =
                                    context.read<AuthProvider>();
                                await authProvider.updateProfile(
                                  name: _capitalizeNames(_nameController.text),
                                  email: _emailController.text,
                                  studentId: _studentIdController.text,
                                  university: _universityController.text,
                                  department: _departmentController.text,
                                  phoneNumber: _phoneNumberController.text,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  await authProvider
                                      .loadUserProfile(); // Reload profile data
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Profile updated successfully'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Failed to update profile: $e'),
                                    ),
                                  );
                                }
                              }
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
    );
  }

  String _capitalizeNames(String name) {
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
