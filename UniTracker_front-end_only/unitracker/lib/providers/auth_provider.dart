import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService.instance;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  AuthProvider() {
    _loadUserFromPrefs();
    // Listen to AuthService changes
    _authService.addListener(_onAuthServiceChanged);
    // Also check if AuthService has a current user with a delay to allow AuthService to initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure AuthService has time to initialize
      Future.delayed(const Duration(milliseconds: 500), () {
        refreshUserSession();
      });
    });
  }

  void _onAuthServiceChanged() {
    _syncWithAuthService();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthServiceChanged);
    super.dispose();
  }

  Future<void> _syncWithAuthService() async {
    try {
      final authServiceUser = _authService.currentUser;
      debugPrint(
          'AuthProvider: _syncWithAuthService - AuthService user: ${authServiceUser?.name ?? 'null'}');
      debugPrint(
          'AuthProvider: _syncWithAuthService - Current user: ${_currentUser?.name ?? 'null'}');

      if (authServiceUser != null) {
        debugPrint(
            'AuthProvider: Syncing with AuthService user: ${authServiceUser.name}');

        // If we don't have a current user or the IDs don't match, update our user
        if (_currentUser == null || _currentUser!.id != authServiceUser.id) {
          _currentUser = authServiceUser;
          await _saveUserToPrefs();

          notifyListeners();
        }
      } else {
        debugPrint(
            'AuthProvider: No user in AuthService, clearing current user');
        // If AuthService has no user, clear our user too
        if (_currentUser != null) {
          _currentUser = null;
          await _saveUserToPrefs();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('AuthProvider: Error syncing with AuthService: $e');
    }
  }

  Future<void> _loadUserFromPrefs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final role = prefs.getString('role') ?? '';
      final userName = prefs.getString('userName') ?? '';
      final userEmail = prefs.getString('userEmail') ?? '';
      final studentId = prefs.getString('studentId') ?? '';
      final university = prefs.getString('university') ?? '';
      final department = prefs.getString('department') ?? '';
      final profileImage = prefs.getString('profileImage');
      final driverId = prefs.getString('driverId');
      final licenseNumber = prefs.getString('licenseNumber');
      final licenseExpiration = prefs.getString('licenseExpiration');

      // Check if we have valid user data
      if (userId.isNotEmpty &&
          role.isNotEmpty &&
          userName.isNotEmpty &&
          userEmail.isNotEmpty) {
        // Validate that the stored user data matches the current Supabase session
        final supabaseUser = _supabaseService.currentUser;
        if (supabaseUser != null && supabaseUser.id == userId) {
          // User data matches Supabase session, load it
          _currentUser = User(
            id: userId,
            name: userName,
            email: userEmail,
            studentId: studentId,
            university: university,
            department: department,
            role: role,
            profileImage: profileImage,
            driverId: driverId,
            licenseNumber: licenseNumber,
            licenseExpiration: licenseExpiration,
          );
          debugPrint(
              '✅ AuthProvider: Loaded user from preferences - ${_currentUser!.name} (ID: ${_currentUser!.id})');
        } else {
          // User data doesn't match Supabase session, clear it
          debugPrint(
              '⚠️ AuthProvider: Stored user data doesn\'t match Supabase session. Clearing preferences.');
          await _clearAllPrefs();
          _currentUser = null;
        }
      } else {
        debugPrint('ℹ️ AuthProvider: No valid user data found in preferences');
      }
    } catch (e) {
      _error = 'Failed to load user data: ${e.toString()}';
      debugPrint('❌ AuthProvider: Error loading user from preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _clearAllPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('role');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('studentId');
    await prefs.remove('university');
    await prefs.remove('department');
    await prefs.remove('profileImage');
    await prefs.remove('driverId');
    await prefs.remove('licenseNumber');
    await prefs.remove('licenseExpiration');
    await prefs.remove('userRole');
    debugPrint('✅ AuthProvider: All preferences cleared');
  }

  bool _validateEmail(String email, {String? role}) {
    if (role == 'driver' && (email == null || email.isEmpty)) {
      return true;
    }
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 8;
  }

  Future<bool> login(String email, String password) async {
    if (!_validateEmail(email)) {
      _error = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }
    if (!_validatePassword(password)) {
      _error = 'Password must be at least 8 characters long';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Clear any existing user data first
      _currentUser = null;
      await _clearAllPrefs();

      // Use the real AuthService for login
      await _authService.signIn(email: email, password: password);

      // The AuthService will handle loading the user profile through its auth state listener
      // We don't need to manually get the current user here
      debugPrint(
          '✅ AuthProvider: Login request completed, waiting for auth state update');
      return true;
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      debugPrint('❌ AuthProvider: Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(
    String name,
    String email,
    String password,
    String role, {
    String? studentId,
    String? university,
    String? department,
    String? phoneNumber,
    String? driverId,
    String? licenseNumber,
    String? licenseExpiration,
    String? licenseImageUrl,
  }) async {
    if (name.isEmpty) {
      _error = 'Please enter your name';
      notifyListeners();
      return false;
    }
    if (!_validateEmail(email, role: role)) {
      _error = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }
    if (!_validatePassword(password)) {
      _error = 'Password must be at least 8 characters long';
      notifyListeners();
      return false;
    }
    if (!['student', 'driver', 'admin'].contains(role)) {
      _error = 'Invalid user role';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (role == 'student') {
        await _authService.signUp(
          name: name,
          email: email,
          studentId: studentId ?? '',
          university: university ?? '',
          department: department ?? '',
          password: password,
          phoneNumber: phoneNumber,
        );
      } else if (role == 'driver') {
        await _authService.signUpDriver(
          name: name,
          driverId: driverId ?? '',
          licenseNumber: licenseNumber ?? '',
          licenseExpirationDate:
              DateTime.tryParse(licenseExpiration ?? '') ?? DateTime.now(),
          licenseImagePath: licenseImageUrl ?? '',
          password: password,
          phoneNumber: phoneNumber,
        );
      }

      _currentUser = _authService.currentUser;
      debugPrint(
          'AuthProvider: After signup, currentUser: \\n  id: \\${_currentUser?.id}, name: \\${_currentUser?.name}, email: \\${_currentUser?.email}');
      // The AuthService will handle loading the user profile through its auth state listener
      // We don't need to manually call loadUserProfile here
      if (_currentUser == null) {
        // This handles the case where signup appears to succeed but no user is returned.
        throw Exception(
            'User registration failed. Please check your details and try again.');
      }
      await _saveUserToPrefs();
      return true;
    } catch (e) {
      debugPrint('❌ AuthProvider SignUp Error: ${e.toString()}');
      _error = e.toString();
      notifyListeners(); // Notify listeners to show the error in the UI
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // First, sign out from Supabase to clear the session
      await _authService.signOut();

      // Clear all local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('role');
      await prefs.remove('userName');
      await prefs.remove('userEmail');
      await prefs.remove('studentId');
      await prefs.remove('university');
      await prefs.remove('department');
      await prefs.remove('profileImage');
      await prefs.remove('driverId');
      await prefs.remove('licenseNumber');
      await prefs.remove('licenseExpiration');
      await prefs.remove('userRole'); // Also clear this one

      // Clear the current user
      _currentUser = null;

      debugPrint('✅ AuthProvider: User logged out successfully');

      // Navigate to login screen after a short delay to ensure all cleanup is done
      Future.delayed(const Duration(milliseconds: 100), () {
        // This will trigger a rebuild of the widget tree and the SplashScreen will handle navigation
        notifyListeners();
      });
    } catch (e) {
      _error = 'An error occurred during logout: ${e.toString()}';
      debugPrint('❌ AuthProvider: Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    if (!_validateEmail(email)) {
      _error = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (email == '21-101122@eui.edu' ||
          email == 'driver@eui.edu' ||
          email == 'admin@eui.edu') {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Email not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An error occurred during password reset: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUserProfile() async {
    try {
      final authServiceUser = _authService.currentUser;
      debugPrint(
          'AuthProvider: loadUserProfile - AuthService user: ${authServiceUser?.name ?? 'null'}');
      debugPrint(
          'AuthProvider: loadUserProfile - Current user: ${_currentUser?.name ?? 'null'}');

      String? userIdToLoad;

      if (_currentUser != null) {
        userIdToLoad = _currentUser!.id;
        debugPrint(
            'AuthProvider: Using existing _currentUser ID to load profile: $userIdToLoad');
      } else if (authServiceUser != null) {
        userIdToLoad = authServiceUser.id;
        debugPrint(
            'AuthProvider: Using AuthService user ID to load profile: $userIdToLoad');
      }

      if (userIdToLoad != null) {
        final userData = await _authService.getUserProfile(userIdToLoad);
        if (userData != null) {
          _currentUser = User.fromSupabase(userData);
          debugPrint(
              'AuthProvider: User profile loaded from database: ${_currentUser?.name}');
          await _saveUserToPrefs();
          notifyListeners();
        } else {
          debugPrint(
              'AuthProvider: No user data found in database for ID: $userIdToLoad');
          // If no data found, clear current user to prevent displaying stale data
          _currentUser = null;
          await _saveUserToPrefs();
          notifyListeners();
        }
      } else {
        debugPrint('AuthProvider: No user ID available to load profile.');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error loading user profile: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? studentId,
    String? university,
    String? department,
    String? profileImage,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update profile in Supabase
      final updateData = <String, dynamic>{};
      if (name != null) updateData['full_name'] = name;
      if (email != null) updateData['email'] = email;
      if (studentId != null) updateData['student_id'] = studentId;
      if (university != null) updateData['university'] = university;
      if (department != null) updateData['department'] = department;
      if (profileImage != null) updateData['profile_image_url'] = profileImage;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;

      await _authService.updateUserProfile(_currentUser!.id, updateData);

      // Save to local storage
      await _saveUserToPrefs();

      // Reload user profile to ensure we have the latest data
      await loadUserProfile();
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadProfileImage(String userId, String imagePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint(
          'DEBUG: AuthProvider.uploadProfileImage - _currentUser is null: ${_currentUser == null}');
      debugPrint(
          'DEBUG: AuthProvider.uploadProfileImage - _currentUser.id: ${_currentUser?.id}');
      final imageUrl = await _authService.uploadProfileImage(userId, imagePath);
      // After successful upload, also update the current user's profileImage locally
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(profileImage: imageUrl);
        await _saveUserToPrefs();
      }
      notifyListeners();
      return imageUrl;
    } catch (e) {
      _error = 'Failed to upload profile image: ${e.toString()}';
      throw Exception(_error);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user is currently logged in');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveUserToPrefs() async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _currentUser!.id);
    await prefs.setString('userName', _currentUser!.name);
    await prefs.setString('userEmail', _currentUser!.email);
    await prefs.setString('studentId', _currentUser!.studentId);
    await prefs.setString('university', _currentUser!.university);
    await prefs.setString('department', _currentUser!.department);
    await prefs.setString('role', _currentUser!.role);
    await prefs.setString('userRole', _currentUser!.role);
    if (_currentUser!.profileImage != null) {
      await prefs.setString('profileImage', _currentUser!.profileImage!);
    }
    if (_currentUser!.driverId != null) {
      await prefs.setString('driverId', _currentUser!.driverId!);
    }
    if (_currentUser!.licenseNumber != null) {
      await prefs.setString('licenseNumber', _currentUser!.licenseNumber!);
    }
    if (_currentUser!.licenseExpiration != null) {
      await prefs.setString(
          'licenseExpiration', _currentUser!.licenseExpiration!);
    }

    debugPrint(
        '✅ AuthProvider: User data saved to preferences - ID: ${_currentUser!.id}, Name: ${_currentUser!.name}');
  }

  Future<void> refreshUserSession() async {
    try {
      debugPrint('🔄 AuthProvider: Refreshing user session...');

      // Clear current user data
      _currentUser = null;

      // Check if there's a valid Supabase session
      final supabaseUser = _supabaseService.currentUser;
      if (supabaseUser != null) {
        // Load fresh user data from database
        await loadUserProfile();
        debugPrint(
            '✅ AuthProvider: User session refreshed - ${_currentUser?.name ?? 'null'}');
      } else {
        // No valid session, clear all data
        await _clearAllPrefs();
        debugPrint('ℹ️ AuthProvider: No valid session found, cleared all data');
      }
    } catch (e) {
      debugPrint('❌ AuthProvider: Error refreshing user session: $e');
    }
  }
}
