import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  AuthProvider() {
    _loadUserFromPrefs();
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
      if (userId.isNotEmpty &&
          role.isNotEmpty &&
          userName.isNotEmpty &&
          userEmail.isNotEmpty) {
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
      }
    } catch (e) {
      _error = 'Failed to load user data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _validateEmail(String email, {String? role}) {
    if (role == 'driver' && (email == null || email.isEmpty)) {
      return true;
    }
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  Future<bool> login(String email, String password) async {
    if (!_validateEmail(email)) {
      _error = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }
    if (!_validatePassword(password)) {
      _error = 'Password must be at least 6 characters long';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (email == 'user@example.com' && password == 'password') {
        _currentUser = User(
          id: '1',
          name: 'John Doe',
          email: email,
          studentId: '',
          university: '',
          department: '',
          role: 'student',
          profileImage: null,
        );
      } else if (email == 'driver@example.com' && password == 'password') {
        _currentUser = User(
          id: '2',
          name: 'Driver User',
          email: email,
          studentId: '',
          university: '',
          department: '',
          role: 'driver',
          profileImage: null,
          driverId: 'DRV-12345',
          licenseNumber: 'LIC-987654',
          licenseExpiration: '2025-12-31',
        );
      } else if (email == 'admin@example.com' && password == 'password') {
        _currentUser = User(
          id: '3',
          name: 'Admin User',
          email: email,
          studentId: '',
          university: '',
          department: '',
          role: 'admin',
          profileImage: null,
        );
      } else {
        _error = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _currentUser!.id);
      await prefs.setString('role', _currentUser!.role);
      await prefs.setString('userName', _currentUser!.name);
      await prefs.setString('userEmail', _currentUser!.email);
      await prefs.setString('studentId', _currentUser!.studentId);
      await prefs.setString('university', _currentUser!.university);
      await prefs.setString('department', _currentUser!.department);
      if (_currentUser!.profileImage != null) {
        await prefs.setString('profileImage', _currentUser!.profileImage!);
      }
      if (_currentUser!.role == 'driver') {
        await prefs.setString('driverId', _currentUser!.driverId ?? '');
        await prefs.setString(
            'licenseNumber', _currentUser!.licenseNumber ?? '');
        await prefs.setString(
            'licenseExpiration', _currentUser!.licenseExpiration ?? '');
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'An error occurred during login: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
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
    String? driverId,
    String? licenseNumber,
    String? licenseExpiration,
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
      _error = 'Password must be at least 6 characters long';
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
      await Future.delayed(const Duration(seconds: 2));
      _currentUser = User(
        id: '4',
        name: name,
        email: email,
        studentId: studentId ?? '',
        university: university ?? '',
        department: department ?? '',
        role: role,
        profileImage: null,
        driverId: driverId,
        licenseNumber: licenseNumber,
        licenseExpiration: licenseExpiration,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _currentUser!.id);
      await prefs.setString('role', _currentUser!.role);
      await prefs.setString('userName', _currentUser!.name);
      await prefs.setString('userEmail', _currentUser!.email);
      await prefs.setString('studentId', _currentUser!.studentId);
      await prefs.setString('university', _currentUser!.university);
      await prefs.setString('department', _currentUser!.department);
      if (_currentUser!.profileImage != null) {
        await prefs.setString('profileImage', _currentUser!.profileImage!);
      }
      if (_currentUser!.role == 'driver') {
        await prefs.setString('driverId', _currentUser!.driverId ?? '');
        await prefs.setString(
            'licenseNumber', _currentUser!.licenseNumber ?? '');
        await prefs.setString(
            'licenseExpiration', _currentUser!.licenseExpiration ?? '');
      }
      print('Signed up user: [32m${_currentUser?.toJson()}[0m');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'An error occurred during signup: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
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
      _currentUser = null;
    } catch (e) {
      _error = 'An error occurred during logout: ${e.toString()}';
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
      if (email == 'user@example.com' ||
          email == 'driver@example.com' ||
          email == 'admin@example.com') {
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
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Update user data
      _currentUser = User(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
        studentId: studentId ?? _currentUser!.studentId,
        university: university ?? _currentUser!.university,
        department: department ?? _currentUser!.department,
        role: _currentUser!.role,
        profileImage: profileImage ?? _currentUser!.profileImage,
        driverId: _currentUser!.driverId,
        licenseNumber: _currentUser!.licenseNumber,
        licenseExpiration: _currentUser!.licenseExpiration,
      );

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _currentUser!.name);
      await prefs.setString('userEmail', _currentUser!.email);
      await prefs.setString('studentId', _currentUser!.studentId);
      await prefs.setString('university', _currentUser!.university);
      await prefs.setString('department', _currentUser!.department);
      if (profileImage != null) {
        await prefs.setString('profileImage', profileImage);
      }
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
      throw Exception(_error);
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
      throw Exception('No user is currently logged in');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate password verification and update
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, you would verify the current password and update to the new one
      if (currentPassword != 'password') {
        // This is just for demo purposes
        throw Exception('Current password is incorrect');
      }

      // Password successfully changed
      // In a real app, you would update the password in your backend
    } catch (e) {
      _error = 'Failed to change password: ${e.toString()}';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
