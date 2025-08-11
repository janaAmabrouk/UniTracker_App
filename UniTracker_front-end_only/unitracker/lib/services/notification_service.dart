import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/driver_notification.dart';
import 'supabase_service.dart';

class NotificationService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final List<DriverNotification> _notifications = [];
  bool _isLoading = false;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;
  final Uuid _uuid = const Uuid();

  List<DriverNotification> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get hasNotifications => _notifications.isNotEmpty;

  // Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationService() {
    print('DEBUG: NotificationService created');
    // Don't initialize here - wait for user to be logged in
  }

  // Initialize the service when user is logged in
  void initializeForUser() {
    print('DEBUG: NotificationService.initializeForUser() called');
    print('DEBUG: About to call _loadNotifications()');
    _loadNotifications();
    print(
        'DEBUG: _loadNotifications() completed, about to call _setupRealtimeSubscription()');
    _setupRealtimeSubscription();
    print('DEBUG: _setupRealtimeSubscription() completed');
  }

  // Get notifications by type
  List<DriverNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  Future<void> _loadNotifications() async {
    print('DEBUG: _loadNotifications called');
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      print('DEBUG: No current user in _loadNotifications');
      return;
    }

    print('DEBUG: Loading notifications for user: ${currentUser.id}');
    _isLoading = true;
    notifyListeners();

    try {
      final notificationsData =
          await _supabaseService.getUserNotifications(currentUser.id);
      print(
          'DEBUG: Retrieved ${notificationsData.length} notifications from database');
      _notifications.clear();
      _notifications.addAll(
          notificationsData.map((data) => _mapSupabaseToNotification(data)));
      print('DEBUG: Loaded ${_notifications.length} notifications into memory');
    } catch (e) {
      print('DEBUG: Error loading notifications: $e');
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('DEBUG: _loadNotifications completed');
    }
  }

  void _setupRealtimeSubscription() {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      print('DEBUG: No current user for real-time subscription');
      return;
    }

    print(
        'DEBUG: Setting up real-time subscription for user: ${currentUser.id}');

    // Unsubscribe from any existing subscription
    if (_notificationSubscription != null) {
      print('DEBUG: Cancelling existing subscription');
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
    }

    try {
      print('DEBUG: Calling subscribeToUserNotifications...');
      final stream =
          _supabaseService.subscribeToUserNotifications(currentUser.id);
      print('DEBUG: Stream created successfully');

      _notificationSubscription = stream.listen((dataList) {
        print(
            'DEBUG: Real-time notification update received: ${dataList.length} notifications');
        print('DEBUG: Data received: $dataList');

        for (final data in dataList) {
          final notification = _mapSupabaseToNotification(data);
          if (!_notifications.any((n) => n.id == notification.id)) {
            _notifications.insert(0, notification);
            print('DEBUG: Added new notification: ${notification.title}');
          }
        }

        print(
            'DEBUG: Total notifications after update: ${_notifications.length}, Unread: $unreadCount');
        notifyListeners();
      }, onError: (error) {
        print('DEBUG: Real-time subscription error: $error');
      });

      print('DEBUG: Real-time subscription set up successfully');
    } catch (e) {
      print('DEBUG: Error setting up real-time subscription: $e');
      print('DEBUG: Error details: ${e.toString()}');
    }
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

  // Check if service is properly initialized and reinitialize if needed
  void ensureInitialized() {
    final currentUser = _supabaseService.currentUser;
    if (currentUser != null && _notificationSubscription == null) {
      print('DEBUG: NotificationService not initialized, initializing now');
      initializeForUser();
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      return;
    }

    final notificationId = _uuid.v4();
    final now = DateTime.now();
    final notificationData = {
      'id': notificationId,
      'user_id': currentUser.id,
      'title': title,
      'message': message,
      'type': type.name,
      'is_read': false,
      'created_at': now.toIso8601String(),
    };
    try {
      await _supabaseService.createNotification(notificationData);
    } catch (e) {
      debugPrint(
          'addNotification: Error inserting notification: ' + e.toString());
    }
    // Real-time subscription will update the UI
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    debugPrint(
        'NotificationService: markAsRead called for ID: $notificationId');
    try {
      await _supabaseService.markNotificationAsRead(notificationId);
      // Force a full reload of notifications to ensure UI consistency
      await _loadNotifications();
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
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // First, delete all notifications from the server
      await _supabaseService.deleteAllUserNotifications(currentUser.id);

      // Then, clear the local list
      _notifications.clear();
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
      // Optionally, handle the error in the UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
