import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class NotificationSettingsService extends ChangeNotifier {
  static const String _routeDelaysKey = 'route_delays_enabled';
  static const String _reservationUpdatesKey = 'reservation_updates_enabled';
  static const String _scheduleChangesKey = 'schedule_changes_enabled';
  static const String _maintenanceAlertsKey = 'maintenance_alerts_enabled';

  final SharedPreferences _prefs;
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _routeDelaysEnabled;
  bool _reservationUpdatesEnabled;
  bool _scheduleChangesEnabled;
  bool _maintenanceAlertsEnabled;
  bool _pushNotificationsEnabled;
  bool _emailNotificationsEnabled;
  bool _smsNotificationsEnabled;
  bool _isLoading = false;
  String? _lastError;

  NotificationSettingsService(this._prefs)
      : _routeDelaysEnabled = _prefs.getBool(_routeDelaysKey) ?? true,
        _reservationUpdatesEnabled =
            _prefs.getBool(_reservationUpdatesKey) ?? true,
        _scheduleChangesEnabled = _prefs.getBool(_scheduleChangesKey) ?? true,
        _maintenanceAlertsEnabled =
            _prefs.getBool(_maintenanceAlertsKey) ?? true,
        _pushNotificationsEnabled = true,
        _emailNotificationsEnabled = true,
        _smsNotificationsEnabled = false {
    _loadFromSupabase();
  }

  bool get routeDelaysEnabled => _routeDelaysEnabled;
  bool get reservationUpdatesEnabled => _reservationUpdatesEnabled;
  bool get scheduleChangesEnabled => _scheduleChangesEnabled;
  bool get maintenanceAlertsEnabled => _maintenanceAlertsEnabled;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get emailNotificationsEnabled => _emailNotificationsEnabled;
  bool get smsNotificationsEnabled => _smsNotificationsEnabled;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  Future<void> _loadFromSupabase() async {
    try {
      _isLoading = true;
      notifyListeners();
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await _supabaseService.client
          .from('user_notification_settings')
          .select('*')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      debugPrint('🔄 Loaded notification settings from Supabase: $response');
      if (response != null) {
        _routeDelaysEnabled = response['route_delays_enabled'] as bool? ?? true;
        _reservationUpdatesEnabled =
            response['reservation_updates_enabled'] as bool? ?? true;
        _scheduleChangesEnabled =
            response['schedule_changes_enabled'] as bool? ?? true;
        _maintenanceAlertsEnabled =
            response['maintenance_alerts_enabled'] as bool? ?? true;
        _pushNotificationsEnabled =
            response['push_notifications_enabled'] as bool? ?? true;
        _emailNotificationsEnabled =
            response['email_notifications_enabled'] as bool? ?? true;
        _smsNotificationsEnabled =
            response['sms_notifications_enabled'] as bool? ?? false;

        debugPrint('✅ Notification settings loaded from Supabase');
        _lastError = null;
        _isLoading = false;
        notifyListeners();
      } else {
        // Create default settings
        await _createDefaultSettings(currentUser.id);
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading notification settings: $e');
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createDefaultSettings(String userId) async {
    try {
      await _supabaseService.client.from('user_notification_settings').insert({
        'user_id': userId,
        'route_delays_enabled': true,
        'reservation_updates_enabled': true,
        'schedule_changes_enabled': true,
        'maintenance_alerts_enabled': true,
        'push_notifications_enabled': true,
        'email_notifications_enabled': true,
        'sms_notifications_enabled': false,
      });
      debugPrint('✅ Default notification settings created in Supabase');
    } catch (e) {
      debugPrint('❌ Error creating default notification settings: $e');
    }
  }

  void setRouteDelaysEnabled(bool value) {
    if (_routeDelaysEnabled != value) {
      _routeDelaysEnabled = value;
      _saveToSupabase('route_delays_enabled', value);
      _prefs.setBool(_routeDelaysKey, value);
      notifyListeners();
    }
  }

  void setReservationUpdatesEnabled(bool value) {
    if (_reservationUpdatesEnabled != value) {
      _reservationUpdatesEnabled = value;
      _saveToSupabase('reservation_updates_enabled', value);
      _prefs.setBool(_reservationUpdatesKey, value);
      notifyListeners();
    }
  }

  void setScheduleChangesEnabled(bool value) {
    if (_scheduleChangesEnabled != value) {
      _scheduleChangesEnabled = value;
      _saveToSupabase('schedule_changes_enabled', value);
      _prefs.setBool(_scheduleChangesKey, value);
      notifyListeners();
    }
  }

  void setMaintenanceAlertsEnabled(bool value) {
    if (_maintenanceAlertsEnabled != value) {
      _maintenanceAlertsEnabled = value;
      _saveToSupabase('maintenance_alerts_enabled', value);
      _prefs.setBool(_maintenanceAlertsKey, value);
      notifyListeners();
    }
  }

  void setPushNotificationsEnabled(bool value) {
    if (_pushNotificationsEnabled != value) {
      _pushNotificationsEnabled = value;
      _saveToSupabase('push_notifications_enabled', value);
      notifyListeners();
    }
  }

  void setEmailNotificationsEnabled(bool value) {
    if (_emailNotificationsEnabled != value) {
      _emailNotificationsEnabled = value;
      _saveToSupabase('email_notifications_enabled', value);
      notifyListeners();
    }
  }

  void setSmsNotificationsEnabled(bool value) {
    if (_smsNotificationsEnabled != value) {
      _smsNotificationsEnabled = value;
      _saveToSupabase('sms_notifications_enabled', value);
      notifyListeners();
    }
  }

  Future<void> _saveToSupabase(String field, bool value) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;
      debugPrint('⬆️ Saving $field = $value for user ${currentUser.id}');
      await _supabaseService.client.from('user_notification_settings').upsert({
        'user_id': currentUser.id,
        field: value,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      debugPrint('✅ Notification setting $field saved to Supabase: $value');
      _lastError = null;
    } catch (e) {
      debugPrint('❌ Error saving notification setting $field: $e');
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> reloadFromSupabase() async {
    await _loadFromSupabase();
  }
}
