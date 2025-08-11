import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send welcome email to new driver with setup instructions
  Future<void> sendWelcomeEmail({
    required String fullName,
    required String driverId,
  }) async {
    try {
      // For now, we'll use Supabase's built-in email functionality
      // In a production environment, you'd integrate with a proper email service

      // Create a simple email template
      final subject = 'Welcome to UniTracker - Driver Account Setup';
      final body = '''
Dear $fullName,

Welcome to UniTracker! Your driver account has been created successfully.

Your Driver ID: $driverId

To complete your account setup and access the mobile app:

1. Download the UniTracker mobile app from your app store
2. Open the app and select "Driver" role
3. Choose "Sign Up"
4. Enter your Driver ID: $driverId
5. Create a secure password of your choice
6. Complete the signup process

Once you've completed the signup, you'll be able to:
- View your assigned routes and schedules
- Track your trips and performance
- Receive real-time updates and notifications
- Access your driver dashboard

If you have any questions or need assistance, please contact the admin team.

Best regards,
The UniTracker Team
      ''';

      // For development, we'll just print the email
      // In production, you'd send this via a proper email service
      print('📧 WELCOME EMAIL (DRIVER)');
      print('📧 SUBJECT: $subject');
      print('📧 BODY:');
      print(body);
      print('📧 END EMAIL');

      // TODO: Integrate with actual email service (SendGrid, AWS SES, etc.)
    } catch (e) {
      print('❌ Error sending welcome email: $e');
      // Don't throw here as the driver creation was successful
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({
    required String email,
    required String resetLink,
  }) async {
    try {
      final subject = 'UniTracker - Password Reset Request';
      final body = '''
Hello,

You have requested to reset your password for your UniTracker account.

Click the link below to reset your password:
$resetLink

If you didn't request this password reset, please ignore this email.

This link will expire in 24 hours.

Best regards,
The UniTracker Team
      ''';

      print('📧 PASSWORD RESET EMAIL SENT TO: $email');
      print('📧 SUBJECT: $subject');
      print('📧 RESET LINK: $resetLink');

      // TODO: Integrate with actual email service
    } catch (e) {
      print('❌ Error sending password reset email: $e');
      rethrow;
    }
  }

  /// Send account activation email
  Future<void> sendAccountActivationEmail({
    required String email,
    required String fullName,
    required String activationLink,
  }) async {
    try {
      final subject = 'UniTracker - Activate Your Account';
      final body = '''
Dear $fullName,

Welcome to UniTracker! Please activate your account by clicking the link below:

$activationLink

Once activated, you'll be able to access all features of the UniTracker platform.

Best regards,
The UniTracker Team
      ''';

      print('📧 ACCOUNT ACTIVATION EMAIL SENT TO: $email');
      print('📧 SUBJECT: $subject');
      print('📧 ACTIVATION LINK: $activationLink');

      // TODO: Integrate with actual email service
    } catch (e) {
      print('❌ Error sending activation email: $e');
      rethrow;
    }
  }
}
