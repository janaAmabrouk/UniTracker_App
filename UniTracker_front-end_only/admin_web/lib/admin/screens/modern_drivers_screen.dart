import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/widgets/animated_widgets.dart';
import '../services/admin_data_service.dart';
import 'dart:ui';
import 'dart:math' show min;
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newTextLength = newValue.text.length;
    final oldTextLength = oldValue.text.length;

    if (newTextLength == 0) {
      return newValue.copyWith(
          text: '', selection: TextSelection.collapsed(offset: 0));
    }

    if (newTextLength > oldTextLength) {
      String text = newValue.text.replaceAll('-', '');

      if (text.length > 8) {
        return oldValue;
      }

      final buffer = StringBuffer();
      for (int i = 0; i < text.length; i++) {
        buffer.write(text[i]);
        if ((i == 1 || i == 3) && i != text.length - 1) {
          buffer.write('-');
        }
      }
      final formattedText = buffer.toString();
      return newValue.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
    return newValue;
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove all non-digit characters from the new value
    String cleanDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Special handling for initial state or backspace over prefix
    if (cleanDigits.isEmpty) {
      return const TextEditingValue(
        text: '+2',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    // Ensure it always starts with '2' internally for processing
    if (!cleanDigits.startsWith('2')) {
      cleanDigits = '2' + cleanDigits.replaceAll('2', '');
    }

    // Remove the initial '2' for formatting purposes, we'll re-add it.
    String effectiveDigits = cleanDigits.substring(1);

    // Limit to 11 digits after +2
    if (effectiveDigits.length > 11) {
      effectiveDigits = effectiveDigits.substring(0, 11);
    }

    // Build the formatted string
    StringBuffer buffer = StringBuffer();
    buffer.write('+2');

    if (effectiveDigits.isNotEmpty) {
      buffer.write(effectiveDigits[0]); // The 'X' digit

      // Now, add the space and groups for the remaining 10 digits
      if (effectiveDigits.length > 1) {
        // If there's at least one digit after 'X'
        buffer.write(' '); // First space: after +2X
        String remainingDigits =
            effectiveDigits.substring(1); // The 10 digits to be grouped

        // Group 1: 3 digits
        if (remainingDigits.length >= 3) {
          buffer.write(remainingDigits.substring(0, 3));
          if (remainingDigits.length > 3) {
            buffer.write(' '); // Second space: after first XXX
          }
        } else {
          buffer.write(remainingDigits.substring(0));
        }

        // Group 2: 3 digits
        if (remainingDigits.length > 3) {
          if (remainingDigits.length >= 6) {
            buffer.write(remainingDigits.substring(3, 6));
            if (remainingDigits.length > 6) {
              buffer.write(' '); // Third space: after second XXX
            }
          } else {
            buffer.write(remainingDigits.substring(3));
          }
        }

        // Group 3: 4 digits
        if (remainingDigits.length > 6) {
          buffer.write(remainingDigits.substring(6));
        }
      }
    }

    String formattedText = buffer.toString();

    // Ensure the cursor stays at the end of the input for simple append formatting.
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class ModernDriversScreen extends StatefulWidget {
  const ModernDriversScreen({Key? key}) : super(key: key);

  @override
  State<ModernDriversScreen> createState() => _ModernDriversScreenState();
}

class _ModernDriversScreenState extends State<ModernDriversScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _buses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';
  Timer? _autoRefreshTimer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadData();

    // Set up auto-refresh timer (every 30 seconds)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        AdminDataService().getAllDrivers(),
        AdminDataService().getAllBuses(),
      ]);

      setState(() {
        _drivers = results[0] as List<Map<String, dynamic>>;
        _buses = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
        _lastUpdated = DateTime.now();
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredDrivers {
    var filtered = _drivers;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((driver) {
        final name = driver['fullName']?.toString().toLowerCase() ?? '';
        final phone = driver['phone']?.toString().toLowerCase() ?? '';
        final license = driver['licenseNumber']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return name.contains(query) ||
            phone.contains(query) ||
            license.contains(query);
      }).toList();
    }

    if (_statusFilter != 'all') {
      filtered = filtered.where((driver) {
        if (_statusFilter == 'active') {
          return driver['isActive'] == true;
        } else if (_statusFilter == 'inactive') {
          return driver['isActive'] == false;
        }
        return true;
      }).toList();
    }

    return filtered;
  }

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _AddDriverDialog(
        onDriverAdded: () {
          _loadData();
        },
      ),
    );
  }

  void _showEditDriverDialog(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _EditDriverDialog(
        driver: driver,
        onDriverUpdated: _loadData,
      ),
    );
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Driver Details - \\${driver['fullName']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (driver['licenseImagePath'] != null &&
                  driver['licenseImagePath'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Image.network(
                    driver['licenseImagePath'],
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('Could not load license photo'),
                  ),
                ),
              Text('ID: \\${driver['id']}'),
              Text('Full Name: \\${driver['fullName']}'),
              Text('Driver ID: \\${driver['driverId'] ?? 'N/A'}'),
              Text('License Number: \\${driver['licenseNumber']}'),
              Text('License Expiration: \\${driver['licenseExpiration']}'),
              Text(
                  'Assigned Buses: \\${(driver['assignedBuses'] as List?)?.length ?? 0}'),
              Text(
                  'Created: \\${driver['createdAt']?.toString().split('T')[0] ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDriverStatisticsDialog(Map<String, dynamic> driver) async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Fetch fresh statistics data from the database
      final freshStats =
          await AdminDataService().getDriverTripStats(driver['driverId']);

      // Close loading dialog
      Navigator.pop(context);

      // Show statistics dialog with fresh data
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.3),
        builder: (context) => _DriverStatisticsDialog(
          driver: driver,
          stats: freshStats,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load driver statistics: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
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
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF9C27B0),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSearchAndFilters(),
                const SizedBox(height: 24),
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildDriversList(),
              ],
            ),
          ),
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
              'Loading Drivers...',
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
            const Color(0xFF9C27B0),
            const Color(0xFF9C27B0).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
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
                  'Driver Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage university bus drivers, licenses, and assignments.',
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
              Icons.person_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search drivers by name, phone, or license...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Drivers')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (value) => setState(() => _statusFilter = value!),
            ),
          ),
        ),
        const SizedBox(width: 16),
        AnimatedWidgets.scaleButton(
          onTap: _showAddDriverDialog,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF8B5CF6).withOpacity(0.8)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Add Driver',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final totalDrivers = _drivers.length;
    final activeDrivers =
        _drivers.where((driver) => driver['isActive'] == true).length;
    final inactiveDrivers =
        _drivers.where((driver) => driver['isActive'] == false).length;
    final assignedDrivers =
        _buses.where((bus) => bus['driverId'] != null).length;

    // Calculate total completed trips across all drivers
    final totalCompletedTrips = _drivers.fold<int>(0, (sum, driver) {
      return sum + (driver['tripStats']?['completedTrips'] as int? ?? 0);
    });

    final stats = [
      {
        'title': 'Total Drivers',
        'value': totalDrivers.toString(),
        'icon': Icons.person_rounded,
        'color': const Color(0xFF3B82F6),
        'description': 'All drivers',
      },
      {
        'title': 'Active',
        'value': activeDrivers.toString(),
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF10B981),
        'description': 'Available',
      },
      {
        'title': 'Completed Trips',
        'value': totalCompletedTrips.toString(),
        'icon': Icons.route_rounded,
        'color': const Color(0xFF8B5CF6),
        'description': 'Total trips',
      },
      {
        'title': 'Assigned',
        'value': assignedDrivers.toString(),
        'icon': Icons.directions_bus_rounded,
        'color': const Color(0xFFF59E0B),
        'description': 'With buses',
      },
    ];

    return Row(
      children: stats
          .map((stat) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: (stat['color'] as Color).withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (stat['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              stat['icon'] as IconData,
                              color: stat['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            stat['value'] as String,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        stat['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        stat['description'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDriversList() {
    if (filteredDrivers.isEmpty) {
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
                Icons.person_outlined,
                size: 48,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No drivers found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first driver to get started',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: filteredDrivers.length,
      itemBuilder: (context, index) {
        final driver = filteredDrivers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: _buildDriverCard(driver, index),
        );
      },
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver, int index) {
    Color getStatusColor(bool? isActive) {
      if (isActive == true) {
        return const Color(0xFF10B981);
      } else {
        return const Color(0xFFF59E0B);
      }
    }

    final statusColor = getStatusColor(driver['isActive']);
    final assignedBuses = driver['assignedBuses'] as List? ?? [];
    final assignedSchedules = driver['assignedSchedules'] as List? ?? [];
    String? assignedRouteName;
    if (assignedSchedules.isNotEmpty) {
      final firstSchedule = assignedSchedules[0];
      if (firstSchedule['routes'] != null &&
          firstSchedule['routes']['name'] != null) {
        assignedRouteName = firstSchedule['routes']['name'];
      }
    }
    final isAssigned = assignedBuses.isNotEmpty || assignedSchedules.isNotEmpty;

    return AnimatedWidgets.modernCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    driver['isActive'] == true ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              driver['fullName'] ?? 'Unknown Driver',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              driver['phone'] ?? 'No phone',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    driver['licenseNumber'] ?? 'No license',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.directions_bus_rounded,
                  color: const Color(0xFF94A3B8),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignedRouteName != null
                        ? assignedRouteName
                        : isAssigned
                            ? 'Assigned'
                            : 'Unassigned',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Driver ID: ${driver['driverId'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedWidgets.scaleButton(
                      onTap: () => _showDriverStatisticsDialog(driver),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              color: const Color(0xFF8B5CF6),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Show Statistics',
                              style: TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedWidgets.scaleButton(
                      onTap: () => _showEditDriverDialog(driver),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              color: const Color(0xFF3B82F6),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Edit',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedWidgets.scaleButton(
                      onTap: () => _toggleDriverStatus(driver),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              driver['isActive'] == true
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: statusColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driver['isActive'] == true
                                  ? 'Deactivate'
                                  : 'Activate',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedWidgets.scaleButton(
                      onTap: () => _showDeleteConfirmation(driver),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.delete_rounded,
                              color: Color(0xFFEF4444),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Delete',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getAssignedBus(String? driverId) {
    if (driverId == null) return null;
    try {
      return _buses.firstWhere((bus) => bus['driverId'] == driverId);
    } catch (e) {
      return null;
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Driver'),
        content: Text(
          'Are you sure you want to delete the driver "${driver['fullName'] ?? 'Unknown Driver'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDriver(driver['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDriver(String driverId) async {
    try {
      await AdminDataService().deleteDriver(driverId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete driver: $e')),
        );
      }
    }
  }

  Future<void> _toggleDriverStatus(Map<String, dynamic> driver) async {
    try {
      final newStatus = driver['isActive'] != true;
      await AdminDataService().updateDriver(
        driverId: driver['id'],
        isActive: newStatus,
      );

      setState(() {
        driver['isActive'] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Driver ${newStatus ? 'activated' : 'deactivated'} successfully'),
          backgroundColor:
              newStatus ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update driver status: $e')),
      );
    }
  }
}

class _AddDriverDialog extends StatefulWidget {
  final VoidCallback onDriverAdded;

  const _AddDriverDialog({required this.onDriverAdded});

  @override
  State<_AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<_AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _driverIdController = TextEditingController();
  String _selectedStatus = 'active';
  bool _isLoading = false;
  XFile? _licenseImage;
  String? _uploadedLicenseImageUrl;

  Future<void> _pickLicenseImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _licenseImage = image);
      await _uploadLicenseImage(image);
    }
  }

  Future<void> _uploadLicenseImage(XFile image) async {
    final storage =
        Supabase.instance.client.storage.from('driver-license-images');
    final fileName =
        'license_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final bytes = await image.readAsBytes();
    final response = await storage.uploadBinary(fileName, bytes,
        fileOptions: const FileOptions(upsert: true));
    final publicUrl = storage.getPublicUrl(fileName);
    setState(() => _uploadedLicenseImageUrl = publicUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          Icons.person_rounded,
                          color: const Color(0xFF8B5CF6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Add New Driver',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g., Ahmed Mohamed',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Full name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _driverIdController,
                          decoration: const InputDecoration(
                            labelText: 'Driver ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _licenseController,
                          decoration: const InputDecoration(
                            labelText: 'License Number',
                            hintText: 'e.g., DL123456789',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'License number is required';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+2X XXX XXX XXXX',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneNumberFormatter()],
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Phone number is required';
                      if (value!.length != 16)
                        return 'Phone number must be in format +2X XXX XXX XXXX';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value!),
                  ),
                  const SizedBox(height: 24),
                  if (_uploadedLicenseImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Image.network(
                        _uploadedLicenseImageUrl!,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('Could not load license photo'),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _pickLicenseImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload License Image'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                            backgroundColor: AppTheme.cardColor,
                          ),
                          child: Text('Cancel',
                              style: TextStyle(color: AppTheme.primaryColor)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addDriver,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Add Driver'),
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

  Future<void> _addDriver() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AdminDataService().createDriver(
        fullName: _nameController.text,
        phoneNumber: _phoneController.text,
        licenseNumber: _licenseController.text,
        status: _selectedStatus,
        licenseImagePath: _uploadedLicenseImageUrl,
        driverId: _driverIdController.text.isNotEmpty
            ? _driverIdController.text
            : null,
      );
      Navigator.pop(context);
      widget.onDriverAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add driver: $e')),
      );
      print('Failed to add driver: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _driverIdController.dispose();
    super.dispose();
  }
}

class _EditDriverDialog extends StatefulWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onDriverUpdated;

  const _EditDriverDialog(
      {required this.driver, required this.onDriverUpdated});

  @override
  State<_EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends State<_EditDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _licenseController;
  late TextEditingController _licenseExpiryController;
  late TextEditingController _driverIdController;
  late String _selectedStatus;
  bool _isLoading = false;
  XFile? _licenseImage;
  String? _uploadedLicenseImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver['fullName']);
    _phoneController = TextEditingController(text: widget.driver['phone']);
    _licenseController =
        TextEditingController(text: widget.driver['licenseNumber']);
    String? displayDate;
    if (widget.driver['licenseExpiration'] != null &&
        widget.driver['licenseExpiration'].toString().isNotEmpty) {
      try {
        final DateTime parsedDate = DateFormat('yyyy-MM-dd')
            .parseStrict(widget.driver['licenseExpiration']);
        displayDate = DateFormat('dd-MM-yyyy').format(parsedDate);
      } catch (e) {
        displayDate = widget.driver['licenseExpiration'];
      }
    }
    _licenseExpiryController = TextEditingController(text: displayDate);
    _selectedStatus = widget.driver['isActive'] == true ? 'active' : 'inactive';
    _uploadedLicenseImageUrl = widget.driver['licenseImagePath'];
    _driverIdController =
        TextEditingController(text: widget.driver['driverId'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _licenseExpiryController.dispose();
    _driverIdController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _licenseImage = image);
      await _uploadLicenseImage(image);
    }
  }

  Future<void> _uploadLicenseImage(XFile image) async {
    final storage =
        Supabase.instance.client.storage.from('driver-license-images');
    final fileName =
        'license_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final bytes = await image.readAsBytes();
    final response = await storage.uploadBinary(fileName, bytes,
        fileOptions: const FileOptions(upsert: true));
    final publicUrl = storage.getPublicUrl(fileName);
    setState(() => _uploadedLicenseImageUrl = publicUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedWidgets.modernCard(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Driver',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _driverIdController,
                          decoration: const InputDecoration(
                            labelText: 'Driver ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _licenseController,
                          decoration: const InputDecoration(
                            labelText: 'License Number',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty == true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+2X XXX XXX XXXX',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneNumberFormatter()],
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Phone number is required';
                      if (value!.length != 16)
                        return 'Phone number must be in format +2X XXX XXX XXXX';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _licenseExpiryController,
                          decoration: const InputDecoration(
                            labelText: 'License Expiry',
                            hintText: 'DD-MM-YYYY',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.datetime,
                          inputFormatters: [DateInputFormatter()],
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            try {
                              DateFormat('dd-MM-yyyy').parseStrict(value!);
                            } catch (e) {
                              return 'Enter date in DD-MM-YYYY format';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value!),
                  ),
                  const SizedBox(height: 24),
                  if (_uploadedLicenseImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Image.network(
                        _uploadedLicenseImageUrl!,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('Could not load license photo'),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _pickLicenseImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload License Image'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                            backgroundColor: AppTheme.cardColor,
                          ),
                          child: Text('Cancel',
                              style: TextStyle(color: AppTheme.primaryColor)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateDriver,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Update Driver'),
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

  Future<void> _updateDriver() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AdminDataService().updateDriver(
        driverId: widget.driver['id'],
        fullName: _nameController.text,
        phoneNumber: _phoneController.text,
        licenseNumber: _licenseController.text,
        licenseExpiration: _licenseExpiryController.text,
        isActive: _selectedStatus == 'active',
        licenseImagePath: _uploadedLicenseImageUrl,
        newDriverId: _driverIdController.text.isNotEmpty
            ? _driverIdController.text
            : null,
      );
      Navigator.pop(context);
      widget.onDriverUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Driver updated successfully'),
            backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update driver: $e'),
            backgroundColor: const Color(0xFFEF4444)),
      );
      print('Failed to update driver: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _DriverStatisticsDialog extends StatefulWidget {
  final Map<String, dynamic> driver;
  final Map<String, dynamic>? stats;

  const _DriverStatisticsDialog({
    required this.driver,
    required this.stats,
  });

  @override
  State<_DriverStatisticsDialog> createState() =>
      _DriverStatisticsDialogState();
}

class _DriverStatisticsDialogState extends State<_DriverStatisticsDialog> {
  Map<String, dynamic>? _currentStats;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentStats = widget.stats;
  }

  Future<void> _refreshStats() async {
    setState(() => _isRefreshing = true);

    try {
      final freshStats = await AdminDataService()
          .getDriverTripStats(widget.driver['driverId']);
      setState(() {
        _currentStats = freshStats;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() => _isRefreshing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh statistics: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedWidgets.modernCard(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Statistics for ${widget.driver['fullName'] ?? 'Driver'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Driver ID: ${widget.driver['driverId'] ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Total Trips',
                  _currentStats?['totalTrips']?.toString() ?? '0'),
              Padding(
                padding: const EdgeInsets.only(left: 136.0, bottom: 4.0),
                child: Text('All trips assigned to this driver.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ),
              _buildDetailRow('Completed',
                  _currentStats?['completedTrips']?.toString() ?? '0'),
              Padding(
                padding: const EdgeInsets.only(left: 136.0, bottom: 4.0),
                child: Text('Trips the driver has finished.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ),
              _buildDetailRow(
                  'On Time', _currentStats?['onTimeTrips']?.toString() ?? '0'),
              Padding(
                padding: const EdgeInsets.only(left: 136.0, bottom: 4.0),
                child: Text('Completed trips finished on time.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ),
              _buildDetailRow(
                  'On Time Rate',
                  _currentStats?['onTimeRate'] != null
                      ? '${_currentStats?['onTimeRate']}%'
                      : '0%'),
              Padding(
                padding: const EdgeInsets.only(left: 136.0, bottom: 4.0),
                child: Text('Percent of completed trips finished on time.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
