import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/widgets/animated_widgets.dart';
import '../services/admin_data_service.dart';

// This is a dummy comment to trigger re-analysis.
class ModernBusesScreen extends StatefulWidget {
  const ModernBusesScreen({Key? key}) : super(key: key);

  @override
  State<ModernBusesScreen> createState() => _ModernBusesScreenState();
}

class _ModernBusesScreenState extends State<ModernBusesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<Map<String, dynamic>> _buses = [];
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AdminDataService().getAllBuses(),
        AdminDataService().getAllRoutes(),
        AdminDataService().getAllDrivers(),
      ]);

      setState(() {
        _buses = results[0];
        _routes = results[1];
        _drivers = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsCards(),
            const SizedBox(height: 24),
            _buildFiltersAndSearch(),
            const SizedBox(height: 24),
            _buildBusesGrid(),
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
      child: const Center(child: CircularProgressIndicator()),
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
            const Color(0xFF42A5F5),
            const Color(0xFF42A5F5).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42A5F5).withOpacity(0.3),
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
                  'Bus Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage university bus fleet, assignments, and maintenance.',
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
              Icons.directions_bus_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalBuses = _buses.length;
    final activeBuses = _buses.where((bus) => bus['status'] == 'active').length;
    final maintenanceBuses =
        _buses.where((bus) => bus['status'] == 'maintenance').length;
    final assignedBuses = _buses.where((bus) => bus['driverId'] != null).length;

    final stats = [
      {
        'title': 'Total Buses',
        'value': totalBuses.toString(),
        'icon': Icons.directions_bus_rounded,
        'color': const Color(0xFF3B82F6),
        'description': 'Fleet size',
      },
      {
        'title': 'Active',
        'value': activeBuses.toString(),
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF10B981),
        'description': 'In service',
      },
      {
        'title': 'Maintenance',
        'value': maintenanceBuses.toString(),
        'icon': Icons.build_rounded,
        'color': const Color(0xFFF59E0B),
        'description': 'Under repair',
      },
      {
        'title': 'Assigned',
        'value': assignedBuses.toString(),
        'icon': Icons.person_rounded,
        'color': const Color(0xFF8B5CF6),
        'description': 'With drivers',
      },
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < stats.length - 1 ? 16 : 0,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
        );
      }).toList(),
    );
  }

  Widget _buildFiltersAndSearch() {
    return Row(
      children: [
        Expanded(
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
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search buses by number, route, or driver...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
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
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                DropdownMenuItem(
                  value: 'maintenance',
                  child: Text('Maintenance'),
                ),
              ],
              onChanged: (value) => setState(() => _statusFilter = value!),
            ),
          ),
        ),
        const SizedBox(width: 16),
        AnimatedWidgets.scaleButton(
          onTap: () => _showAddBusDialog(),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF8B5CF6).withOpacity(0.8),
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
                  'Add Bus',
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

  Widget _buildBusesGrid() {
    final filteredBuses = _buses.where((bus) {
      final matchesSearch = bus['busNumber']?.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
          false;
      final matchesStatus =
          _statusFilter == 'all' || bus['status'] == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    if (filteredBuses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No buses found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first bus to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: filteredBuses.length,
      itemBuilder: (context, index) {
        final bus = filteredBuses[index];
        return _buildBusCard(bus, index);
      },
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus, int index) {
    Color getStatusColor(String? status) {
      switch (status?.toLowerCase()) {
        case 'active':
          return const Color(0xFF10B981);
        case 'inactive':
          return const Color(0xFF64748B);
        case 'maintenance':
          return const Color(0xFFF59E0B);
        default:
          return const Color(0xFF64748B);
      }
    }

    final statusColor = getStatusColor(bus['status']);
    final routeName = _getRouteName(bus['routeId']);
    final driverName = _getDriverName(bus['driverId']);

    return AnimatedWidgets.modernCard(
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
                  Icons.directions_bus_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  bus['status']?.toString().toUpperCase() ?? 'UNKNOWN',
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
            'Bus ${bus['busNumber'] ?? 'Unknown'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Capacity: ${bus['capacity'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.route_rounded,
                color: const Color(0xFF94A3B8),
                size: 12,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  routeName ?? 'No route assigned',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: const Color(0xFF94A3B8),
                size: 12,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  driverName ?? 'No driver assigned',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: AnimatedWidgets.scaleButton(
                  onTap: () => _toggleBusStatus(bus),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          bus['status'] == 'active'
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: statusColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bus['status'] == 'active' ? 'Deactivate' : 'Activate',
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
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedWidgets.scaleButton(
                  onTap: () => _showEditBusDialog(bus),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedWidgets.scaleButton(
                  onTap: () => _showDeleteConfirmationDialog(bus),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          color: Colors.redAccent,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  String? _getRouteName(String? routeId) {
    if (routeId == null) return null;
    try {
      final route = _routes.firstWhere((r) => r['id'] == routeId);
      return route['name'];
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

  // Actions
  Future<void> _toggleBusStatus(Map<String, dynamic> bus) async {
    final newStatus = bus['status'] == 'active' ? 'inactive' : 'active';
    try {
      await AdminDataService().updateBus(busId: bus['id'], status: newStatus);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bus ${bus['busNumber']} ${newStatus == 'active' ? 'activated' : 'deactivated'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update bus status: $e')),
        );
      }
    }
  }

  void _showAddBusDialog() {
    _showBusDialog();
  }

  void _showEditBusDialog(Map<String, dynamic> bus) {
    _showBusDialog(bus: bus);
  }

  void _showBusDialog({Map<String, dynamic>? bus}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _BusDialog(
        bus: bus,
        routes: _routes,
        drivers: _drivers,
        buses: _buses,
        onBusUpdated: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(Map<String, dynamic> bus) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'Are you sure you want to delete Bus ${bus['busNumber']}?',
            style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteBus(bus['id']);
    }
  }

  Future<void> _deleteBus(String busId) async {
    setState(() => _isLoading = true);
    try {
      await AdminDataService().deleteBus(busId);
      await _loadData(); // Reload data after deletion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete bus: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Bus Dialog
class _BusDialog extends StatefulWidget {
  final Map<String, dynamic>? bus;
  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> drivers;
  final List<Map<String, dynamic>> buses;
  final VoidCallback onBusUpdated;

  const _BusDialog({
    this.bus,
    required this.routes,
    required this.drivers,
    required this.buses,
    required this.onBusUpdated,
  });

  @override
  State<_BusDialog> createState() => _BusDialogState();
}

class _BusDialogState extends State<_BusDialog> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  String? _selectedRouteId;
  String? _selectedDriverId;
  String _selectedStatus = 'active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bus != null) {
      _busNumberController.text = widget.bus!['busNumber'] ?? '';
      _plateNumberController.text = widget.bus!['plateNumber'] ?? '';
      _capacityController.text = widget.bus!['capacity']?.toString() ?? '';
      _selectedRouteId = widget.bus!['routeId'];
      final String? busDriverId = widget.bus!['driverId'];
      if (busDriverId != null &&
          widget.drivers.any((driver) => driver['id'] == busDriverId)) {
        _selectedDriverId = busDriverId;
      } else {
        _selectedDriverId = null;
      }
      _selectedStatus = widget.bus!['status'] ?? 'active';
    }
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _plateNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignedDriverIds = widget.buses
        .where((b) =>
            b['driverId'] != null &&
            (widget.bus == null || b['id'] != widget.bus!['id']))
        .map((b) => b['driverId'] as String)
        .toSet();
    final availableDrivers = widget.drivers
        .where((d) =>
            !assignedDriverIds.contains(d['id']) ||
            d['id'] == _selectedDriverId)
        .toList();

    final assignedRouteIds = widget.buses
        .where((b) =>
            b['routeId'] != null &&
            (widget.bus == null || b['id'] != widget.bus!['id']))
        .map((b) => b['routeId'] as String)
        .toSet();
    final availableRoutes = widget.routes
        .where((r) =>
            !assignedRouteIds.contains(r['id']) || r['id'] == _selectedRouteId)
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
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
                    Icons.directions_bus_rounded,
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
                        widget.bus == null ? 'Add New Bus' : 'Edit Bus',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        widget.bus == null
                            ? 'Add a new bus to your fleet'
                            : 'Update bus information',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _busNumberController,
                          decoration: InputDecoration(
                            labelText: 'Bus Number',
                            hintText: 'e.g., BUS-001',
                            prefixIcon: const Icon(Icons.numbers_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter bus number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _plateNumberController,
                          decoration: InputDecoration(
                            labelText: 'Plate Number',
                            hintText: 'e.g., ABC-123',
                            prefixIcon: const Icon(
                              Icons.confirmation_number_rounded,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter plate number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    decoration: InputDecoration(
                      labelText: 'Capacity',
                      hintText: 'Number of passengers',
                      prefixIcon: const Icon(Icons.people_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter capacity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedRouteId,
                        decoration: InputDecoration(
                          labelText: 'Route',
                          prefixIcon: const Icon(Icons.route_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No route assigned'),
                          ),
                          ...availableRoutes.map(
                            (route) => DropdownMenuItem(
                              value: route['id'],
                              child: Text(
                                route['name'] != null
                                    ? '${route['name']} (${(route['is_active'] == true ? 'Active' : 'Inactive')})'
                                    : 'Unknown Route',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedRouteId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDriverId,
                        decoration: InputDecoration(
                          labelText: 'Driver',
                          prefixIcon: const Icon(Icons.person_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No driver assigned'),
                          ),
                          ...availableDrivers.map(
                            (driver) => DropdownMenuItem(
                              value: driver['id'],
                              child: Text(
                                driver['fullName'] != null
                                    ? '${driver['fullName']} (${(driver['isActive'] == true ? 'Active' : 'Inactive')})'
                                    : 'Unknown Driver',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedDriverId = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: const Icon(Icons.info_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text('Maintenance'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveBus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            widget.bus == null ? 'Add Bus' : 'Update Bus',
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

  Future<void> _saveBus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.bus == null) {
        // Create new bus
        await AdminDataService().createBus(
          busNumber: _busNumberController.text,
          plateNumber: _plateNumberController.text,
          capacity: int.parse(_capacityController.text),
          status: _selectedStatus,
          driverId: _selectedDriverId,
          routeId: _selectedRouteId,
        );
      } else {
        // Update existing bus
        await AdminDataService().updateBus(
          busId: widget.bus!['id'],
          busNumber: _busNumberController.text,
          plateNumber: _plateNumberController.text,
          capacity: int.parse(_capacityController.text),
          status: _selectedStatus,
          driverId: _selectedDriverId,
          routeId: _selectedRouteId,
        );
      }

      Navigator.pop(context);
      widget.onBusUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.bus == null
                ? 'Bus added successfully'
                : 'Bus updated successfully',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save bus: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
