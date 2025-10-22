import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_web/theme/app_theme.dart';
import '../models/mock_buses.dart';
import 'package:admin_web/utils/responsive_utils.dart';

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
  int? _hoveredRowIndex;

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
    _showToast('Bus ${bus.name} added successfully',
        color: AppTheme.successColor);
  }

  void _editBus(MockBus bus, MockBus updated) {
    setState(() {
      final idx = _buses.indexWhere((b) => b.id == bus.id);
      if (idx != -1) _buses[idx] = updated;
    });
    _showToast('Bus ${updated.name} updated successfully',
        color: AppTheme.primaryColor);
  }

  void _removeBus(MockBus bus) {
    setState(() {
      _buses.removeWhere((b) => b.id == bus.id);
    });
    _showToast('Bus ${bus.name} deleted', color: AppTheme.errorColor);
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
          color: tracking ? AppTheme.successColor : AppTheme.errorColor,
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
    _showToast('Status updated for ${bus.name}', color: AppTheme.primaryColor);
  }

  void _scheduleMaintenance(MockBus bus, String date) {
    setState(() {
      final idx = _buses.indexWhere((b) => b.id == bus.id);
      if (idx != -1) {
        _buses[idx] = _buses[idx].copyWith(lastMaintenance: date);
      }
    });
    _showToast('Maintenance scheduled for ${bus.name}',
        color: AppTheme.primaryColor);
  }

  void _assignDriver(MockBus bus, String driver) {
    setState(() {
      final idx = _buses.indexWhere((b) => b.id == bus.id);
      if (idx != -1) {
        _buses[idx] = _buses[idx].copyWith(driver: driver);
      }
    });
    _showToast('Driver assigned to ${bus.name}', color: AppTheme.primaryColor);
  }

  void _reportIssue(MockBus bus, String issue) {
    _showToast('Issue reported for ${bus.name}', color: AppTheme.warningColor);
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
    SizeConfig.init(context);
    double width = SizeConfig.screenWidth;
    bool isMobile = width < 600;
    bool isTablet = width < 900;

    Widget tableView = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Bus ID', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Name', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Driver', style: _headerStyle())),
                Expanded(
                    flex: 1, child: Text('Capacity', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Route', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Status', style: _headerStyle())),
                Expanded(
                    flex: 2,
                    child: Text('Last Maintenance', style: _headerStyle())),
                SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          // Rows
          ...filteredBuses.take(_rowsPerPage).map((bus) {
            return Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text(bus.id,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15))),
                      Expanded(
                          flex: 2,
                          child: Text(bus.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15))),
                      Expanded(
                          flex: 2,
                          child: Text(bus.driver,
                              style: const TextStyle(fontSize: 15))),
                      Expanded(
                          flex: 1,
                          child: Text(bus.capacity.toString(),
                              style: const TextStyle(fontSize: 15))),
                      Expanded(
                          flex: 2,
                          child: Text(bus.route,
                              style: const TextStyle(fontSize: 15))),
                      Expanded(
                          flex: 2,
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: _StatusBadge(status: bus.status))),
                      Expanded(
                          flex: 2,
                          child: Text(bus.lastMaintenance,
                              style: const TextStyle(fontSize: 15))),
                      SizedBox(
                        width: 40,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _BusActionsMenu(
                            bus: bus,
                            onEdit: (updated) => _editBus(bus, updated),
                            onRemove: () => _removeBus(bus),
                            onChangeStatus: (status) =>
                                _changeStatus(bus, status),
                            onScheduleMaintenance: (date) =>
                                _scheduleMaintenance(bus, date),
                            onViewDetails: () => _showBusDetails(bus),
                            onAssignDriver: (driver) =>
                                _assignDriver(bus, driver),
                            onReportIssue: (issue) => _reportIssue(bus, issue),
                            onViewHistory: () => _viewHistory(bus),
                            onShowAddEditBusDialog: (bus) =>
                                _showAddEditBusDialog(bus: bus),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              ],
            );
          }).toList(),
        ],
      ),
    );

    Widget cardListView = Column(
      children: filteredBuses
          .take(_rowsPerPage)
          .map((bus) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _BusCard(
                  bus: bus,
                  onEdit: (updated) => _editBus(bus, updated),
                  onRemove: () => _removeBus(bus),
                  onChangeStatus: (status) => _changeStatus(bus, status),
                  onScheduleMaintenance: (date) =>
                      _scheduleMaintenance(bus, date),
                  onViewDetails: () => _showBusDetails(bus),
                  onAssignDriver: (driver) => _assignDriver(bus, driver),
                  onReportIssue: (issue) => _reportIssue(bus, issue),
                  onViewHistory: () => _viewHistory(bus),
                  onShowAddEditBusDialog: (bus) =>
                      _showAddEditBusDialog(bus: bus),
                ),
              ))
          .toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Buses',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
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
              // Responsive filter/search controls
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search buses...',
                        hintStyle:
                            TextStyle(color: AppTheme.secondaryTextColor),
                        prefixIcon: Icon(Icons.search,
                            color: AppTheme.secondaryTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                      ),
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _statusFilter ?? 'All',
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        ...statusOptions.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) =>
                          setState(() => _statusFilter = v == 'All' ? null : v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _routeFilter ?? 'All',
                      decoration: InputDecoration(
                        labelText: 'Route',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        ...mockRoutes.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) =>
                          setState(() => _routeFilter = v == 'All' ? null : v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _driverFilter ?? 'All',
                      decoration: InputDecoration(
                        labelText: 'Driver',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        ...mockDrivers.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) =>
                          setState(() => _driverFilter = v == 'All' ? null : v),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddEditBusDialog(),
                        icon: const Icon(Icons.add,
                            size: 20, color: Colors.white),
                        label: const Text('Add Bus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search buses...',
                          hintStyle:
                              TextStyle(color: AppTheme.secondaryTextColor),
                          prefixIcon: Icon(Icons.search,
                              color: AppTheme.secondaryTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey, width: 0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey, width: 0.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey, width: 0.5),
                          ),
                          filled: true,
                          fillColor: AppTheme.cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                        ),
                        onChanged: (value) => setState(() => _search = value),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: DropdownButton<String>(
                        value: _statusFilter ?? 'All',
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          ...statusOptions.map((s) =>
                              DropdownMenuItem(value: s, child: Text(s))),
                        ],
                        onChanged: (v) => setState(
                            () => _statusFilter = v == 'All' ? null : v),
                        hint: const Text('Status'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButton<String>(
                        value: _routeFilter ?? 'All',
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          ...mockRoutes.map((s) =>
                              DropdownMenuItem(value: s, child: Text(s))),
                        ],
                        onChanged: (v) => setState(
                            () => _routeFilter = v == 'All' ? null : v),
                        hint: const Text('Route'),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: DropdownButton<String>(
                        value: _driverFilter ?? 'All',
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          ...mockDrivers.map((s) =>
                              DropdownMenuItem(value: s, child: Text(s))),
                        ],
                        onChanged: (v) => setState(
                            () => _driverFilter = v == 'All' ? null : v),
                        hint: const Text('Driver'),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddEditBusDialog(),
                        icon: const Icon(Icons.add,
                            size: 20, color: Colors.white),
                        label: const Text('Add Bus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              if (isMobile)
                cardListView
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth < 700 ? 0 : 700,
                      maxWidth: constraints.maxWidth,
                    ),
                    child: tableView,
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
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 20, child: Text('20')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                      DropdownMenuItem(value: 100, child: Text('100')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _rowsPerPage = value);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  TextStyle _headerStyle() => TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 0.3,
        color: AppTheme.secondaryTextColor,
      );

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
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: AppTheme.secondaryTextColor),
          filled: true,
          fillColor: AppTheme.secondaryColor,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppTheme.textColor,
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
                            color: AppTheme.textColor,
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
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppTheme.primaryColor,
                                    onPrimary: AppTheme.cardColor,
                                    onSurface: AppTheme.textColor,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            maintenanceDate = picked;
                            (context as Element).markNeedsBuild();
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
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
                            foregroundColor: AppTheme.textColor,
                            side: BorderSide(
                                color: AppTheme.primaryColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: AppTheme.cardColor,
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
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppTheme.primaryColor,
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
    Color bg;
    Color fg;
    if (status == 'Active') {
      bg = const Color(0xFF22C55E);
      fg = Colors.white;
    } else if (status == 'Maintenance') {
      bg = Colors.transparent;
      fg = const Color(0xFFF59E42);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: status == 'Maintenance'
            ? Border.all(color: const Color(0xFFF59E42), width: 1)
            : null,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ),
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
      icon: const Icon(Icons.more_horiz, color: Color(0xFF64748B)),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          enabled: false,
          height: 36,
          child: SizedBox(
            width: 145,
            child: Text('Actions',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          height: 36,
          child: SizedBox(
              width: 145,
              child: Text('View details', style: TextStyle(fontSize: 14))),
        ),
        PopupMenuItem<int>(
          value: 1,
          height: 36,
          child: SizedBox(
              width: 145,
              child: Text('Edit bus', style: TextStyle(fontSize: 14))),
        ),
        PopupMenuItem<int>(
          value: 6,
          height: 36,
          child: SizedBox(
              width: 145,
              child: Text('Change status', style: TextStyle(fontSize: 14))),
        ),
        PopupMenuItem<int>(
          value: 3,
          height: 36,
          child: SizedBox(
              width: 145,
              child:
                  Text('Schedule maintenance', style: TextStyle(fontSize: 14))),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 5,
          height: 36,
          child: SizedBox(
            width: 145,
            child: Text(
              'Delete bus',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 0:
            onViewDetails();
            break;
          case 1:
            onShowAddEditBusDialog(bus);
            break;
          case 6:
            // Show dialog with radio buttons for status
            String selectedStatus = bus.status;
            final result = await showDialog<String>(
              context: context,
              builder: (context) {
                String tempStatus = selectedStatus;
                return StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    backgroundColor: AppTheme.cardColor,
                    title: Text('Change Status',
                        style: TextStyle(color: AppTheme.textColor)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: statusOptions
                          .map((status) => RadioListTile<String>(
                                value: status,
                                groupValue: tempStatus,
                                title: Text(status,
                                    style: TextStyle(
                                      color: tempStatus == status
                                          ? AppTheme.primaryColor
                                          : AppTheme.secondaryTextColor,
                                      fontWeight: tempStatus == status
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    )),
                                activeColor: AppTheme.primaryColor,
                                selected: tempStatus == status,
                                onChanged: (v) =>
                                    setState(() => tempStatus = v!),
                              ))
                          .toList(),
                    ),
                    actions: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, tempStatus);
                        },
                        child: const Text('Change'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
            if (result != null && result != bus.status) {
              onChangeStatus(result);
            }
            break;
          case 3:
            // Schedule maintenance date picker
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              onScheduleMaintenance(picked.toIso8601String().split('T').first);
            }
            break;
          case 5:
            _showRemoveBusDialog(context, bus, onRemove);
            break;
        }
      },
    );
  }

  void _showRemoveBusDialog(
      BuildContext context, MockBus bus, void Function() onRemove) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus'),
        content: Text('Are you sure you want to delete ${bus.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onRemove();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
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
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey[500],
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal, fontSize: 17),
                  indicator: FixedWidthTabIndicator(
                    width: 36,
                    height: 4,
                    color: AppTheme.primaryColor,
                    radius: 2,
                  ),
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
      backgroundColor: Colors.white,
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
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: AppTheme.primaryColor.withOpacity(0.08), width: 1.2),
          ),
          margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          color: AppTheme.cardColor,
          shadowColor: AppTheme.primaryColor.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...[
                  _infoRow(Icons.confirmation_number, 'Bus ID', bus.id),
                  _infoRow(Icons.person, 'Driver', bus.driver),
                  _infoRow(
                      Icons.event_seat, 'Capacity', bus.capacity.toString()),
                  _infoRow(Icons.alt_route, 'Route', bus.route),
                  _infoRow(Icons.verified, 'Status', bus.status,
                      status: bus.status),
                  _infoRow(
                      Icons.build, 'Last Maintenance', bus.lastMaintenance),
                ]
                    .expand((row) =>
                        [row, const Divider(height: 24, thickness: 0.7)])
                    .toList()
                    .sublist(0, 11),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onEdit(bus),
                    icon: Icon(Icons.edit, color: AppTheme.primaryColor),
                    label: Text('Edit Bus',
                        style: TextStyle(color: AppTheme.primaryColor)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppTheme.cardColor,
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

  Widget _infoRow(IconData icon, String label, String value, {String? status}) {
    Color? statusColor;
    if (status != null) {
      if (status == 'Active')
        statusColor = AppTheme.successColor;
      else if (status == 'Maintenance')
        statusColor = AppTheme.warningColor;
      else if (status == 'Inactive') statusColor = AppTheme.secondaryTextColor;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: statusColor ?? AppTheme.primaryColor, size: 22),
          const SizedBox(width: 16),
          Text('$label:',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.textColor)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: TextStyle(fontSize: 16, color: AppTheme.textColor))),
        ],
      ),
    );
  }

  Widget _buildTrackingTab() {
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
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              margin: const EdgeInsets.only(
                  top: 36, left: 20, right: 20, bottom: 20),
              color: AppTheme.cardColor,
              shadowColor: AppTheme.primaryColor.withOpacity(0.10),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
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
                        color: _isTracking
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
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
                        backgroundColor: _isTracking
                            ? AppTheme.errorColor
                            : AppTheme.successColor,
                        foregroundColor: AppTheme.cardColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: Text(
                          _isTracking ? 'Stop Tracking' : 'Start Tracking'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppTheme.cardColor,
              child: Container(
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 54, color: AppTheme.primaryColor),
                    const SizedBox(height: 12),
                    Text('Map goes here (mock)',
                        style:
                            TextStyle(color: AppTheme.textColor, fontSize: 16)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              child: Text('Location History (mock):',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                      fontSize: 17)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: mockLocationHistory.length,
                itemBuilder: (context, i) => Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: AppTheme.cardColor,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 4,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading:
                          Icon(Icons.location_on, color: AppTheme.primaryColor),
                      title: Text(mockLocationHistory[i]['time']!,
                          style: TextStyle(
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(mockLocationHistory[i]['location']!,
                          style: TextStyle(color: AppTheme.secondaryTextColor)),
                    ),
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
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        color: AppTheme.cardColor,
        child: SizedBox(
          height: 220,
          width: 420,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build, color: AppTheme.primaryColor, size: 40),
              const SizedBox(height: 18),
              Text('Maintenance history and scheduling (mock)',
                  style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        color: AppTheme.cardColor,
        child: SizedBox(
          height: 220,
          width: 420,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_ind,
                  color: AppTheme.primaryColor, size: 40),
              const SizedBox(height: 18),
              Text('Driver and route assignments history (mock)',
                  style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
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

class FixedWidthTabIndicator extends Decoration {
  final double width;
  final double height;
  final Color color;
  final double radius;

  const FixedWidthTabIndicator({
    required this.width,
    this.height = 4,
    required this.color,
    this.radius = 2,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FixedWidthPainter(this);
  }
}

class _FixedWidthPainter extends BoxPainter {
  final FixedWidthTabIndicator decoration;

  _FixedWidthPainter(this.decoration);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration config) {
    final Paint paint = Paint()
      ..color = decoration.color
      ..style = PaintingStyle.fill;
    final double x = offset.dx + (config.size!.width - decoration.width) / 2;
    final double y = offset.dy + config.size!.height - decoration.height;
    final Rect rect = Rect.fromLTWH(x, y, decoration.width, decoration.height);
    final RRect rRect =
        RRect.fromRectAndRadius(rect, Radius.circular(decoration.radius));
    canvas.drawRRect(rRect, paint);
  }
}

class _BusCard extends StatelessWidget {
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

  const _BusCard({
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bus.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                _StatusBadge(status: bus.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('ID: ${bus.id}', style: const TextStyle(fontSize: 15)),
            Text('Driver: ${bus.driver}', style: const TextStyle(fontSize: 15)),
            Text('Capacity: ${bus.capacity}',
                style: const TextStyle(fontSize: 15)),
            Text('Route: ${bus.route}', style: const TextStyle(fontSize: 15)),
            Text('Last Maintenance: ${bus.lastMaintenance}',
                style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Details',
                  onPressed: onViewDetails,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () => onShowAddEditBusDialog(bus),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
