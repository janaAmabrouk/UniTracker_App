import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/widgets/animated_widgets.dart';
import '../services/admin_data_service.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

class ModernRoutesScreen extends StatefulWidget {
  const ModernRoutesScreen({Key? key}) : super(key: key);

  @override
  State<ModernRoutesScreen> createState() => _ModernRoutesScreenState();
}

class _ModernRoutesScreenState extends State<ModernRoutesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';

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
      final routes = await AdminDataService().getAllRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredRoutes {
    var filtered = _routes;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((route) {
        final name = route['name']?.toString().toLowerCase() ?? '';
        final pickup = route['pickupLocation']?.toString().toLowerCase() ?? '';
        final drop = route['dropLocation']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return name.contains(query) ||
            pickup.contains(query) ||
            drop.contains(query);
      }).toList();
    }

    if (_statusFilter != 'all') {
      filtered =
          filtered.where((route) => route['status'] == _statusFilter).toList();
    }

    return filtered;
  }

  void _showAddRouteDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _AddRouteDialog(
        onRouteAdded: () {
          _loadData();
        },
        format24HourTo12Hour: _format24HourTo12Hour,
        format12HourTo24Hour: _format12HourTo24Hour,
        parseTimeOfDay: _parseTimeOfDay,
        selectTime: _selectTime,
      ),
    );
  }

  void _showEditRouteDialog(Map<String, dynamic> route) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _EditRouteDialog(
        route: route,
        onRouteUpdated: _loadData,
        format24HourTo12Hour: _format24HourTo12Hour,
        format12HourTo24Hour: _format12HourTo24Hour,
        parseTimeOfDay: _parseTimeOfDay,
        selectTime: _selectTime,
      ),
    );
  }

  void _showRouteDetailsDialog(Map<String, dynamic> route) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _RouteDetailsDialog(
          route: route,
          format24HourTo12HourNoSeconds: _format24HourTo12HourNoSeconds),
    );
  }

  // Helper to format 24-hour time string (HH:mm or HH:mm:ss) to 12-hour (hh:mm a)
  String _format24HourTo12Hour(String? time24Hour) {
    if (time24Hour == null || time24Hour.isEmpty) return '';
    try {
      DateTime dateTime;
      // Try parsing with seconds first
      try {
        dateTime = DateFormat('HH:mm:ss').parse(time24Hour);
      } catch (_) {
        // If parsing with seconds fails, try without seconds
        dateTime = DateFormat('HH:mm').parse(time24Hour);
      }
      final formattedTime = DateFormat('hh:mm a')
          .format(dateTime); // Format to 12-hour with AM/PM
      return formattedTime;
    } catch (e) {
      return time24Hour; // Return original if parsing fails
    }
  }

  // Helper to format 24-hour time string (HH:mm:ss or HH:mm) to 12-hour (hh:mm a) without seconds
  String _format24HourTo12HourNoSeconds(String? time24Hour) {
    if (time24Hour == null || time24Hour.isEmpty) return '';
    try {
      DateTime dateTime;
      // Try parsing with seconds first
      try {
        dateTime = DateFormat('HH:mm:ss').parse(time24Hour);
      } catch (_) {
        // If parsing with seconds fails, try without seconds
        dateTime = DateFormat('HH:mm').parse(time24Hour);
      }
      final formattedTime = DateFormat('hh:mm a')
          .format(dateTime); // Format to 12-hour with AM/PM
      return formattedTime;
    } catch (e) {
      return time24Hour; // Return original if parsing fails
    }
  }

  // Helper to convert 12-hour time string (hh:mm a) to 24-hour (HH:mm)
  String _format12HourTo24Hour(String? time12Hour) {
    if (time12Hour == null || time12Hour.isEmpty) return '';
    try {
      final format = DateFormat('hh:mm a');
      final dateTime = format.parse(time12Hour);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return time12Hour; // Return original if parsing fails
    }
  }

  // Helper to parse 12-hour time (hh:mm a) to TimeOfDay
  TimeOfDay _parseTimeOfDay(String timeString) {
    if (timeString.isEmpty) return TimeOfDay.now();
    try {
      final format = DateFormat('hh:mm a');
      final dateTime = format.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      return TimeOfDay.now(); // Fallback
    }
  }

  // Helper to show time picker and update controller
  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(controller.text),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final dt = DateTime(
          now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
      final String formatted12Hour = DateFormat('hh:mm a').format(dt);

      setState(() {
        controller.text = formatted12Hour;
      });
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
              _buildRoutesList(),
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
              'Loading Routes...',
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
            const Color(0xFF10B981),
            const Color(0xFF10B981).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
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
                  'Route Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage university transport routes, schedules, and stops.',
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
              Icons.route_rounded,
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
                hintText: 'Search routes by name, pickup, or destination...',
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
                DropdownMenuItem(value: 'all', child: Text('All Routes')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (value) => setState(() => _statusFilter = value!),
            ),
          ),
        ),
        const SizedBox(width: 16),
        AnimatedWidgets.scaleButton(
          onTap: _showAddRouteDialog,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF10B981).withOpacity(0.8)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
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
                const Icon(Icons.add_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Add Route',
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
    final totalRoutes = _routes.length;
    final activeRoutes =
        _routes.where((route) => route['status'] == 'active').length;
    final inactiveRoutes =
        _routes.where((route) => route['status'] == 'inactive').length;
    final avgStops = _routes.isNotEmpty
        ? (_routes
                    .map((r) => (r['stops'] as List?)?.length ?? 0)
                    .reduce((a, b) => a + b) /
                _routes.length)
            .round()
        : 0;

    final stats = [
      {
        'title': 'Total Routes',
        'value': totalRoutes.toString(),
        'icon': Icons.route_rounded,
        'color': const Color(0xFF3B82F6),
        'description': 'All routes',
      },
      {
        'title': 'Active',
        'value': activeRoutes.toString(),
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF10B981),
        'description': 'In service',
      },
      {
        'title': 'Inactive',
        'value': inactiveRoutes.toString(),
        'icon': Icons.pause_circle_rounded,
        'color': const Color(0xFFF59E0B),
        'description': 'Not running',
      },
      {
        'title': 'Avg Stops',
        'value': avgStops.toString(),
        'icon': Icons.location_on_rounded,
        'color': const Color(0xFF8B5CF6),
        'description': 'Per route',
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

  Widget _buildRoutesList() {
    if (filteredRoutes.isEmpty) {
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
                Icons.route_outlined,
                size: 48,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No routes found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first route to get started',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredRoutes.length,
      itemBuilder: (context, index) {
        final route = filteredRoutes[index];
        return _buildRouteCard(route, index);
      },
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route, int index) {
    Color getStatusColor(String? status) {
      switch (status?.toLowerCase()) {
        case 'active':
          return const Color(0xFF10B981);
        case 'inactive':
          return const Color(0xFFF59E0B);
        default:
          return const Color(0xFF64748B);
      }
    }

    final statusColor = getStatusColor(route['status']);
    final stops = route['stops'] as List? ?? [];

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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: statusColor,
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
                          route['name'] ?? 'Unknown Route',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            route['status']?.toString().toUpperCase() ??
                                'UNKNOWN',
                            style: TextStyle(
                              color: statusColor,
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
                          Icons.location_on_rounded,
                          color: const Color(0xFF64748B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          route['pickupLocation'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 16,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.flag_rounded,
                          color: const Color(0xFF64748B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          route['dropLocation'] ?? 'Unknown',
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
                          Icons.schedule_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_format24HourTo12HourNoSeconds(route['startTime'])} - ${_format24HourTo12HourNoSeconds(route['endTime'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.location_city_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stops.length} stops',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  AnimatedWidgets.scaleButton(
                    onTap: () => _showEditRouteDialog(route),
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
                    onTap: () => _showRouteDetailsDialog(route),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.visibility_rounded,
                        color: const Color(0xFF10B981),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedWidgets.scaleButton(
                    onTap: () => _showDeleteConfirmation(route),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Color(0xFFEF4444),
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

  void _showDeleteConfirmation(Map<String, dynamic> route) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Route'),
        content: Text(
          'Are you sure you want to delete the route "${route['name'] ?? 'Unknown Route'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteRoute(route['id']);
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

  Future<void> _deleteRoute(String routeId) async {
    try {
      await AdminDataService().deleteRoute(routeId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete route: $e')),
        );
      }
    }
  }
}

// Add Route Dialog
class _AddRouteDialog extends StatefulWidget {
  final VoidCallback onRouteAdded;
  final String Function(String?) format24HourTo12Hour;
  final String Function(String?) format12HourTo24Hour;
  final TimeOfDay Function(String) parseTimeOfDay;
  final Future<void> Function(TextEditingController) selectTime;

  const _AddRouteDialog({
    required this.onRouteAdded,
    required this.format24HourTo12Hour,
    required this.format12HourTo24Hour,
    required this.parseTimeOfDay,
    required this.selectTime,
  });

  @override
  State<_AddRouteDialog> createState() => _AddRouteDialogState();
}

class _AddRouteDialogState extends State<_AddRouteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  String _selectedStatus = 'active';
  bool _isLoading = false;

  List<Map<String, dynamic>> _busStops = [];
  final _stopNameController = TextEditingController();
  final _stopTimeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _stopNameController.dispose();
    _stopTimeController.dispose();
    super.dispose();
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
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
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
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.route_rounded,
                            color: const Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add New Route',
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
                        labelText: 'Route Name',
                        hintText: 'e.g., Maadi Shuttle',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Route name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pickupController,
                            decoration: const InputDecoration(
                              labelText: 'Pickup Location',
                              hintText: 'e.g., University Gate',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Pickup location is required';
                              return null;
                            },
                            onChanged: (value) {
                              if (_busStops.isNotEmpty) {
                                _busStops[0]['name'] = value;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _dropController,
                            decoration: const InputDecoration(
                              labelText: 'Drop Location',
                              hintText: 'e.g., Maadi Metro',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Drop location is required';
                              return null;
                            },
                            onChanged: (value) {
                              if (_busStops.isNotEmpty) {
                                _busStops[_busStops.length - 1]['name'] = value;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startTimeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              hintText: 'HH:MM AM/PM',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time_rounded),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Start time is required';
                              return null;
                            },
                            onTap: () async {
                              TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: widget
                                    .parseTimeOfDay(_startTimeController.text),
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context)
                                        .copyWith(alwaysUse24HourFormat: false),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                final now = DateTime.now();
                                final dt = DateTime(now.year, now.month,
                                    now.day, picked.hour, picked.minute);
                                final formatted12 =
                                    DateFormat('hh:mm a').format(dt);
                                final formatted24 =
                                    DateFormat('HH:mm').format(dt);
                                setState(() {
                                  _startTimeController.text = formatted12;
                                  if (_busStops.isNotEmpty) {
                                    _busStops[0]['time'] = formatted24;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _endTimeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              hintText: 'HH:MM AM/PM',
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(Icons.access_time_filled_rounded),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'End time is required';
                              return null;
                            },
                            onTap: () async {
                              TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: widget
                                    .parseTimeOfDay(_endTimeController.text),
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context)
                                        .copyWith(alwaysUse24HourFormat: false),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                final now = DateTime.now();
                                final dt = DateTime(now.year, now.month,
                                    now.day, picked.hour, picked.minute);
                                final formatted12 =
                                    DateFormat('hh:mm a').format(dt);
                                final formatted24 =
                                    DateFormat('HH:mm').format(dt);
                                setState(() {
                                  _endTimeController.text = formatted12;
                                  if (_busStops.isNotEmpty) {
                                    _busStops[_busStops.length - 1]['time'] =
                                        formatted24;
                                  }
                                });
                              }
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
                        DropdownMenuItem(
                            value: 'active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'inactive', child: Text('Inactive')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedStatus = value!),
                    ),
                    const SizedBox(height: 24),
                    _buildBusStopsSection(),
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
                            onPressed: _isLoading ? null : _addRoute,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Add Route'),
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
      ),
    );
  }

  Widget _buildBusStopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Bus Stops',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addBusStop,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Stop'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_busStops.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No bus stops added yet. Click "Add Stop" to add stops.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          SizedBox(
            height: (_busStops.length * 64.0).clamp(64.0, 400.0),
            child: ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _busStops.removeAt(oldIndex);
                  _busStops.insert(newIndex, item);
                  for (int i = 0; i < _busStops.length; i++) {
                    _busStops[i]['order'] = i + 1;
                  }
                  _updatePickupDropAndTimesFromStops();
                });
              },
              children: _busStops.asMap().entries.map((entry) {
                final index = entry.key;
                final stop = entry.value;
                return Container(
                  key: ValueKey(stop['order']),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: index > 0
                        ? Border(top: BorderSide(color: Colors.grey[200]!))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Arrival: ${stop['time']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _editBusStop(index),
                        icon: const Icon(Icons.edit_rounded,
                            color: Color(0xFF10B981)),
                        iconSize: 20,
                      ),
                      IconButton(
                        onPressed: () => _removeBusStop(index),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        iconSize: 20,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.drag_handle,
                          color: Colors.grey, size: 20),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _addBusStop() {
    _stopNameController.clear();
    _stopTimeController.clear();
    _showStopDialog('Add Bus Stop', () {
      if (_stopNameController.text.isNotEmpty &&
          _stopTimeController.text.isNotEmpty) {
        setState(() {
          _busStops.add({
            'name': _stopNameController.text,
            'time': widget.format12HourTo24Hour(_stopTimeController.text),
            'order': _busStops.length + 1,
          });
        });
        _updatePickupDropAndTimesFromStops();
        Navigator.pop(context);
      }
    });
  }

  void _editBusStop(int index) {
    final stop = _busStops[index];
    _stopNameController.text = stop['name'];
    _stopTimeController.text = widget.format24HourTo12Hour(stop['time']);
    _showStopDialog('Edit Bus Stop', () {
      if (_stopNameController.text.isNotEmpty &&
          _stopTimeController.text.isNotEmpty) {
        setState(() {
          _busStops[index] = {
            'id': stop['id'],
            'name': _stopNameController.text,
            'time': widget.format12HourTo24Hour(_stopTimeController.text),
            'order': index + 1,
          };
        });
        _updatePickupDropAndTimesFromStops();
        Navigator.pop(context);
      }
    });
  }

  void _showStopDialog(String title, VoidCallback onSave) {
    final _stopFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: _stopFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _stopNameController,
                decoration: const InputDecoration(
                  labelText: 'Stop Name',
                  hintText: 'e.g., Shopping Mall',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stop name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => widget.selectTime(_stopTimeController),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _stopTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Arrival Time',
                      hintText: 'e.g., 08:15 AM',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Arrival time cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
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
              if (_stopFormKey.currentState!.validate()) {
                onSave();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeBusStop(int index) {
    setState(() {
      _busStops.removeAt(index);
      for (int i = 0; i < _busStops.length; i++) {
        _busStops[i]['order'] = i + 1;
      }
    });
    _updatePickupDropAndTimesFromStops();
  }

  Future<void> _addRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AdminDataService().createRouteWithStops(
        name: _nameController.text,
        pickupLocation: _pickupController.text,
        dropLocation: _dropController.text,
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        status: _selectedStatus,
        busStops: _busStops,
      );

      Navigator.pop(context);
      widget.onRouteAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add route: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updatePickupDropAndTimesFromStops() {
    if (_busStops.isNotEmpty) {
      final first = _busStops.first;
      final last = _busStops.last;
      _pickupController.text = first['name'] ?? '';
      _startTimeController.text =
          widget.format24HourTo12Hour(first['time'] ?? '');
      _dropController.text = last['name'] ?? '';
      _endTimeController.text = widget.format24HourTo12Hour(last['time'] ?? '');
    } else {
      _pickupController.text = '';
      _startTimeController.text = '';
      _dropController.text = '';
      _endTimeController.text = '';
    }
  }
}

class _EditRouteDialog extends StatefulWidget {
  final Map<String, dynamic> route;
  final VoidCallback onRouteUpdated;
  final String Function(String?) format24HourTo12Hour;
  final String Function(String?) format12HourTo24Hour;
  final TimeOfDay Function(String) parseTimeOfDay;
  final Future<void> Function(TextEditingController) selectTime;

  const _EditRouteDialog({
    required this.route,
    required this.onRouteUpdated,
    required this.format24HourTo12Hour,
    required this.format12HourTo24Hour,
    required this.parseTimeOfDay,
    required this.selectTime,
  });

  @override
  State<_EditRouteDialog> createState() => _EditRouteDialogState();
}

class _EditRouteDialogState extends State<_EditRouteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pickupController;
  late TextEditingController _dropController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  final _stopNameController = TextEditingController();
  final _stopTimeController = TextEditingController();
  late String _selectedStatus;
  bool _isLoading = false;
  List<Map<String, dynamic>> _busStops = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.route['name']);
    _pickupController =
        TextEditingController(text: widget.route['pickupLocation']);
    _dropController = TextEditingController(text: widget.route['dropLocation']);
    _startTimeController = TextEditingController(
        text: widget.format24HourTo12Hour(widget.route['startTime']));
    _endTimeController = TextEditingController(
        text: widget.format24HourTo12Hour(widget.route['endTime']));
    _selectedStatus = widget.route['status'] ?? 'active';

    if (widget.route['stops'] != null) {
      _busStops =
          List<Map<String, dynamic>>.from(widget.route['stops'].map((stop) => {
                'id': stop['id'],
                'name': stop['name'] ?? '',
                'time': widget
                    .format24HourTo12Hour(stop['estimated_arrival_time'] ?? ''),
                'order': stop['stop_order'] ?? 1,
              }));
      _busStops
          .sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
    }
    _updatePickupDropAndTimesFromStops();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _stopNameController.dispose();
    _stopTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedWidgets.modernCard(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Edit Route',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Route Name',
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
                          controller: _pickupController,
                          decoration: const InputDecoration(
                            labelText: 'Pickup Location',
                            hintText: 'e.g., University Gate',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Pickup location is required';
                            return null;
                          },
                          onChanged: (value) {
                            if (_busStops.isNotEmpty) {
                              _busStops[0]['name'] = value;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _dropController,
                          decoration: const InputDecoration(
                            labelText: 'Drop Location',
                            hintText: 'e.g., Maadi Metro',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Drop location is required';
                            return null;
                          },
                          onChanged: (value) {
                            if (_busStops.isNotEmpty) {
                              _busStops[_busStops.length - 1]['name'] = value;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startTimeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            hintText: 'HH:MM AM/PM',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time_rounded),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Start time is required';
                            return null;
                          },
                          onTap: () async {
                            TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: widget
                                  .parseTimeOfDay(_startTimeController.text),
                              builder: (context, child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(alwaysUse24HourFormat: false),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              final now = DateTime.now();
                              final dt = DateTime(now.year, now.month, now.day,
                                  picked.hour, picked.minute);
                              final formatted12 =
                                  DateFormat('hh:mm a').format(dt);
                              final formatted24 =
                                  DateFormat('HH:mm').format(dt);
                              setState(() {
                                _startTimeController.text = formatted12;
                                if (_busStops.isNotEmpty) {
                                  _busStops[0]['time'] = formatted24;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _endTimeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            hintText: 'HH:MM AM/PM',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time_filled_rounded),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'End time is required';
                            return null;
                          },
                          onTap: () async {
                            TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: widget
                                  .parseTimeOfDay(_endTimeController.text),
                              builder: (context, child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(alwaysUse24HourFormat: false),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              final now = DateTime.now();
                              final dt = DateTime(now.year, now.month, now.day,
                                  picked.hour, picked.minute);
                              final formatted12 =
                                  DateFormat('hh:mm a').format(dt);
                              final formatted24 =
                                  DateFormat('HH:mm').format(dt);
                              setState(() {
                                _endTimeController.text = formatted12;
                                if (_busStops.isNotEmpty) {
                                  _busStops[_busStops.length - 1]['time'] =
                                      formatted24;
                                }
                              });
                            }
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
                  _buildBusStopsSection(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Update Route'),
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

  Widget _buildBusStopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Bus Stops',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addBusStop,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Stop'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_busStops.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No bus stops added yet. Click "Add Stop" to add stops.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          SizedBox(
            height: (_busStops.length * 64.0).clamp(64.0, 400.0),
            child: ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _busStops.removeAt(oldIndex);
                  _busStops.insert(newIndex, item);
                  for (int i = 0; i < _busStops.length; i++) {
                    _busStops[i]['order'] = i + 1;
                  }
                  _updatePickupDropAndTimesFromStops();
                });
              },
              children: _busStops.asMap().entries.map((entry) {
                final index = entry.key;
                final stop = entry.value;
                return Container(
                  key: ValueKey(stop['order']),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: index > 0
                        ? Border(top: BorderSide(color: Colors.grey[200]!))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Arrival: ${stop['time']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _editBusStop(index),
                        icon: const Icon(Icons.edit_rounded,
                            color: Color(0xFF10B981)),
                        iconSize: 20,
                      ),
                      IconButton(
                        onPressed: () => _removeBusStop(index),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        iconSize: 20,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.drag_handle,
                          color: Colors.grey, size: 20),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _addBusStop() {
    _stopNameController.clear();
    _stopTimeController.clear();
    _showStopDialog('Add Bus Stop', () {
      if (_stopNameController.text.isNotEmpty &&
          _stopTimeController.text.isNotEmpty) {
        setState(() {
          _busStops.add({
            'name': _stopNameController.text,
            'time': widget.format12HourTo24Hour(_stopTimeController.text),
            'order': _busStops.length + 1,
          });
        });
        _updatePickupDropAndTimesFromStops();
        Navigator.pop(context);
      }
    });
  }

  void _editBusStop(int index) {
    final stop = _busStops[index];
    _stopNameController.text = stop['name'];
    _stopTimeController.text = widget.format24HourTo12Hour(stop['time']);
    _showStopDialog('Edit Bus Stop', () {
      if (_stopNameController.text.isNotEmpty &&
          _stopTimeController.text.isNotEmpty) {
        setState(() {
          _busStops[index] = {
            'id': stop['id'],
            'name': _stopNameController.text,
            'time': widget.format12HourTo24Hour(_stopTimeController.text),
            'order': index + 1,
          };
        });
        _updatePickupDropAndTimesFromStops();
        Navigator.pop(context);
      }
    });
  }

  void _showStopDialog(String title, VoidCallback onSave) {
    final _stopFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: _stopFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _stopNameController,
                decoration: const InputDecoration(
                  labelText: 'Stop Name',
                  hintText: 'e.g., Shopping Mall',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stop name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => widget.selectTime(_stopTimeController),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _stopTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Arrival Time',
                      hintText: 'e.g., 08:15 AM',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Arrival time cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
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
              if (_stopFormKey.currentState!.validate()) {
                onSave();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeBusStop(int index) {
    setState(() {
      _busStops.removeAt(index);
      for (int i = 0; i < _busStops.length; i++) {
        _busStops[i]['order'] = i + 1;
      }
    });
    _updatePickupDropAndTimesFromStops();
  }

  Future<void> _updateRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AdminDataService().updateRouteWithStops(
        routeId: widget.route['id'],
        name: _nameController.text,
        pickupLocation: _pickupController.text,
        dropLocation: _dropController.text,
        startTime: widget.format12HourTo24Hour(_startTimeController.text),
        endTime: widget.format12HourTo24Hour(_endTimeController.text),
        status: _selectedStatus,
        busStops: _busStops
            .map((stop) => {
                  ...stop,
                  'time': widget.format12HourTo24Hour(stop['time']),
                })
            .toList(),
      );

      Navigator.pop(context);
      widget.onRouteUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route updated successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update route: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updatePickupDropAndTimesFromStops() {
    if (_busStops.isNotEmpty) {
      final first = _busStops.first;
      final last = _busStops.last;
      _pickupController.text = first['name'] ?? '';
      _startTimeController.text =
          widget.format24HourTo12Hour(first['time'] ?? '');
      _dropController.text = last['name'] ?? '';
      _endTimeController.text = widget.format24HourTo12Hour(last['time'] ?? '');
    } else {
      _pickupController.text = '';
      _startTimeController.text = '';
      _dropController.text = '';
      _endTimeController.text = '';
    }
  }
}

class _RouteDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> route;
  final String Function(String?) format24HourTo12HourNoSeconds;

  const _RouteDetailsDialog(
      {required this.route, required this.format24HourTo12HourNoSeconds});

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
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
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
                          route['name'] ?? 'Unknown Route',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${route['pickupLocation']} → ${route['dropLocation']}',
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
              _buildDetailRow('Operating Hours',
                  '${format24HourTo12HourNoSeconds(route['startTime'])} - ${format24HourTo12HourNoSeconds(route['endTime'])}'),
              _buildDetailRow('Status',
                  route['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
              _buildDetailRow('Route ID', route['id']?.toString() ?? 'N/A'),
              if (route['stops'] != null &&
                  (route['stops'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Bus Stops',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...((route['stops'] as List).map((stop) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(stop['name'] ?? 'Unknown Stop'),
                        ],
                      ),
                    ))),
              ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
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
