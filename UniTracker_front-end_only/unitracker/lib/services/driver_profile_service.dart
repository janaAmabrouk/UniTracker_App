import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverProfileService extends ChangeNotifier {
  static DriverProfileService? _instance;
  static DriverProfileService get instance {
    _instance ??= DriverProfileService._internal();
    return _instance!;
  }

  DriverProfileService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _driverProfile;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get driverProfile => _driverProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDriverProfile(String driverId) async {
    debugPrint(
        '🚗 DriverProfileService: Loading profile for driver ID: $driverId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.from('drivers').select('''
            id,
            driver_id,
            full_name,
            phone,
            driver_license,
            license_expiry,
            license_image_path,
            is_active,
            created_at,
            updated_at
          ''').eq('id', driverId).single();

      print('RAW SUPABASE RESPONSE: $response');

      _driverProfile = {
        'id': response['id'],
        'driverId': response['driver_id'],
        'fullName': response['full_name'],
        'phone': response['phone'],
        'licenseNumber': response['driver_license'],
        'licenseExpiry': response['license_expiry'],
        'licenseImagePath': response['license_image_path'],
        'isActive': response['is_active'],
        'joinedDate': response['created_at'],
        'updatedAt': response['updated_at'],
      };

      debugPrint(
          '✅ DriverProfileService: Successfully loaded profile for: ${_driverProfile!['fullName']}');
    } catch (e) {
      _error = 'Failed to load driver profile: ${e.toString()}';
      debugPrint('❌ DriverProfileService: Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDriverProfile({
    required String driverId,
    String? fullName,
    String? phone,
    String? licenseNumber,
    String? licenseExpiry,
  }) async {
    debugPrint(
        '🚗 DriverProfileService: Updating profile for driver ID: $driverId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{};

      if (fullName != null && fullName.isNotEmpty) {
        updateData['full_name'] = fullName;
      }
      if (phone != null && phone.isNotEmpty) {
        updateData['phone'] = phone;
      }
      if (licenseNumber != null && licenseNumber.isNotEmpty) {
        updateData['driver_license'] = licenseNumber;
      }
      if (licenseExpiry != null && licenseExpiry.isNotEmpty) {
        updateData['license_expiry'] = licenseExpiry;
      }

      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toIso8601String();

        final response = await _supabase
            .from('drivers')
            .update(updateData)
            .eq('id', driverId)
            .select()
            .single();

        // Update local profile data
        if (_driverProfile != null) {
          _driverProfile!['fullName'] = response['full_name'];
          _driverProfile!['phone'] = response['phone'];
          _driverProfile!['licenseNumber'] = response['driver_license'];
          _driverProfile!['licenseExpiry'] = response['license_expiry'];
          _driverProfile!['updatedAt'] = response['updated_at'];
        }

        debugPrint('✅ DriverProfileService: Successfully updated profile');
      }
    } catch (e) {
      _error = 'Failed to update driver profile: ${e.toString()}';
      debugPrint('❌ DriverProfileService: Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLicenseImagePath(String driverId, String imageUrl) async {
    await _supabase.from('drivers').update({
      'license_image_path': imageUrl,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', driverId);
    await loadDriverProfile(driverId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
