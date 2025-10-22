import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/mock_buses.dart';

// Mock data for drivers and routes
const mockDrivers = [
  'John Smith',
  'Sarah Johnson',
  'Michael Brown',
  'Emily Davis',
  'Robert Wilson',
];
const mockRoutes = [
  'North Campus Loop',
  'South Campus Loop',
  'East Campus Loop',
  'West Campus Loop',
  'Downtown Connector',
];
const statusOptions = ['Active', 'Maintenance', 'Inactive'];

class AdminBusesScreen extends StatefulWidget {
  const AdminBusesScreen({Key? key}) : super(key: key);

  @override
  State<AdminBusesScreen> createState() => _AdminBusesScreenState();
}

class _AdminBusesScreenState extends State<AdminBusesScreen> {
  String _search = '';
  int _rowsPerPage = 10;
  String? _statusFilter;
  String? _routeFilter;
  String? _driverFilter;
  late List<MockBus> _buses;

  @override
  void initState() {
    super.initState();
    _buses = List<MockBus>.from(mockBuses);
  }

  List<MockBus> get filteredBuses {
    var buses = _buses;
    if (_search.isNotEmpty) {
      buses = buses
          .where((bus) =>
              bus.id.toLowerCase().contains(_search.toLowerCase()) ||
              bus.name.toLowerCase().contains(_search.toLowerCase()) ||
              bus.driver.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    if (_statusFilter != null && _statusFilter != 'All') {
      buses = buses.where((bus) => bus.status == _statusFilter).toList();
    }
    if (_routeFilter != null && _routeFilter != 'All') {
      buses = buses.where((bus) => bus.route == _routeFilter).toList();
    }
    if (_driverFilter != null && _driverFilter != 'All') {
      buses = buses.where((bus) => bus.driver == _driverFilter).toList();
    }
    return buses;
  }

  void _showToast(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _addBus(MockBus bus) {
    setState(() {
      _buses.insert(0, bus);
    });
    _showToast('Bus ${bus.name} added successfully', color: Colors.green[700]);
  }

  void _editBus(MockBus bus, MockBus updated) {
    setState(() {
      final idx = _buses.indexWhere((b) => b.id == bus.id);
      if (idx != -1) _buses[idx] = updated;
    });
    _showToast('Bus ${updated.name} updated successfully',
        color: Colors.blue[700]);
  }

  void _removeBus(MockBus bus) {
    setState(() {
      _buses.removeWhere((b) => b.id == bus.id);
    });
    _showToast('Bus ${bus.name} deleted', color: Colors.red[700]);
  }

  void _toggleTracking(MockBus bus) {
    setState(() {
      final idx = _buses.indexWhere((b) => b.id == bus.id);
      if (idx != -1) {
        final tracking = !_buses[idx].isTracking;
        _buses[idx] = _buses[idx].copyWith(isTracking: tracking);
        _showToast(
          tracking
              ? 'Now tracking ${bus.name}'
              : 'Tracking stopped for ${bus.name}',
          color: tracking ? Colors.green[700] : Colors.red[700],
        );
      }
    });
  }

  void _changeStatus(MockBus bus, String status) {
    setState(() {
      final idx = _buses.indexWhere((b) => b.id == bus.id);
      if (idx != -1) {
        _buses[idx] = _buses[idx].copyWith(status: status);
      }
    });
    _showToast('Status updated for ${bus.name}', color: Colors.blue[700]);
  }

  void _scheduleMaintenance(MockBus bus, String date) {
    setState(() {
      final idx = _buses.indexWhere((b) => b.id == bus.id);
      if (idx != -1) {
        _buses[idx] = _buses[idx].copyWith(lastMaintenance: date);
      }
    });
    _showToast('Maintenance scheduled for ${bus.name}',
        color: Colors.blue[700]);
  }

  void _assignDriver(MockBus bus, String driver) {
    setState(() {
      final idx = _buses.indexWhere((b) => b.id == bus.id);
      if (idx != -1) {
        _buses[idx] = _buses[idx].copyWith(driver: driver);
      }
    });
    _showToast('Driver assigned to ${bus.name}', color: Colors.blue[700]);
  }

  void _reportIssue(MockBus bus, String issue) {
    _showToast('Issue reported for ${bus.name}', color: Colors.orange[700]);
  }

  void _viewHistory(MockBus bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('History for ${bus.name}'),
        content: const Text('Bus activity timeline (mocked)'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  void _showBusDetails(MockBus bus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusDetailsScreen(
          bus: bus,
          onEdit: (bus) => _showAddEditBusDialog(bus: bus),
          onToggleTracking: () => _toggleTracking(bus),
          onScheduleMaintenance: (date) => _scheduleMaintenance(bus, date),
          onAssignDriver: (driver) => _assignDriver(bus, driver),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  width: 1100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        'Buses',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Manage and monitor all buses in the system.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search buses...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB)),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 16),
                              ),
                              onChanged: (value) =>
                                  setState(() => _search = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _statusFilter ?? 'All',
                            items: ['All', ...statusOptions]
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setState(
                                () => _statusFilter = v == 'All' ? null : v),
                            hint: const Text('Status'),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _routeFilter ?? 'All',
                            items: ['All', ...mockRoutes]
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setState(
                                () => _routeFilter = v == 'All' ? null : v),
                            hint: const Text('Route'),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _driverFilter ?? 'All',
                            items: ['All', ...mockDrivers]
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setState(
                                () => _driverFilter = v == 'All' ? null : v),
                            hint: const Text('Driver'),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () => _showAddEditBusDialog(),
                              icon: const Icon(Icons.add,
                                  size: 20, color: Colors.white),
                              label: const Text('Add Bus'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 1100,
                  child: Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 24.0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 400,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 32,
                                  headingRowHeight: 48,
                                  dataRowHeight: 72,
                                  columns: const [
                                    DataColumn(
                                        label: Text('Bus ID',
                                            style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500))),
                                    DataColumn(
                                        label: Text('Name',
                                            style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500))),
                                    DataColumn(
                                        label: Text('Driver',
                                            style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500))),
                                    DataColumn(
                                        label: Text('Capacity',
                                            style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500))),
                                    DataColumn(
                                        label: Text('Route',
                                            style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500))),
                                    DataColumn(
                                        label: Text('Status',
                                            style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500))),
                                    DataColumn(
                                        label: Text('Last Maintenance',
                                            style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500))),
                                    DataColumn(
                                        label: Text('Tracking',
                                            style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500))),
                                    DataColumn(label: Text('')),
                                  ],
                                  rows: filteredBuses
                                      .take(_rowsPerPage)
                                      .map((bus) {
                                    return DataRow(
                                      onSelectChanged: (_) =>
                                          _showBusDetails(bus),
                                      cells: [
                                        DataCell(Text(bus.id,
                                            style: const TextStyle(
                                                color: Colors.black))),
                                        DataCell(Text(bus.name,
                                            style: const TextStyle(
                                                color: Colors.black))),
                                        DataCell(Text(bus.driver,
                                            style: const TextStyle(
                                                color: Colors.black))),
                                        DataCell(Text(bus.capacity.toString(),
                                            style: const TextStyle(
                                                color: Colors.black))),
                                        DataCell(Text(bus.route,
                                            style: const TextStyle(
                                                color: Colors.black))),
                                        DataCell(
                                            _StatusBadge(status: bus.status)),
                                        DataCell(Text(bus.lastMaintenance,
                                            style: const TextStyle(
                                                color: Colors.black))),
                                        DataCell(_TrackingButton(
                                          isTracking: bus.isTracking,
                                          onPressed: () => _toggleTracking(bus),
                                        )),
                                        DataCell(_BusActionsMenu(
                                          bus: bus,
                                          onEdit: (updated) =>
                                              _editBus(bus, updated),
                                          onRemove: () => _removeBus(bus),
                                          onChangeStatus: (status) =>
                                              _changeStatus(bus, status),
                                          onScheduleMaintenance: (date) =>
                                              _scheduleMaintenance(bus, date),
                                          onViewDetails: () =>
                                              _showBusDetails(bus),
                                          onAssignDriver: (driver) =>
                                              _assignDriver(bus, driver),
                                          onReportIssue: (issue) =>
                                              _reportIssue(bus, issue),
                                          onViewHistory: () =>
                                              _viewHistory(bus),
                                          onShowAddEditBusDialog: (bus) =>
                                              _showAddEditBusDialog(bus: bus),
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('Rows per page:'),
                              const SizedBox(width: 8),
                              DropdownButton<int>(
                                value: _rowsPerPage,
                                items: const [
                                  DropdownMenuItem(
                                      value: 10, child: Text('10')),
                                  DropdownMenuItem(
                                      value: 20, child: Text('20')),
                                  DropdownMenuItem(
                                      value: 50, child: Text('50')),
                                  DropdownMenuItem(
                                      value: 100, child: Text('100')),
                                ],
                                onChanged: (value) {
                                  if (value != null)
                                    setState(() => _rowsPerPage = value);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddEditBusDialog({MockBus? bus}) {
    final isEdit = bus != null;
    final nameController = TextEditingController(text: bus?.name ?? '');
    final idController =
        TextEditingController(text: bus?.id ?? _suggestBusId());
    String driver = bus?.driver ?? mockDrivers.first;
    final capacityController =
        TextEditingController(text: bus?.capacity.toString() ?? '');
    String route = bus?.route ?? mockRoutes.first;
    String status = bus?.status ?? statusOptions.first;
    DateTime? maintenanceDate =
        bus != null ? DateTime.tryParse(bus.lastMaintenance) : null;
    final formKey = GlobalKey<FormState>();

    InputDecoration fieldDecoration(String label, IconData icon) =>
        InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blueGrey[700],
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: Colors.blueGrey[400]),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEdit ? 'Edit Bus' : 'Add New Bus',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: nameController,
                    decoration: fieldDecoration('Name', Icons.directions_bus),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: idController,
                    decoration: fieldDecoration(
                        'Bus Number/ID', Icons.confirmation_number),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: driver,
                    items: mockDrivers
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => driver = v!,
                    decoration: fieldDecoration('Driver', Icons.person),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: capacityController,
                    decoration: fieldDecoration('Capacity', Icons.event_seat),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty || int.tryParse(v) == null
                            ? 'Enter a number'
                            : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: route,
                    items: mockRoutes
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => route = v!,
                    decoration: fieldDecoration('Route', Icons.alt_route),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: statusOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => status = v!,
                    decoration: fieldDecoration('Status', Icons.verified),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          maintenanceDate == null
                              ? 'No maintenance date'
                              : 'Maintenance: ${DateFormat('yyyy-MM-dd').format(maintenanceDate!)}',
                          style: TextStyle(
                            color: Colors.blueGrey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: maintenanceDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            maintenanceDate = picked;
                            (context as Element).markNeedsBuild();
                          }
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blueGrey[700],
                            side: const BorderSide(
                                color: Color(0xFF2563EB), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final newBus = MockBus(
                                id: idController.text,
                                name: nameController.text,
                                driver: driver,
                                capacity: int.parse(capacityController.text),
                                route: route,
                                status: status,
                                lastMaintenance: maintenanceDate != null
                                    ? DateFormat('yyyy-MM-dd')
                                        .format(maintenanceDate!)
                                    : '',
                              );
                              if (isEdit) {
                                _editBus(bus!, newBus);
                              } else {
                                _addBus(newBus);
                              }
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isEdit ? 'Save' : 'Add'),
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

  String _suggestBusId() {
    int maxId = 100;
    for (final bus in _buses) {
      final match = RegExp(r'BUS-(\d+)').firstMatch(bus.id);
      if (match != null) {
        final num = int.tryParse(match.group(1)!);
        if (num != null && num > maxId) maxId = num;
      }
    }
    return 'BUS-${maxId + 1}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'Active':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Active',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
        );
      case 'Maintenance':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Color(0xFFF59E42), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Maintenance',
            style: TextStyle(
              color: Color(0xFFF59E42),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
        );
      case 'Inactive':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Inactive',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
        );
      default:
        return Text(status);
    }
  }
}

class _TrackingButton extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onPressed;
  const _TrackingButton({
    Key? key,
    required this.isTracking,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: isTracking
                ? Icon(Icons.track_changes,
                    key: const ValueKey('active'),
                    color: Colors.green,
                    size: 28)
                : Icon(Icons.track_changes_outlined,
                    key: const ValueKey('inactive'),
                    color: Colors.grey,
                    size: 28),
          ),
          tooltip: isTracking ? 'Stop Tracking' : 'Start Tracking',
          onPressed: () {
            onPressed();
            setState(() {}); // Triggers local rebuild for animation
          },
        );
      },
    );
  }
}

class _BusActionsMenu extends StatelessWidget {
  final MockBus bus;
  final void Function(MockBus updated) onEdit;
  final void Function() onRemove;
  final void Function(String status) onChangeStatus;
  final void Function(String date) onScheduleMaintenance;
  final void Function() onViewDetails;
  final void Function(String driver) onAssignDriver;
  final void Function(String issue) onReportIssue;
  final void Function() onViewHistory;
  final void Function(MockBus bus) onShowAddEditBusDialog;
  const _BusActionsMenu({
    Key? key,
    required this.bus,
    required this.onEdit,
    required this.onRemove,
    required this.onChangeStatus,
    required this.onScheduleMaintenance,
    required this.onViewDetails,
    required this.onAssignDriver,
    required this.onReportIssue,
    required this.onViewHistory,
    required this.onShowAddEditBusDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          enabled: false,
          height: 36,
          child: Text('Actions',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          height: 36,
          child: Text('View details', style: TextStyle(fontSize: 14)),
        ),
        PopupMenuItem<int>(
          value: 1,
          height: 36,
          child: Text('Edit bus', style: TextStyle(fontSize: 14)),
        ),
        PopupMenuItem<int>(
          value: 2,
          height: 36,
          child: Text('Change status', style: TextStyle(fontSize: 14)),
        ),
        PopupMenuItem<int>(
          value: 3,
          height: 36,
          child: Text('Schedule maintenance', style: TextStyle(fontSize: 14)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 4,
          height: 36,
          child: Text(
            'Remove bus',
            style: TextStyle(color: Color(0xFFEF4444), fontSize: 14),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 0:
            onViewDetails();
            break;
          case 1:
            onShowAddEditBusDialog(bus);
            break;
          case 2:
            _showChangeStatusDialog(context, bus);
            break;
          case 3:
            _showScheduleMaintenanceDialog(context, bus);
            break;
          case 4:
            _showRemoveBusDialog(context, bus);
            break;
        }
      },
    );
  }

  void _showBusDetailsDialog(BuildContext context, MockBus bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bus Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Bus ID', bus.id),
            _detailRow('Name', bus.name),
            _detailRow('Driver', bus.driver),
            _detailRow('Capacity', bus.capacity.toString()),
            _detailRow('Route', bus.route),
            _detailRow('Status', bus.status),
            _detailRow('Last Maintenance', bus.lastMaintenance),
          ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showChangeStatusDialog(BuildContext context, MockBus bus) {
    String selectedStatus = bus.status;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'Active',
                groupValue: selectedStatus,
                onChanged: (value) => setState(() => selectedStatus = value!),
                title: const Text('Active'),
              ),
              RadioListTile<String>(
                value: 'Maintenance',
                groupValue: selectedStatus,
                onChanged: (value) => setState(() => selectedStatus = value!),
                title: const Text('Maintenance'),
              ),
              RadioListTile<String>(
                value: 'Inactive',
                groupValue: selectedStatus,
                onChanged: (value) => setState(() => selectedStatus = value!),
                title: const Text('Inactive'),
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
              onChangeStatus(selectedStatus);
              Navigator.pop(context);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showScheduleMaintenanceDialog(BuildContext context, MockBus bus) {
    DateTime? selectedDate;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Maintenance'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
                child: Text(selectedDate == null
                    ? 'Pick a date'
                    : 'Selected: ${selectedDate!.toLocal().toString().split(' ')[0]}'),
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
              if (selectedDate != null) {
                onScheduleMaintenance(
                    selectedDate!.toLocal().toString().split(' ')[0]);
              }
              Navigator.pop(context);
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _showRemoveBusDialog(BuildContext context, MockBus bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Bus'),
        content: Text('Are you sure you want to remove ${bus.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              onRemove();
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class BusDetailsScreen extends StatefulWidget {
  final MockBus bus;
  final void Function(MockBus updated) onEdit;
  final VoidCallback onToggleTracking;
  final void Function(String date) onScheduleMaintenance;
  final void Function(String driver) onAssignDriver;
  const BusDetailsScreen({
    Key? key,
    required this.bus,
    required this.onEdit,
    required this.onToggleTracking,
    required this.onScheduleMaintenance,
    required this.onAssignDriver,
  }) : super(key: key);

  @override
  State<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isTracking;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isTracking = widget.bus.isTracking;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(widget.bus.name,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: Colors.grey[500],
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.primaryColor.withOpacity(0.1),
                  ),
                  indicatorPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Tracking'),
                    Tab(text: 'Maintenance'),
                    Tab(text: 'Assignments'),
                  ],
                ),
                const Divider(height: 1, thickness: 1),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF6F8FB),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTrackingTab(),
          _buildMaintenanceTab(),
          _buildAssignmentsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final bus = widget.bus;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.confirmation_number, 'Bus ID', bus.id),
                _infoRow(Icons.person, 'Driver', bus.driver),
                _infoRow(Icons.event_seat, 'Capacity', bus.capacity.toString()),
                _infoRow(Icons.alt_route, 'Route', bus.route),
                _infoRow(Icons.verified, 'Status', bus.status),
                _infoRow(Icons.build, 'Last Maintenance', bus.lastMaintenance),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onEdit(bus),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Bus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 22),
          const SizedBox(width: 16),
          Text('$label:',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildTrackingTab() {
    // Mock location history with street/landmark names
    final mockLocationHistory = [
      {'time': '2024-06-01 08:00', 'location': 'Main St & 5th Ave'},
      {'time': '2024-06-02 08:01', 'location': 'Central Station'},
      {'time': '2024-06-03 08:02', 'location': 'City Park Entrance'},
      {'time': '2024-06-04 08:03', 'location': 'Elm St & 10th Ave'},
      {'time': '2024-06-05 08:04', 'location': 'North Campus Loop'},
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(
                  top: 32, left: 16, right: 16, bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    _TrackingStatusDot(isActive: _isTracking),
                    const SizedBox(width: 12),
                    Text(
                      _isTracking
                          ? 'Tracking is ACTIVE'
                          : 'Tracking is INACTIVE',
                      style: TextStyle(
                        fontSize: 18,
                        color: _isTracking ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _isTracking = !_isTracking);
                        widget.onToggleTracking();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isTracking ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                          _isTracking ? 'Stop Tracking' : 'Start Tracking'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.map, size: 48, color: Colors.blueGrey),
                    SizedBox(height: 8),
                    Text('Map goes here (mock)',
                        style: TextStyle(color: Colors.blueGrey)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text('Location History (mock):',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mockLocationHistory.length,
                itemBuilder: (context, i) => Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading:
                        const Icon(Icons.location_on, color: Colors.blueGrey),
                    title: Text(mockLocationHistory[i]['time']!),
                    subtitle: Text(mockLocationHistory[i]['location']!),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return Center(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: const SizedBox(
          height: 200,
          width: 400,
          child: Center(
              child: Text('Maintenance history and scheduling (mock)',
                  style: TextStyle(fontSize: 16))),
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Center(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: const SizedBox(
          height: 200,
          width: 400,
          child: Center(
              child: Text('Driver and route assignments history (mock)',
                  style: TextStyle(fontSize: 16))),
        ),
      ),
    );
  }
}

class _TrackingStatusDot extends StatefulWidget {
  final bool isActive;
  const _TrackingStatusDot({Key? key, required this.isActive})
      : super(key: key);

  @override
  State<_TrackingStatusDot> createState() => _TrackingStatusDotState();
}

class _TrackingStatusDotState extends State<_TrackingStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
        ),
      );
    }
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent,
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
