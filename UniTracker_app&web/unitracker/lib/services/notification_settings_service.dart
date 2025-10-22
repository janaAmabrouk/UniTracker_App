import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService extends ChangeNotifier {
  static const String _routeDelaysKey = 'route_delays_enabled';
  static const String _reservationUpdatesKey = 'reservation_updates_enabled';
  static const String _scheduleChangesKey = 'schedule_changes_enabled';
  static const String _maintenanceAlertsKey = 'maintenance_alerts_enabled';

  final SharedPreferences _prefs;
  bool _routeDelaysEnabled;
  bool _reservationUpdatesEnabled;
  bool _scheduleChangesEnabled;
  bool _maintenanceAlertsEnabled;

  NotificationSettingsService(this._prefs)
      : _routeDelaysEnabled = _prefs.getBool(_routeDelaysKey) ?? true,
        _reservationUpdatesEnabled =
            _prefs.getBool(_reservationUpdatesKey) ?? true,
        _scheduleChangesEnabled = _prefs.getBool(_scheduleChangesKey) ?? true,
        _maintenanceAlertsEnabled =
            _prefs.getBool(_maintenanceAlertsKey) ?? true;

  bool get routeDelaysEnabled => _routeDelaysEnabled;
  bool get reservationUpdatesEnabled => _reservationUpdatesEnabled;
  bool get scheduleChangesEnabled => _scheduleChangesEnabled;
  bool get maintenanceAlertsEnabled => _maintenanceAlertsEnabled;

  void setRouteDelaysEnabled(bool value) {
    if (_routeDelaysEnabled != value) {
      _routeDelaysEnabled = value;
      _prefs.setBool(_routeDelaysKey, value);
      notifyListeners();
    }
  }

  void setReservationUpdatesEnabled(bool value) {
    if (_reservationUpdatesEnabled != value) {
      _reservationUpdatesEnabled = value;
      _prefs.setBool(_reservationUpdatesKey, value);
      notifyListeners();
    }
  }

  void setScheduleChangesEnabled(bool value) {
    if (_scheduleChangesEnabled != value) {
      _scheduleChangesEnabled = value;
      _prefs.setBool(_scheduleChangesKey, value);
      notifyListeners();
    }
  }

  void setMaintenanceAlertsEnabled(bool value) {
    if (_maintenanceAlertsEnabled != value) {
      _maintenanceAlertsEnabled = value;
      _prefs.setBool(_maintenanceAlertsKey, value);
      notifyListeners();
    }
  }
}
