import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';

class NotificationSettings {
  bool pushNotifications;
  bool emailNotifications;
  bool smsNotifications;

  NotificationSettings({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = true,
  });
}

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  late NotificationSettings notificationSettings;

  @override
  void initState() {
    super.initState();
    notificationSettings = NotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(16),
          vertical: getProportionateScreenHeight(16),
        ),
        child: Column(
          children: [
            SwitchListTile(
              value: notificationSettings.pushNotifications,
              onChanged: (bool value) {
                setState(() {
                  notificationSettings.pushNotifications = value;
                });
              },
              activeColor: const Color(0xFF1A237E),
              inactiveThumbColor: Colors.grey[300],
              inactiveTrackColor: Colors.grey[200],
              title: const Text('Push Notifications'),
            ),
            SwitchListTile(
              value: notificationSettings.emailNotifications,
              onChanged: (bool value) {
                setState(() {
                  notificationSettings.emailNotifications = value;
                });
              },
              activeColor: const Color(0xFF1A237E),
              inactiveThumbColor: Colors.grey[300],
              inactiveTrackColor: Colors.grey[200],
              title: const Text('Email Notifications'),
            ),
            SwitchListTile(
              value: notificationSettings.smsNotifications,
              onChanged: (bool value) {
                setState(() {
                  notificationSettings.smsNotifications = value;
                });
              },
              activeColor: const Color(0xFF1A237E),
              inactiveThumbColor: Colors.grey[300],
              inactiveTrackColor: Colors.grey[200],
              title: const Text('SMS Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}
