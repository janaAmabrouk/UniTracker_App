import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import '../widgets/admin_layout.dart';
import 'package:intl/intl.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  String _searchQuery = '';
  String _selectedType = 'All';

  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': 'NOT001',
      'title': 'Route Delay',
      'message':
          'Route Campus A - Campus B is experiencing delays due to traffic.',
      'type': 'Alert',
      'timestamp': '2024-05-01 08:30 AM',
      'recipients': 'All Students',
      'status': 'Sent',
    },
    {
      'id': 'NOT002',
      'title': 'Schedule Change',
      'message': 'Bus UN-1234 schedule has been updated for tomorrow.',
      'type': 'Info',
      'timestamp': '2024-05-01 09:15 AM',
      'recipients': 'Route A Students',
      'status': 'Scheduled',
    },
    // Add more mock notifications as needed
  ];

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Notifications Management',
      selectedRoute: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actions Row
          Row(
            children: [
              // Type Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    items: ['All', 'Alert', 'Info', 'Announcement']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Search Field
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search notifications...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Send Notification Button
              ElevatedButton.icon(
                onPressed: () {
                  // Show send notification dialog
                  _showSendNotificationDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send Notification'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notifications List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _mockNotifications
                    .where((notification) =>
                        (_selectedType == 'All' ||
                            notification['type'] == _selectedType) &&
                        (notification['title']
                                .toString()
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            notification['message']
                                .toString()
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase())))
                    .length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final notification = _mockNotifications
                      .where((notification) =>
                          (_selectedType == 'All' ||
                              notification['type'] == _selectedType) &&
                          (notification['title']
                                  .toString()
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ||
                              notification['message']
                                  .toString()
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase())))
                      .toList()[index];
                  return _buildNotificationItem(context, notification);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, Map<String, dynamic> notification) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getTypeColor(notification['type'])[0],
        child: Icon(
          _getTypeIcon(notification['type']),
          color: _getTypeColor(notification['type'])[1],
        ),
      ),
      title: Text(
        notification['title'],
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(notification['message']),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                notification['timestamp'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.people_outline,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                notification['recipients'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: notification['status'] == 'Sent'
                      ? Colors.green[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notification['status'],
                  style: TextStyle(
                    color: notification['status'] == 'Sent'
                        ? Colors.green[800]
                        : Colors.orange[800],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              _showEditNotificationDialog(context, notification);
              break;
            case 'delete':
              _showDeleteConfirmation(context, notification);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getTypeColor(String type) {
    switch (type) {
      case 'Alert':
        return [Colors.red[100]!, Colors.red[800]!];
      case 'Info':
        return [Colors.blue[100]!, Colors.blue[800]!];
      case 'Announcement':
        return [Colors.green[100]!, Colors.green[800]!];
      default:
        return [Colors.grey[100]!, Colors.grey[800]!];
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Alert':
        return Icons.warning_outlined;
      case 'Info':
        return Icons.info_outline;
      case 'Announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  void _showSendNotificationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'Info';
    String selectedRecipients = 'All Students';
    DateTime? scheduledDate;
    TimeOfDay? scheduledTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Alert', 'Info', 'Announcement']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRecipients,
                decoration: const InputDecoration(
                  labelText: 'Recipients',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'All Students',
                  'All Drivers',
                  'Route A Students',
                  'Route B Students'
                ]
                    .map((recipients) => DropdownMenuItem(
                          value: recipients,
                          child: Text(recipients),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedRecipients = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          scheduledDate = date;
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('Schedule Date'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          scheduledTime = time;
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: const Text('Schedule Time'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // Send notification logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Notification sent successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showEditNotificationDialog(
      BuildContext context, Map<String, dynamic> notification) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: notification['title']);
    final messageController =
        TextEditingController(text: notification['message']);
    String selectedType = notification['type'];
    String selectedRecipients = notification['recipients'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notification'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Alert', 'Info', 'Announcement']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRecipients,
                decoration: const InputDecoration(
                  labelText: 'Recipients',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'All Students',
                  'All Drivers',
                  'Route A Students',
                  'Route B Students'
                ]
                    .map((recipients) => DropdownMenuItem(
                          value: recipients,
                          child: Text(recipients),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedRecipients = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // Update notification logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Notification updated successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text(
            'Are you sure you want to delete the notification "${notification['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete notification logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notification deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
