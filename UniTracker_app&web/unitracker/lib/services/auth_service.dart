import 'package:flutter/foundation.dart';
import 'package:unitracker/models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual authentication logic
      // For now, we'll simulate a successful login
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = User(
        id: '1',
        name: 'John Doe',
        email: email,
        studentId: 'S12345678',
        university: 'Egypt University of Informatics (EUI)',
        department: 'Computer Science',
        role: 'student',
      );
    } catch (e) {
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
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual registration logic
      // For now, we'll simulate a successful registration
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = User(
        id: '1',
        name: name,
        email: email,
        studentId: studentId,
        university: university,
        department: department,
        role: 'student',
      );
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
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual driver registration logic
      // For now, we'll simulate a successful registration
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = User(
        id: '1',
        name: name,
        email: '', // Drivers don't have email
        studentId: '', // Drivers don't have student ID
        university: '', // Drivers don't have university
        department: '', // Drivers don't have department
        role: 'driver',
      );
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
      // TODO: Implement actual sign out logic
      await Future.delayed(const Duration(milliseconds: 500));
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
      // TODO: Implement actual profile update logic
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = User(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
        studentId: studentId ?? _currentUser!.studentId,
        university: university ?? _currentUser!.university,
        department: department ?? _currentUser!.department,
        role: _currentUser!.role,
        profileImage: profileImage ?? _currentUser!.profileImage,
      );
    } catch (e) {
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
      throw Exception('No user is currently logged in');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual password change logic
      // For now, we'll simulate a successful password change
      await Future.delayed(const Duration(seconds: 1));

      // In a real implementation, you would:
      // 1. Send the current password and new password to your backend
      // 2. The backend would verify the current password against the stored hash
      // 3. If verified, update to the new password
      // 4. Handle any errors that might occur
    } catch (e) {
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
      // TODO: Implement actual password reset logic
      // For now, we'll simulate a successful password reset request
      await Future.delayed(const Duration(seconds: 1));

      // In a real implementation, you would:
      // 1. For students: Send a password reset link to their email
      // 2. For drivers: Send a password reset link to their registered phone number or email
      // 3. Handle any errors (invalid email, account not found, etc.)

      if (role == 'student' && !email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }

      if (role == 'driver' && driverId.isEmpty) {
        throw Exception('Please enter your driver ID');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
