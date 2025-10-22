import 'package:flutter/foundation.dart';
import '../models/driver_notification.dart';

class NotificationService extends ChangeNotifier {
  NotificationService() {
    print('NotificationService: Initializing...');
    print(
        'NotificationService: Initialized with [32m[1m[4m${_notifications.length}[0m notifications');
  }

  final List<DriverNotification> _notifications = [];
  bool _isLoading = false;

  List<DriverNotification> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get hasNotifications => _notifications.isNotEmpty;

  // Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Get notifications by type
  List<DriverNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1)); // Simulated delay

      _notifications.clear(); // Clear previous notifications before adding new
      // Sample notifications
      _notifications.addAll([
        DriverNotification(
          id: '1',
          title: 'Route Update',
          message: 'Your route has been updated for tomorrow',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          type: NotificationType.route,
        ),
        DriverNotification(
          id: '2',
          title: 'Schedule Change',
          message: 'Your shift has been rescheduled to 2 PM',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          type: NotificationType.schedule,
        ),
        DriverNotification(
          id: '3',
          title: 'Maintenance Alert',
          message: 'Vehicle maintenance is due in 2 days',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          type: NotificationType.maintenance,
        ),
      ]);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) {
    final notification = DriverNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    _notifications.insert(0, notification);
    notifyListeners();
  }

  // The following convenience methods are commented out because their NotificationType values do not exist in the model.
  // void addReservationConfirmation({ ... }) {}
  // void addReservationCancellation({ ... }) {}
  // void addRouteDelay({ ... }) {}
  // void addNewRoute({ ... }) {}
  // void addSeatLimitReached({ ... }) {}
  // void addEventReminder({ ... }) {}
  // void addTimeUpdate({ ... }) {}

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // Delete a notification
  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    notifyListeners();
  }
}
