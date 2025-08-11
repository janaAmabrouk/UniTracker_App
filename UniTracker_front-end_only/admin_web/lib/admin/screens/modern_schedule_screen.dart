import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/widgets/animated_widgets.dart';
import '../services/admin_data_service.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

class ModernScheduleScreen extends StatefulWidget {
  const ModernScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ModernScheduleScreen> createState() => _ModernScheduleScreenState();
}

class _ModernScheduleScreenState extends State<ModernScheduleScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _buses = [];
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _dayFilter = 'all';

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        AdminDataService().getAllSchedules(),
        AdminDataService().getAllRoutes(),
        AdminDataService().getAllBuses(),
        AdminDataService().getAllDrivers(),
      ]);

      setState(() {
        _schedules = results[0] as List<Map<String, dynamic>>;
        _routes = results[1] as List<Map<String, dynamic>>;
        _buses = results[2] as List<Map<String, dynamic>>;
        _drivers = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });

      // Debug prints
      print(
        'Loaded ${_routes.length} routes: ${_routes.map((r) => r['name']).toList()}',
      );
      print(
        'Loaded ${_buses.length} buses: ${_buses.map((b) => b['busNumber']).toList()}',
      );
      print(
        'Loaded ${_drivers.length} drivers: ${_drivers.map((d) => d['fullName']).toList()}',
      );

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredSchedules {
    var filtered = _schedules;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((schedule) {
        final routeName =
            (schedule['routeName'] ?? _getRouteName(schedule['routeId']) ?? '')
                .toLowerCase();
        final busNumber =
            (schedule['busNumber'] ?? _getBusNumber(schedule['busId']) ?? '')
                .toLowerCase();
        final time = schedule['departureTime']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return routeName.contains(query) ||
            busNumber.contains(query) ||
            time.contains(query);
      }).toList();
    }

    if (_dayFilter != 'all') {
      filtered = filtered.where((schedule) {
        final days = schedule['days'] as List? ?? [];
        return days.contains(_dayFilter);
      }).toList();
    }

    return filtered;
  }

  void _showAddScheduleDialog() {
    final assignedDriverIds =
        _schedules.map((s) => s['driverId']).where((id) => id != null).toSet();
    final availableDrivers =
        _drivers.where((d) => !assignedDriverIds.contains(d['id'])).toList();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _AddScheduleDialog(
        routes: _routes,
        buses: _buses,
        drivers: _drivers,
        schedules: _schedules,
        onScheduleAdded: () {
          _loadData();
        },
      ),
    );
  }

  void _showEditScheduleDialog(Map<String, dynamic> schedule) {
    final assignedDriverIds = _schedules
        .map((s) => s['driverId'])
        .where((id) => id != null && id != schedule['driverId'])
        .toSet();
    final availableDrivers = _drivers
        .where((d) =>
            !assignedDriverIds.contains(d['id']) ||
            d['id'] == schedule['driverId'])
        .toList();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _AddScheduleDialog(
        schedule: schedule,
        routes: _routes,
        buses: _buses,
        drivers: _drivers,
        schedules: _schedules,
        onScheduleAdded: () {
          _loadData();
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Schedule'),
        content: Text(
          'Are you sure you want to delete this schedule for ${schedule['routeName'] ?? 'Unknown Route'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSchedule(schedule['id']);
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

  Future<void> _deleteSchedule(String scheduleId) async {
    try {
      await AdminDataService().deleteSchedule(scheduleId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete schedule: $e')),
        );
      }
    }
  }

  void _showScheduleDetailsDialog(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _ScheduleDetailsDialog(
        schedule: schedule,
        getRouteName: _getRouteName,
        getBusNumber: _getBusNumber,
        getDriverName: _getDriverName,
      ),
    );
  }

  // Helper to format time strings for card display (HH:mm)
  String _formatTimeForCard(String? time) {
    if (time == null || time.isEmpty) return 'N/A';
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
    } catch (e) {
      // Fallback in case of unexpected format
    }
    return time; // Return original if parsing fails
  }

  // Helper to format 24-hour time string to 12-hour for display
  String _format24HourTo12Hour(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final format24 = DateFormat('HH:mm');
      final dateTime = format24.parse(time);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return time; // Return original if parsing fails
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
      child: SingleChildScrollView(
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
              _buildSchedulesList(),
            ],
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
              'Loading Schedules...',
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
            const Color(0xFF06B6D4),
            const Color(0xFF06B6D4).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withOpacity(0.3),
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
                  'Schedule Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage bus schedules, timetables, and route assignments.',
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
              Icons.schedule_rounded,
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
                hintText: 'Search schedules by route, bus, or time...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
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
              value: _dayFilter,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Days')),
                ..._weekDays.map(
                  (day) => DropdownMenuItem(value: day, child: Text(day)),
                ),
              ],
              onChanged: (value) => setState(() => _dayFilter = value!),
            ),
          ),
        ),
        const SizedBox(width: 16),
        AnimatedWidgets.scaleButton(
          onTap: _showAddScheduleDialog,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF06B6D4),
                  const Color(0xFF06B6D4).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.3),
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
                  'Add Schedule',
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
    final totalSchedules = _schedules.length;
    final todaySchedules = _schedules.where((schedule) {
      final days = schedule['days'] as List? ?? [];
      final today = _weekDays[DateTime.now().weekday - 1];
      return days.contains(today);
    }).length;
    final activeRoutes =
        _routes.where((route) => route['status'] == 'active').length;
    final activeBuses = _buses.where((bus) => bus['status'] == 'active').length;

    final stats = [
      {
        'title': 'Total Schedules',
        'value': totalSchedules.toString(),
        'icon': Icons.schedule_rounded,
        'color': const Color(0xFF3B82F6),
        'description': 'All schedules',
      },
      {
        'title': 'Today',
        'value': todaySchedules.toString(),
        'icon': Icons.today_rounded,
        'color': const Color(0xFF10B981),
        'description': 'Running today',
      },
      {
        'title': 'Active Routes',
        'value': activeRoutes.toString(),
        'icon': Icons.route_rounded,
        'color': const Color(0xFFF59E0B),
        'description': 'In service',
      },
      {
        'title': 'Active Buses',
        'value': activeBuses.toString(),
        'icon': Icons.directions_bus_rounded,
        'color': const Color(0xFF8B5CF6),
        'description': 'Available',
      },
    ];

    return Row(
      children: stats
          .map(
            (stat) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (stat['color'] as Color).withOpacity(0.1),
                  ),
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
                            color: (stat['color'] as Color).withOpacity(
                              0.1,
                            ),
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
            ),
          )
          .toList(),
    );
  }

  Widget _buildSchedulesList() {
    if (filteredSchedules.isEmpty) {
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
                Icons.schedule_outlined,
                size: 48,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No schedules found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first schedule to get started',
              style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredSchedules.length,
      itemBuilder: (context, index) {
        final schedule = filteredSchedules[index];
        return _buildScheduleCard(schedule, index);
      },
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule, int index) {
    final routeName = schedule['routeName'] ??
        _getRouteName(schedule['routeId']) ??
        'Unknown Route';
    final busNumber = schedule['busNumber'] ??
        _getBusNumber(schedule['busId']) ??
        'Unknown Bus';
    final driverName = schedule['driverName'] ??
        _getDriverName(schedule['driverId']) ??
        'Unassigned Driver';
    final departureTime = _format24HourTo12Hour(schedule['departureTime']);
    final arrivalTime = _format24HourTo12Hour(schedule['arrivalTime']);
    final days = schedule['days'] as List? ?? [];
    final isToday = days.contains(_weekDays[DateTime.now().weekday - 1]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: AnimatedWidgets.modernCard(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFF06B6D4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: isToday
                      ? const Color(0xFF10B981)
                      : const Color(0xFF06B6D4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          routeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          color: const Color(0xFF64748B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bus $busNumber',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.person_rounded,
                          color: const Color(0xFF64748B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: const Color(0xFF64748B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$departureTime - $arrivalTime',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: days
                          .map<Widget>(
                            (day) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF94A3B8,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      const Color(0xFF94A3B8).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                day.toString().substring(0, 3),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  AnimatedWidgets.scaleButton(
                    onTap: () => _showEditScheduleDialog(schedule),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: const Color(0xFF3B82F6),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedWidgets.scaleButton(
                    onTap: () => _showScheduleDetailsDialog(schedule),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.visibility_rounded,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedWidgets.scaleButton(
                    onTap: () => _showDeleteConfirmation(schedule),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: const Color(0xFFEF4444),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getRouteName(String? routeId) {
    if (routeId == null) return null;
    try {
      final route = _routes.firstWhere((r) => r['id'] == routeId);
      return route['name'];
    } catch (e) {
      return null;
    }
  }

  String? _getBusNumber(String? busId) {
    if (busId == null) return null;
    try {
      final bus = _buses.firstWhere((b) => b['id'] == busId);
      return bus['busNumber'];
    } catch (e) {
      return null;
    }
  }

  String? _getDriverName(String? driverId) {
    if (driverId == null) return null;
    try {
      final driver = _drivers.firstWhere((d) => d['id'] == driverId);
      return driver['fullName'];
    } catch (e) {
      return null;
    }
  }
}

// Add Schedule Dialog
class _AddScheduleDialog extends StatefulWidget {
  final Map<String, dynamic>? schedule;
  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> buses;
  final List<Map<String, dynamic>> drivers;
  final List<Map<String, dynamic>> schedules;
  final VoidCallback onScheduleAdded;

  const _AddScheduleDialog({
    this.schedule,
    required this.routes,
    required this.buses,
    required this.drivers,
    required this.schedules,
    required this.onScheduleAdded,
  });

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _departureTimeController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  String? _selectedRouteId;
  String? _selectedBusId;
  String? _selectedDriverId;
  List<String> _selectedDays = [];
  bool _isLoading = false;

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      // Initialize with existing schedule data
      _selectedRouteId = widget.schedule!['routeId'];
      _selectedBusId = widget.schedule!['busId'];

      // Format departure and arrival times for display
      _departureTimeController.text =
          _format24HourTo12Hour(widget.schedule!['departureTime']);
      _arrivalTimeController.text =
          _format24HourTo12Hour(widget.schedule!['arrivalTime']);

      _selectedDays = List<String>.from(widget.schedule!['days'] ?? []);
      _selectedDriverId = widget.schedule!['driverId'];
    }
  }

  @override
  void dispose() {
    _departureTimeController.dispose();
    _arrivalTimeController.dispose();
    super.dispose();
  }

  // Helper to parse time string (HH:mm or hh:mm a) to TimeOfDay
  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      // Try parsing as 24-hour first (from DB)
      final format24 = DateFormat('HH:mm');
      final dateTime24 = format24.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime24);
    } catch (_) {
      try {
        // Then try parsing as 12-hour (from UI input)
        final format12 = DateFormat('hh:mm a');
        final dateTime12 = format12.parse(timeString);
        return TimeOfDay.fromDateTime(dateTime12);
      } catch (e) {
        // Fallback to default if parsing fails
        return TimeOfDay.now();
      }
    }
  }

  // Helper to format 24-hour time string to 12-hour for display
  String _format24HourTo12Hour(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final format24 = DateFormat('HH:mm');
      final dateTime = format24.parse(time);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return time; // Return original if parsing fails
    }
  }

  void _autoFillTimes(String? routeId) {
    if (routeId == null) return;

    try {
      final route = widget.routes.firstWhere((r) => r['id'] == routeId);
      final startTime24Hour = route['startTime']?.toString() ?? '';
      final endTime24Hour = route['endTime']?.toString() ?? '';

      if (startTime24Hour.isNotEmpty) {
        _departureTimeController.text = _format24HourTo12Hour(startTime24Hour);
      }
      if (endTime24Hour.isNotEmpty) {
        _arrivalTimeController.text = _format24HourTo12Hour(endTime24Hour);
      }
    } catch (e) {
      // Route not found, ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedBusIds = widget.schedules
        .where((s) =>
            s['busId'] != null &&
            (widget.schedule == null || s['id'] != widget.schedule!['id']))
        .map((s) => s['busId'] as String)
        .toSet();
    final availableBuses = widget.buses
        .where((b) =>
            !assignedBusIds.contains(b['id']) || b['id'] == _selectedBusId)
        .toList();

    final assignedDriverIds = widget.schedules
        .where((s) =>
            s['driverId'] != null &&
            (widget.schedule == null || s['id'] != widget.schedule!['id']))
        .map((s) => s['driverId'] as String)
        .toSet();
    final availableDrivers = widget.drivers
        .where((d) =>
            (!assignedDriverIds.contains(d['id']) ||
                d['id'] == _selectedDriverId) &&
            (d['isActive'] == true))
        .toList();

    final assignedRouteIds = widget.schedules
        .where((s) =>
            s['routeId'] != null &&
            (widget.schedule == null || s['id'] != widget.schedule!['id']))
        .map((s) => s['routeId'] as String)
        .toSet();
    final availableRoutes = widget.routes
        .where((r) =>
            (!assignedRouteIds.contains(r['id']) ||
                r['id'] == _selectedRouteId) &&
            (r['is_active'] == true))
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: const Color(0xFF06B6D4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.schedule == null
                          ? 'Add New Schedule'
                          : 'Edit Schedule',
                      style: const TextStyle(
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
                DropdownButtonFormField<String>(
                  value: _selectedRouteId,
                  items: availableRoutes
                      .map<DropdownMenuItem<String>>(
                          (route) => DropdownMenuItem<String>(
                                value: route['id'],
                                child: Text(
                                  route['name'] != null
                                      ? '${route['name']} (${(route['is_active'] == true ? 'Active' : 'Inactive')})'
                                      : 'Unknown Route',
                                ),
                              ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedRouteId = v;
                      _autoFillTimes(v);
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Route'),
                  validator: (v) => v == null ? 'Select a route' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedBusId,
                  items: availableBuses
                      .map<DropdownMenuItem<String>>(
                          (bus) => DropdownMenuItem<String>(
                                value: bus['id'],
                                child: Text(
                                    'Bus ${bus['busNumber']} (${bus['status']})'),
                              ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBusId = v),
                  decoration: const InputDecoration(labelText: 'Bus'),
                  validator: (v) => v == null ? 'Select a bus' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedDriverId,
                  items: availableDrivers
                      .map<DropdownMenuItem<String>>(
                          (driver) => DropdownMenuItem<String>(
                                value: driver['id'],
                                child: Text(
                                    '${driver['fullName']} (${driver['isActive'] == true ? 'Active' : 'Inactive'})'),
                              ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDriverId = v),
                  decoration: const InputDecoration(labelText: 'Driver'),
                  validator: (v) => v == null ? 'Select a driver' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _departureTimeController,
                        readOnly: true, // Make read-only as time is picked
                        decoration: const InputDecoration(
                          labelText: 'Departure Time',
                          prefixIcon: Icon(Icons.access_time_rounded),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                        onTap: () async {
                          TimeOfDay? selectedTime = await showTimePicker(
                            context: context,
                            initialTime: _departureTimeController
                                    .text.isNotEmpty
                                ? _parseTimeOfDay(_departureTimeController.text)
                                : TimeOfDay.now(),
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
                            final dateTime = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                selectedTime.hour,
                                selectedTime.minute);

                            // Format for display (12-hour with AM/PM)
                            _departureTimeController.text =
                                DateFormat('hh:mm a').format(dateTime);

                            // Store in 24-hour format internally for saving to DB
                            // (The controller text itself will be used for saving)
                            _departureTimeController.text =
                                DateFormat('HH:mm').format(dateTime);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _arrivalTimeController,
                        readOnly: true, // Make read-only as time is picked
                        decoration: const InputDecoration(
                          labelText: 'Arrival Time',
                          prefixIcon: Icon(Icons.access_time_rounded),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                        onTap: () async {
                          TimeOfDay? selectedTime = await showTimePicker(
                            context: context,
                            initialTime: _arrivalTimeController.text.isNotEmpty
                                ? _parseTimeOfDay(_arrivalTimeController.text)
                                : TimeOfDay.now(),
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
                            final dateTime = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                selectedTime.hour,
                                selectedTime.minute);

                            // Format for display (12-hour with AM/PM)
                            _arrivalTimeController.text =
                                DateFormat('hh:mm a').format(dateTime);

                            // Store in 24-hour format internally for saving to DB
                            // (The controller text itself will be used for saving)
                            _arrivalTimeController.text =
                                DateFormat('HH:mm').format(dateTime);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Operating Days',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _weekDays.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return AnimatedWidgets.scaleButton(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedDays.remove(day);
                          } else {
                            _selectedDays.add(day);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF06B6D4)
                              : const Color(
                                  0xFF06B6D4,
                                ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF06B6D4).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          day.substring(0, 3),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF06B6D4),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedDays.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select at least one day',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSchedule,
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.schedule == null
                                    ? 'Add Schedule'
                                    : 'Update Schedule',
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
    );
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate() || _selectedDays.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (widget.schedule == null) {
        // Create new schedule
        await AdminDataService().createSchedule(
          routeId: _selectedRouteId!,
          busId: _selectedBusId!,
          driverId: _selectedDriverId!,
          departureTime: _departureTimeController.text,
          arrivalTime: _arrivalTimeController.text,
          days: _selectedDays,
        );
      } else {
        // Update existing schedule
        await AdminDataService().updateSchedule(
          scheduleId: widget.schedule!['id'],
          routeId: _selectedRouteId,
          busId: _selectedBusId,
          driverId: _selectedDriverId,
          departureTime: _departureTimeController.text,
          arrivalTime: _arrivalTimeController.text,
          days: _selectedDays,
        );
      }

      Navigator.pop(context);
      widget.onScheduleAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.schedule == null
                ? 'Schedule added successfully'
                : 'Schedule updated successfully',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${widget.schedule == null ? 'add' : 'update'} schedule: $e',
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _ScheduleDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final String? Function(String?) getRouteName;
  final String? Function(String?) getBusNumber;
  final String? Function(String?) getDriverName;

  const _ScheduleDetailsDialog({
    required this.schedule,
    required this.getRouteName,
    required this.getBusNumber,
    required this.getDriverName,
  });

  @override
  Widget build(BuildContext context) {
    final routeName = getRouteName(schedule['routeId']) ?? 'N/A';
    final busNumber = getBusNumber(schedule['busId']) ?? 'N/A';
    final driverName = getDriverName(schedule['driverId']) ?? 'N/A';

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
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule for $routeName',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bus $busNumber - Driver: $driverName',
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
              _buildDetailRow(
                  'Departure Time', schedule['departureTime'] ?? 'N/A'),
              _buildDetailRow('Arrival Time', schedule['arrivalTime'] ?? 'N/A'),
              _buildDetailRow(
                  'Days', (schedule['days'] as List? ?? []).join(', ')),
              _buildDetailRow('Status', schedule['status'] ?? 'N/A'),
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
