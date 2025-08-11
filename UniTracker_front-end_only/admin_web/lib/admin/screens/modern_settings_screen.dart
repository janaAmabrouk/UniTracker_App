import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/widgets/animated_widgets.dart';
import '../services/admin_data_service.dart';
import 'dart:ui';
import 'dart:math' show min;
import 'package:intl/intl.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String newText = newValue.text;

    String digitsOnly = newText.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '+2',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    if (!digitsOnly.startsWith('2')) {
      digitsOnly = '2' + digitsOnly;
    }

    String numbersAfterPrefix = '';
    if (digitsOnly.length > 1) {
      numbersAfterPrefix = digitsOnly.substring(1);
      if (numbersAfterPrefix.length > 11) {
        numbersAfterPrefix = numbersAfterPrefix.substring(0, 11);
      }
    }

    final StringBuffer buffer = StringBuffer('+2');

    if (numbersAfterPrefix.isNotEmpty) {
      buffer.write(numbersAfterPrefix[0]);

      if (numbersAfterPrefix.length > 1) {
        buffer.write(' ');

        if (numbersAfterPrefix.length > 1) {
          buffer.write(numbersAfterPrefix.substring(
              1, min(4, numbersAfterPrefix.length)));
        }

        if (numbersAfterPrefix.length > 4) {
          buffer.write(' ');
          buffer.write(numbersAfterPrefix.substring(
              4, min(7, numbersAfterPrefix.length)));
        }

        if (numbersAfterPrefix.length > 7) {
          buffer.write(' ');
          buffer.write(numbersAfterPrefix.substring(
              7, min(11, numbersAfterPrefix.length)));
        }
      }
    }

    final String formattedString = buffer.toString();

    return newValue.copyWith(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }

  static String formatRawNumber(String rawNumber) {
    if (rawNumber.isEmpty) return '';

    String digitsOnly = rawNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!digitsOnly.startsWith('2')) {
      digitsOnly = '2' + digitsOnly;
    }

    String numbersAfterPrefix = '';
    if (digitsOnly.length > 1) {
      numbersAfterPrefix = digitsOnly.substring(1);
      if (numbersAfterPrefix.length > 11) {
        numbersAfterPrefix = numbersAfterPrefix.substring(0, 11);
      }
    }

    final StringBuffer buffer = StringBuffer('+2');
    if (numbersAfterPrefix.isNotEmpty) {
      buffer.write(numbersAfterPrefix[0]);
      if (numbersAfterPrefix.length > 1) {
        buffer.write(' ');
        if (numbersAfterPrefix.length > 1) {
          buffer.write(numbersAfterPrefix.substring(
              1, min(4, numbersAfterPrefix.length)));
        }
        if (numbersAfterPrefix.length > 4) {
          buffer.write(' ');
          buffer.write(numbersAfterPrefix.substring(
              4, min(7, numbersAfterPrefix.length)));
        }
        if (numbersAfterPrefix.length > 7) {
          buffer.write(' ');
          buffer.write(numbersAfterPrefix.substring(
              7, min(11, numbersAfterPrefix.length)));
        }
      }
    }
    return buffer.toString();
  }
}

class ModernSettingsScreen extends StatefulWidget {
  const ModernSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ModernSettingsScreen> createState() => _ModernSettingsScreenState();
}

class _ModernSettingsScreenState extends State<ModernSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await AdminDataService().getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });

      // Initialize controllers
      _settings.forEach((key, value) {
        String initialText = value?.toString() ?? '';
        if (key == 'admin_contact') {
          initialText = PhoneNumberFormatter.formatRawNumber(initialText);
        }
        _controllers[key] = TextEditingController(text: initialText);
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final updatedSettings = <String, dynamic>{};
      _controllers.forEach((key, controller) {
        // Exclude specific keys that are not meant to be updated via this form
        if (!['log_level', 'info', 'backup_frequency']
            .contains(key.trim().toLowerCase())) {
          updatedSettings[key] = controller.text;
        }
      });

      await AdminDataService().updateSettings(updatedSettings);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFE2E8F0).withOpacity(0.3),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildSettingsForm(),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildQuickInfo(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFE2E8F0).withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedWidgets.shimmer(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading Settings...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF6366F1).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure university transport system settings and preferences.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.settings_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm() {
    return AnimatedWidgets.modernCard(
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
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: const Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Configuration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                _isSaving
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Saving...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : AnimatedWidgets.scaleButton(
                        onTap: () {
                          _saveSettings();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981),
                                const Color(0xFF10B981).withOpacity(0.8)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isSaving)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              else
                                const Icon(Icons.save_rounded,
                                    color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _isSaving ? 'Saving...' : 'Save Changes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSettingsSection('University Information', [
                      _buildSettingField('university_name', 'University Name',
                          Icons.school_rounded),
                      _buildSettingField(
                          'admin_email', 'Contact Email', Icons.email_rounded),
                      _buildSettingField('admin_contact', 'Contact Phone',
                          Icons.phone_rounded),
                      _buildSettingField('admin_address', 'Address',
                          Icons.location_on_rounded),
                    ]),
                    const SizedBox(height: 24),
                    _buildSettingsSection('Operating Hours', [
                      _buildTimeSettingField('operating_start_time',
                          'Start Time', Icons.access_time_rounded),
                      _buildTimeSettingField('operating_end_time', 'End Time',
                          Icons.access_time_rounded),
                      _buildTimeSettingField('break_start_time', 'Break Start',
                          Icons.pause_circle_filled_rounded),
                      _buildTimeSettingField('break_end_time', 'Break End',
                          Icons.play_circle_fill_rounded),
                    ]),
                    const SizedBox(height: 24),
                    _buildSettingsSection('System Configuration', [
                      _buildSettingField(
                          'max_reservations_per_user',
                          'Max Reservations per User',
                          Icons.people_alt_rounded),
                      _buildSettingField('reservation_advance_days',
                          'Advance Booking Days', Icons.calendar_today_rounded),
                      _buildSettingField(
                          'cancellation_deadline_hours',
                          'Cancellation Deadline (Hours)',
                          Icons.hourglass_bottom_rounded),
                      _buildSettingField('notification_email',
                          'Notification Email', Icons.notifications_rounded),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        ...fields,
      ],
    );
  }

  Widget _buildSettingField(String key, String label, IconData icon) {
    TextInputType? keyboardType;
    List<TextInputFormatter>? inputFormatters;
    String? hintText;
    String? Function(String?)? validator;

    if (key == 'admin_contact') {
      keyboardType = TextInputType.phone;
      inputFormatters = [PhoneNumberFormatter()];
      hintText = '+2X XXX XXX XXXX';
      validator = (value) {
        if (value?.isEmpty ?? true) return 'Phone number is required';
        if (value!.length != 16)
          return 'Phone number must be in format +2X XXX XXX XXXX';
        return null;
      };
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildTimeSettingField(String key, String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
        onTap: () async {
          TimeOfDay? selectedTime = await showTimePicker(
            context: context,
            initialTime: _parseTime(_controllers[key]?.text ?? '00:00'),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(alwaysUse24HourFormat: false),
                child: child!,
              );
            },
          );

          if (selectedTime != null) {
            final now = DateTime.now();
            final dateTime = DateTime(now.year, now.month, now.day,
                selectedTime.hour, selectedTime.minute);

            // Format for display (12-hour with AM/PM)
            final formattedDisplayTime = DateFormat('hh:mm a').format(dateTime);
            _controllers[key]?.text = formattedDisplayTime;

            // Store in 24-hour format in the _settings map for saving to DB
            _settings[key] = DateFormat('HH:mm').format(dateTime);
          }
        },
      ),
    );
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {
      // Fallback to default if parsing fails
    }
    return TimeOfDay.now(); // Default to current time
  }

  Widget _buildQuickInfo() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AnimatedWidgets.modernCard(
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
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_rounded,
                          color: const Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'System Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusItem(
                      'Database', 'Connected', const Color(0xFF10B981)),
                  _buildStatusItem(
                      'Email Service', 'Active', const Color(0xFF10B981)),
                  _buildStatusItem(
                      'Notifications', 'Enabled', const Color(0xFF10B981)),
                  _buildStatusItem(
                      'Backup', 'Last: 2 hours ago', const Color(0xFF06B6D4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedWidgets.modernCard(
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
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.help_rounded,
                          color: const Color(0xFF8B5CF6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Quick Help',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHelpItem(
                      'University Name', 'Display name for your institution'),
                  _buildHelpItem('Operating Hours', 'When buses are available'),
                  _buildHelpItem(
                      'Max Reservations', 'Limit per student account'),
                  _buildHelpItem(
                      'Advance Days', 'How far ahead students can book'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
