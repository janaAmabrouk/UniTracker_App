import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitracker/services/notification_service.dart';
import 'package:unitracker/services/notification_settings_service.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/utils/responsive_utils.dart';
import 'package:unitracker/models/driver_notification.dart';

class DriverNotificationsScreen extends StatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  State<DriverNotificationsScreen> createState() =>
      _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState extends State<DriverNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await context.read<NotificationService>().loadNotifications();
  }

  void clearAllNotifications() {
    context.read<NotificationService>().clearAllNotifications();
  }

  bool get hasNotifications =>
      context.watch<NotificationService>().hasNotifications;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            'Notifications',
            style: TextStyle(
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              fontSize: getProportionateScreenWidth(20),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          Consumer<NotificationService>(
            builder: (context, service, _) => TextButton(
              onPressed: service.notifications.isEmpty
                  ? null
                  : service.clearAllNotifications,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                disabledForegroundColor: Colors.white.withOpacity(0.5),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Settings Section
          SliverToBoxAdapter(
            child: Consumer<NotificationSettingsService>(
              builder: (context, settings, _) => Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNotificationToggle(
                      'Route Delays',
                      'Get notified about bus delays and disruptions',
                      settings.routeDelaysEnabled ?? false,
                      (value) => settings.setRouteDelaysEnabled(value ?? false),
                    ),
                    const Divider(height: 1),
                    _buildNotificationToggle(
                      'Reservation Updates',
                      'Receive updates about your bus reservations',
                      settings.reservationUpdatesEnabled ?? false,
                      (value) =>
                          settings.setReservationUpdatesEnabled(value ?? false),
                    ),
                    const Divider(height: 1),
                    _buildNotificationToggle(
                      'Schedule Changes',
                      'Stay informed about changes to bus schedules',
                      settings.scheduleChangesEnabled ?? false,
                      (value) =>
                          settings.setScheduleChangesEnabled(value ?? false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Notifications List
          Consumer<NotificationService>(
            builder: (context, service, _) {
              if (service.notifications.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: getProportionateScreenWidth(48),
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: getProportionateScreenWidth(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom +
                      getProportionateScreenHeight(kBottomNavigationBarHeight),
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notification = service.notifications[index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNotificationItem(
                            context,
                            notification,
                            service,
                          ),
                          if (index < service.notifications.length - 1)
                            const Divider(height: 1),
                        ],
                      );
                    },
                    childCount: service.notifications.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    DriverNotification notification,
    NotificationService service,
  ) {
    IconData icon = Icons.notifications_outlined;
    Color iconColor = AppTheme.primaryColor;

    switch (notification.type) {
      case NotificationType.route:
        icon = Icons.directions_bus_outlined;
        iconColor = AppTheme.primaryColor;
        break;
      case NotificationType.schedule:
        icon = Icons.schedule;
        iconColor = Colors.green;
        break;
      case NotificationType.maintenance:
        icon = Icons.build;
        iconColor = Colors.orange;
        break;
      case NotificationType.alert:
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.red;
        break;
    }

    return Material(
      color: notification.isRead ? Colors.white : Colors.grey[50],
      child: InkWell(
        onTap: () {
          service.markAsRead(notification.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: getProportionateScreenWidth(40),
                height: getProportionateScreenHeight(40),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(getProportionateScreenWidth(20)),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: getProportionateScreenWidth(24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: getProportionateScreenWidth(8),
                            height: getProportionateScreenHeight(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(14),
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTimeAgo(notification.timestamp),
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(12),
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return difference.inDays == 1
          ? 'Yesterday'
          : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
