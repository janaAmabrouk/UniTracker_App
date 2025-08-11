import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unitracker/models/user.dart' as app_user;
import 'supabase_service.dart';
import 'dart:io';

class AuthService extends ChangeNotifier {
  app_user.User? _currentUser;
  bool _isLoading = false;
  final SupabaseService _supabaseService = SupabaseService.instance;
  StreamSubscription<AuthState>? _authStateSubscription;

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _initializeAuth();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authStateSubscription =
        _supabaseService.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      debugPrint(
          '🔐 AuthService: Auth state changed - Event: $event, Session: ${session?.user?.id}');

      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        debugPrint(
            '🔐 AuthService: User signed in, loading profile for: ${session!.user.id}');
        _loadUserProfile(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('🔐 AuthService: User signed out, clearing current user');
        _currentUser = null;
        notifyListeners();
      } else if (event == AuthChangeEvent.tokenRefreshed &&
          session?.user != null) {
        debugPrint(
            '🔐 AuthService: Token refreshed, ensuring profile is loaded for: ${session!.user.id}');
        if (_currentUser == null) {
          _loadUserProfile(session.user.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    final supabaseUser = _supabaseService.currentUser;
    if (supabaseUser != null) {
      debugPrint(
          '🔐 AuthService: Initializing with existing user: ${supabaseUser.id}');
      await _loadUserProfile(supabaseUser.id);
    } else {
      debugPrint(
          '🔐 AuthService: No existing user found during initialization');
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      debugPrint('🔐 AuthService: Loading user profile for ID: $userId');
      final profileData = await _supabaseService.getUserProfile(userId);
      if (profileData != null) {
        _currentUser = app_user.User.fromSupabase(profileData);
        debugPrint('✅ AuthService: User profile loaded: ${_currentUser?.name}');
        notifyListeners();
      } else {
        debugPrint('❌ AuthService: No profile data found for user: $userId');
        _currentUser = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ AuthService: Error loading user profile: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String loginEmail = email;

      // For driver login, convert driver ID to email format
      if (!email.contains('@')) {
        // This is a driver ID, convert to email format
        loginEmail = '${email.toLowerCase()}@unitracker.driver';
      }

      debugPrint('🔐 AuthService: Attempting login with email: $loginEmail');

      final response = await _supabaseService.signIn(
        email: loginEmail,
        password: password,
      );

      // Debug prints for troubleshooting
      debugPrint('Sign in response user: [32m${response.user}[0m');
      debugPrint('Sign in response: [31m${response.toString()}[0m');
      debugPrint(
          'Supabase currentUser after sign in: [34m${_supabaseService.client.auth.currentUser}[0m');

      if (response.user != null) {
        // Check if user profile exists in your app database
        final profileData =
            await _supabaseService.getUserProfile(response.user!.id);
        if (profileData == null) {
          // Profile is missing, log out and show error
          await _supabaseService.signOut();
          throw Exception(
              'Your account has been deleted. Please contact support.');
        }
        await _loadUserProfile(response.user!.id);
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      debugPrint('❌ AuthService: Login failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String studentId,
    required String university,
    required String department,
    required String password,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'role': 'student',
        },
      );

      if (response.user != null) {
        // Create user profile in the users table
        await _supabaseService.createUserProfile({
          'id': response.user!.id,
          'email': email,
          'full_name': name,
          'role': 'student',
          'student_id': studentId,
          'university': university,
          'department': department,
          'is_active': true,
          'phone_number': phoneNumber,
        });

        await _loadUserProfile(response.user!.id);
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpDriver({
    required String name,
    required String driverId,
    required String licenseNumber,
    required DateTime licenseExpirationDate,
    required String licenseImagePath,
    required String password,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if driver already exists in the database (admin-created)
      final existingDriver = await _supabaseService.client
          .from('drivers')
          .select('*')
          .eq('driver_id', driverId)
          .maybeSingle();

      if (existingDriver != null) {
        debugPrint(
            '🚗 AuthService: Found existing driver record for ID: $driverId');

        // Check if this driver already has an auth account
        final existingUser = await _supabaseService.client
            .from('users')
            .select('*')
            .eq('driver_id', driverId)
            .maybeSingle();

        if (existingUser != null) {
          throw Exception(
              'Driver account already exists. Please log in instead.');
        }

        // Create auth account for existing driver
        final driverEmail = '${driverId.toLowerCase()}@unitracker.driver';

        final response = await _supabaseService.signUp(
          email: driverEmail,
          password: password,
          data: {
            'full_name': existingDriver['full_name'] ?? name,
            'role': 'driver',
          },
        );

        if (response.user != null) {
          // Update the existing driver record with auth user ID
          await _supabaseService.client
              .from('drivers')
              .update({'id': response.user!.id, 'phone': phoneNumber}).eq(
                  'driver_id', driverId);

          // Create user profile linking to existing driver data
          await _supabaseService.createUserProfile({
            'id': response.user!.id,
            'full_name': existingDriver['full_name'] ?? name,
            'role': 'driver',
            'driver_license': existingDriver['driver_license'] ?? licenseNumber,
            'license_expiry': existingDriver['license_expiry'] ??
                licenseExpirationDate.toIso8601String().split('T')[0],
            'is_active': existingDriver['is_active'] ?? true,
            'phone_number': phoneNumber ?? existingDriver['phone'],
            'driver_id': driverId,
          });

          debugPrint(
              '✅ AuthService: Linked existing driver record to new auth account');
          await _loadUserProfile(response.user!.id);
        } else {
          debugPrint(
              '❌ AuthService: Supabase signUp returned a null user. This usually means the user already exists or requires email confirmation.');
          throw Exception(
              'Signup failed. The driver ID or email might already be taken. Please try another one or log in if you have an account.');
        }
      } else {
        // Create new driver (self-signup flow)
        debugPrint(
            '🚗 AuthService: Creating new driver account for ID: $driverId');

        // For drivers, we'll use a generated email based on driver ID
        final driverEmail = '${driverId.toLowerCase()}@unitracker.driver';

        final response = await _supabaseService.signUp(
          email: driverEmail,
          password: password,
          data: {
            'full_name': name,
            'role': 'driver',
          },
        );

        if (response.user == null) {
          debugPrint(
              '❌ AuthService: Supabase signUp returned a null user. This usually means the user already exists or requires email confirmation.');
          throw Exception(
              'Signup failed. The driver ID or email might already be taken. Please try another one or log in if you have an account.');
        }

        debugPrint(
            '✅ AuthService: Auth account created successfully for user: ${response.user!.id}');

        // Create driver profile in the users table
        final userProfileData = {
          'id': response.user!.id,
          'full_name': name,
          'role': 'driver',
          'driver_license': licenseNumber,
          'license_expiry':
              licenseExpirationDate.toIso8601String().split('T')[0],
          'is_active': true,
          'driver_id': driverId,
          'phone_number': phoneNumber,
        };

        debugPrint(
            '🔥 AuthService: Creating user profile with data: $userProfileData');
        await _supabaseService.createUserProfile(userProfileData);

        // Also create or upsert a record in the drivers table for admin panel and profile screen
        final driverRecordData = {
          'id': response.user!.id,
          'full_name': name,
          'driver_license': licenseNumber,
          'license_expiry':
              licenseExpirationDate.toIso8601String().split('T')[0],
          'driver_id': driverId,
          'is_active': true,
          'phone': phoneNumber,
          'license_image_path': licenseImagePath,
        };

        debugPrint(
            '🔥 AuthService: Upserting driver record with data: $driverRecordData');
        await _supabaseService.client.from('drivers').upsert(driverRecordData);
        debugPrint('✅ AuthService: Driver record upserted successfully.');

        await _loadUserProfile(response.user!.id);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _currentUser = null;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? studentId,
    String? university,
    String? department,
    String? profileImage,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['full_name'] = name;
      if (email != null) updateData['email'] = email;
      if (studentId != null) updateData['student_id'] = studentId;
      if (university != null && university.trim().isNotEmpty)
        updateData['university'] = university.trim();
      if (department != null) updateData['department'] = department;
      if (profileImage != null) updateData['profile_image_url'] = profileImage;

      debugPrint('Updating user with data: ' + updateData.toString());
      // Update profile in Supabase
      final response = await _supabaseService.client
          .from('users')
          .update(updateData)
          .eq('id', _currentUser!.id)
          .select()
          .single();
      debugPrint('Update response: ' + response.toString());

      if (response == null) {
        throw Exception('Failed to update profile');
      }

      // Update local user data
      _currentUser = app_user.User(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
        studentId: studentId ?? _currentUser!.studentId,
        university: university ?? _currentUser!.university,
        department: department ?? _currentUser!.department,
        role: _currentUser!.role,
        profileImage: profileImage ?? _currentUser!.profileImage,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception("User not authenticated.");
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Store current user info
      final currentEmail = _currentUser!.email;
      final userId = _currentUser!.id;

      // Step 1: Verify the current password by signing in.
      // This provides both verification and a new, valid session for the next step.
      final signInResponse =
          await _supabaseService.client.auth.signInWithPassword(
        email: currentEmail,
        password: currentPassword,
      );

      if (signInResponse.user == null || signInResponse.session == null) {
        // This case should be caught by the exception below, but as a safeguard:
        throw Exception('Incorrect current password.');
      }

      // Step 2: With the new valid session from the sign-in, update the password.
      await _supabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // Step 3: Reload the user's profile to ensure the app state is correct.
      await _loadUserProfile(userId);
    } catch (e) {
      // Check for specific auth errors that indicate a wrong password
      if (e is AuthException && e.statusCode == '400') {
        throw Exception('Incorrect current password.');
      }
      // Rethrow other exceptions to be handled by the UI
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String email,
    required String driverId,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔐 AuthService: Initiating password reset for $role');

      if (role == 'student') {
        // Validate email format
        if (!email.contains('@') || !email.contains('.')) {
          throw Exception('Please enter a valid email address');
        }

        // Check if student exists in database
        final studentCheck = await _supabaseService.client
            .from('users')
            .select('id, email')
            .eq('email', email)
            .eq('role', 'student')
            .maybeSingle();

        if (studentCheck == null) {
          throw Exception('No student account found with this email address');
        }

        // Send password reset email using Supabase Auth
        try {
          await _supabaseService.client.auth.resetPasswordForEmail(
            email,
            redirectTo:
                'https://fsdopmaaeqkxmirbvheu.supabase.co/auth/v1/verify',
          );
        } catch (authError) {
          debugPrint('❌ AuthService: Password reset error: $authError');
          throw Exception('Failed to send reset email: $authError');
        }

        debugPrint(
            '✅ AuthService: Password reset email sent successfully to $email');
      } else if (role == 'driver') {
        // Validate driver ID
        if (driverId.isEmpty) {
          throw Exception('Please enter your driver ID');
        }

        // Check if driver exists in database
        final driverCheck = await _supabaseService.client
            .from('drivers')
            .select('id, driver_id')
            .eq('driver_id', driverId)
            .maybeSingle();

        if (driverCheck == null) {
          throw Exception('No driver account found with this ID');
        }

        final driverEmail = driverCheck['email'] as String?;
        if (driverEmail == null || driverEmail.isEmpty) {
          throw Exception(
              'No email associated with this driver account. Please contact admin.');
        }

        // Send password reset email for driver
        try {
          await _supabaseService.client.auth.resetPasswordForEmail(
            driverEmail,
            redirectTo:
                'https://fsdopmaaeqkxmirbvheu.supabase.co/auth/v1/verify',
          );
        } catch (authError) {
          debugPrint('❌ AuthService: Driver password reset error: $authError');
          throw Exception('Failed to send reset email: $authError');
        }

        debugPrint(
            '✅ AuthService: Password reset email sent successfully to driver email');
      }
    } catch (e) {
      debugPrint('❌ AuthService: Password reset failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔐 AuthService: Updating user password');

      // Validate password
      if (newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }

      if (newPassword != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      // Update password using Supabase Auth
      try {
        await _supabaseService.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } catch (authError) {
        debugPrint('❌ AuthService: Password update error: $authError');
        throw Exception('Failed to update password: $authError');
      }

      debugPrint('✅ AuthService: Password updated successfully');
    } catch (e) {
      debugPrint('❌ AuthService: Password update failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateUserProfile(userId, data);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      return await _supabaseService.getUserProfile(userId);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> createUserProfile(Map<String, dynamic> data) async {
    await _supabaseService.createUserProfile(data);
  }

  Future<String> uploadProfileImage(String userId, String imagePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint(
          '📸 AuthService: Starting profile image upload for user: $userId');

      // Validate input parameters
      if (userId.isEmpty) {
        throw Exception('User ID is required for profile image upload');
      }

      if (imagePath.isEmpty) {
        throw Exception('Image path is required for profile image upload');
      }

      final fileExtension = imagePath.split('.').last.toLowerCase();
      final fileName = '${userId}.${fileExtension}';
      // Use just the filename as the storage path, not the full path
      final storagePath = fileName;

      debugPrint('📸 AuthService: Uploading to path: $storagePath');
      debugPrint('📸 AuthService: File extension: $fileExtension');

      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file does not exist at path: $imagePath');
      }

      // Check file size (limit to 5MB)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image file size must be less than 5MB');
      }

      // Validate file extension
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!allowedExtensions.contains(fileExtension)) {
        throw Exception(
            'Invalid file type. Allowed types: ${allowedExtensions.join(', ')}');
      }

      // Upload the file to the profile-images bucket with just the filename
      final response = await _supabaseService.client.storage
          .from('profile-images')
          .upload(storagePath, file,
              fileOptions: const FileOptions(upsert: true));

      debugPrint('📸 AuthService: File uploaded successfully to: $response');

      // Get the public URL using the same filename
      final publicUrl = _supabaseService.client.storage
          .from('profile-images')
          .getPublicUrl(storagePath);

      debugPrint('📸 AuthService: Generated public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      debugPrint('❌ AuthService: Error uploading profile image: $e');

      // Provide specific error messages based on the error type
      if (e.toString().contains('row-level security policy')) {
        throw Exception(
            'Permission denied: Please make sure you have the correct storage policies set up in Supabase. Check the PROFILE_IMAGE_SETUP.md file for setup instructions.');
      } else if (e.toString().contains('bucket')) {
        throw Exception(
            'Storage bucket not found: Please ensure the "profile-images" bucket exists in your Supabase project.');
      } else if (e.toString().contains('network')) {
        throw Exception(
            'Network error: Please check your internet connection and try again.');
      } else if (e.toString().contains('authentication')) {
        throw Exception(
            'Authentication error: Please log in again and try uploading the image.');
      } else {
        throw Exception('Failed to upload profile image: ${e.toString()}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
