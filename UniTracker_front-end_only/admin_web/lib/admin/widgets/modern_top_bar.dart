import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/widgets/animated_widgets.dart';
import 'package:admin_web/admin/services/admin_data_service.dart';
import 'dart:ui';

class ModernTopBar extends StatefulWidget {
  final String title;
  final Function(String)? onSearch;
  final VoidCallback? onProfileTap;

  const ModernTopBar({
    super.key,
    required this.title,
    this.onSearch,
    this.onProfileTap,
  });

  @override
  State<ModernTopBar> createState() => _ModernTopBarState();
}

class _ModernTopBarState extends State<ModernTopBar>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _notifications = [];
  bool _hasUnreadNotifications = false;
  bool _isSearchFocused = false;
  late AnimationController _searchAnimationController;
  late AnimationController _notificationAnimationController;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _notificationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
      if (_searchFocusNode.hasFocus) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
      }
    });

    _loadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    _notificationAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await AdminDataService().getNotifications();
      setState(() {
        _notifications = notifications;
        _hasUnreadNotifications = notifications.isNotEmpty;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _showNotifications() {
    _notificationAnimationController.forward();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _buildNotificationDialog(),
    ).then((_) {
      _notificationAnimationController.reverse();
    });
  }

  Widget _buildNotificationDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      AnimatedWidgets.scaleButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _notifications.isEmpty
                        ? _buildEmptyNotifications()
                        : ListView.builder(
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              return _buildNotificationItem(_notifications[index], index);
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedWidgets.scaleButton(
                          onTap: () {
                            setState(() {
                              _hasUnreadNotifications = false;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              'Mark All Read',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
    Color getNotificationColor(String? severity) {
      switch (severity) {
        case 'error':
          return const Color(0xFFEF4444);
        case 'warning':
          return const Color(0xFFF59E0B);
        case 'success':
          return const Color(0xFF10B981);
        default:
          return const Color(0xFF3B82F6);
      }
    }

    IconData getNotificationIcon(String? type) {
      switch (type) {
        case 'maintenance':
          return Icons.build_rounded;
        case 'cancellation':
          return Icons.cancel_rounded;
        case 'reservation':
          return Icons.event_seat_rounded;
        case 'system':
          return Icons.info_rounded;
        default:
          return Icons.notifications_rounded;
      }
    }

    final color = getNotificationColor(notification['severity']);
    
    return AnimatedWidgets.slideIn(
      controller: _notificationAnimationController,
      delay: Duration(milliseconds: index * 100),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getNotificationIcon(notification['type']),
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification['message'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(notification['time']),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProfileMenuSelection(String value) {
    switch (value) {
      case 'profile':
        if (widget.onProfileTap != null) {
          widget.onProfileTap!();
        }
        break;
      case 'settings':
        Navigator.pushNamed(context, '/admin/settings');
        break;
      case 'logout':
        _showLogoutConfirmation();
        break;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: const Color(0xFFEF4444)),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    // Clear any stored session data
    // Navigate back to login screen
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/admin/login',
      (route) => false,
    );

    // Show logout success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully logged out'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E8F0).withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Title
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                
                // Search Bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isSearchFocused ? 300 : 250,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isSearchFocused 
                          ? AppTheme.primaryColor.withOpacity(0.3)
                          : const Color(0xFFE2E8F0),
                      width: _isSearchFocused ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search anything...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: _isSearchFocused
                            ? AppTheme.primaryColor
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      if (widget.onSearch != null) {
                        widget.onSearch!(value);
                      }
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Notifications
                AnimatedWidgets.scaleButton(
                  onTap: _showNotifications,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      if (_hasUnreadNotifications)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Profile Menu
                PopupMenuButton<String>(
                  onSelected: _handleProfileMenuSelection,
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, size: 16, color: const Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          const Text('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_rounded, size: 16, color: const Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          const Text('Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 16, color: const Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Text('Logout', style: TextStyle(color: const Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return '';
    try {
      final time = DateTime.parse(timeString);
      final now = DateTime.now();
      final diff = now.difference(time);
      
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h';
      } else {
        return '${diff.inDays}d';
      }
    } catch (e) {
      return timeString;
    }
  }
}
