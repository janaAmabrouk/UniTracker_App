import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_notification.dart';
import 'supabase_service.dart';

class NotificationService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final List<DriverNotification> _notifications = [];
  bool _isLoading = false;
  RealtimeChannel? _notificationSubscription;

  List<DriverNotification> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get hasNotifications => _notifications.isNotEmpty;

  // Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationService() {
    print('NotificationService: Initializing...');
    _loadNotifications();
    _setupRealtimeSubscription();
  }

  // Get notifications by type
  List<DriverNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  Future<void> _loadNotifications() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final notificationsData =
          await _supabaseService.getUserNotifications(currentUser.id);
      _notifications.clear();
      _notifications.addAll(
          notificationsData.map((data) => _mapSupabaseToNotification(data)));
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupRealtimeSubscription() {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return;

    _supabaseService
        .subscribeToUserNotifications(currentUser.id)
        .listen((dataList) {
      for (final data in dataList) {
        final notification = _mapSupabaseToNotification(data);
        if (!_notifications.any((n) => n.id == notification.id)) {
          _notifications.insert(0, notification);
        }
      }
      notifyListeners();
    });
  }

  DriverNotification _mapSupabaseToNotification(Map<String, dynamic> data) {
    return DriverNotification(
      id: data['id'] as String,
      title: data['title'] as String,
      message: data['message'] as String,
      timestamp: DateTime.parse(data['created_at'] as String),
      type: _mapNotificationType(data['type'] as String),
      isRead: data['is_read'] as bool? ?? false,
    );
  }

  NotificationType _mapNotificationType(String type) {
    switch (type) {
      case 'info':
        return NotificationType.info;
      case 'warning':
        return NotificationType.warning;
      case 'alert':
        return NotificationType.alert;
      case 'success':
        return NotificationType.success;
      default:
        return NotificationType.info;
    }
  }

  Future<void> loadNotifications() async {
    await _loadNotifications();
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

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseService.markNotificationAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
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

  @override
  void dispose() {
    _notificationSubscription?.unsubscribe();
    super.dispose();
  }
}
