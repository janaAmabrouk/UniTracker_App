import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/responsive_utils.dart';
import '../../theme/app_theme.dart';
import 'package:unitracker/services/notification_settings_service.dart';

class NotificationSettingsDialog extends StatelessWidget {
  const NotificationSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<NotificationSettingsService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (settings.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(settings.lastError!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(16),
        vertical: getProportionateScreenHeight(32),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(getProportionateScreenWidth(33)),
            bottom: Radius.circular(getProportionateScreenWidth(33)),
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: EdgeInsets.fromLTRB(
          getProportionateScreenWidth(24),
          getProportionateScreenHeight(24),
          getProportionateScreenWidth(24),
          getProportionateScreenHeight(16),
        ),
        child: settings.isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notification Settings',
                        style: TextStyle(
                          fontSize: getProportionateScreenWidth(20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: getProportionateScreenHeight(24)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Route Delays'),
                    value: settings.routeDelaysEnabled,
                    onChanged: (bool value) {
                      settings.setRouteDelaysEnabled(value);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reservation Updates'),
                    value: settings.reservationUpdatesEnabled,
                    onChanged: (bool value) {
                      settings.setReservationUpdatesEnabled(value);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Schedule Changes'),
                    value: settings.scheduleChangesEnabled,
                    onChanged: (bool value) {
                      settings.setScheduleChangesEnabled(value);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Email Notifications'),
                    value: settings.emailNotificationsEnabled,
                    onChanged: (bool value) {
                      settings.setEmailNotificationsEnabled(value);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  SizedBox(height: getProportionateScreenHeight(16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(16),
                            vertical: getProportionateScreenHeight(8),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: getProportionateScreenWidth(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
