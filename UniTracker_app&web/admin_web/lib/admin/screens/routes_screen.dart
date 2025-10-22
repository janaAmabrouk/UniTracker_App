import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/admin/models/mock_buses.dart';
import 'package:admin_web/admin/models/bus_stop.dart';

import '../models/mock_buses.dart';

// Mock data for routes
class MockRoute {
  final String id;
  final String name;
  final int stops;
  final String distance;
  final String frequency;
  final int activeBuses;
  final String status;

  MockRoute({
    required this.id,
    required this.name,
    required this.stops,
    required this.distance,
    required this.frequency,
    required this.activeBuses,
    required this.status,
  });
}

final mockRoutesData = [
  MockRoute(
    id: 'R-101',
    name: 'North Campus Loop',
    stops: 8,
    distance: '3.2 miles',
    frequency: '10 min',
    activeBuses: 3,
    status: 'active',
  ),
  MockRoute(
    id: 'R-102',
    name: 'South Campus Loop',
    stops: 6,
    distance: '2.8 miles',
    frequency: '12 min',
    activeBuses: 2,
    status: 'active',
  ),
  MockRoute(
    id: 'R-103',
    name: 'East Campus Loop',
    stops: 5,
    distance: '2.5 miles',
    frequency: '15 min',
    activeBuses: 1,
    status: 'active',
  ),
  MockRoute(
    id: 'R-104',
    name: 'West Campus Loop',
    stops: 7,
    distance: '3.0 miles',
    frequency: '12 min',
    activeBuses: 2,
    status: 'active',
  ),
  MockRoute(
    id: 'R-105',
    name: 'Downtown Connector',
    stops: 10,
    distance: '5.5 miles',
    frequency: '20 min',
    activeBuses: 2,
    status: 'active',
  ),
  MockRoute(
    id: 'R-106',
    name: 'Weekend Express',
    stops: 4,
    distance: '4.2 miles',
    frequency: '30 min',
    activeBuses: 0,
    status: 'inactive',
  ),
];

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({Key? key}) : super(key: key);

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  String _search = '';
  late List<MockRoute> _routes;
  int? _hoveredRowIndex;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _routes = List<MockRoute>.from(mockRoutesData);
  }

  List<MockRoute> get filteredRoutes {
    if (_search.isEmpty) return _routes;
    return _routes.where((route) {
      return route.id.toLowerCase().contains(_search.toLowerCase()) ||
          route.name.toLowerCase().contains(_search.toLowerCase());
    }).toList();
  }

  void _showToast(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _addRoute(MockRoute route) {
    setState(() {
      _routes.insert(0, route);
    });
    _showToast('Route ${route.name} added successfully',
        color: AppTheme.successColor);
  }

  void _editRoute(MockRoute route, MockRoute updated) {
    setState(() {
      final idx = _routes.indexWhere((r) => r.id == route.id);
      if (idx != -1) _routes[idx] = updated;
    });
    _showToast('Route ${updated.name} updated successfully',
        color: AppTheme.primaryColor);
  }

  void _removeRoute(MockRoute route) {
    setState(() {
      _routes.removeWhere((r) => r.id == route.id);
    });
    _showToast('Route ${route.name} deleted', color: AppTheme.errorColor);
  }

  void _changeStatus(MockRoute route, String status) {
    setState(() {
      final idx = _routes.indexWhere((r) => r.id == route.id);
      if (idx != -1) {
        _routes[idx] = MockRoute(
          id: route.id,
          name: route.name,
          stops: route.stops,
          distance: route.distance,
          frequency: route.frequency,
          activeBuses: route.activeBuses,
          status: status,
        );
      }
    });
    _showToast('Status updated for ${route.name}',
        color: AppTheme.primaryColor);
  }

  void _showAddEditRouteDialog({MockRoute? route}) {
    final isEdit = route != null;
    final nameController = TextEditingController(text: route?.name ?? '');
    final idController =
        TextEditingController(text: route?.id ?? _suggestRouteId());
    final stopsController =
        TextEditingController(text: route?.stops.toString() ?? '');
    final distanceController =
        TextEditingController(text: route?.distance ?? '');
    final frequencyController =
        TextEditingController(text: route?.frequency ?? '');
    final activeBusesController =
        TextEditingController(text: route?.activeBuses.toString() ?? '');
    String status = route?.status ?? 'active';
    final formKey = GlobalKey<FormState>();

    InputDecoration fieldDecoration(String label, IconData icon) =>
        InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppTheme.secondaryTextColor,
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
                    isEdit ? 'Edit ${route!.id}' : 'Add New Route',
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
                    decoration: fieldDecoration('Name', Icons.alt_route),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: idController,
                    enabled: !isEdit,
                    decoration:
                        fieldDecoration('Route ID', Icons.confirmation_number),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: stopsController,
                    decoration:
                        fieldDecoration('Number of Stops', Icons.location_on),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Must be a number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: distanceController,
                    decoration: fieldDecoration('Distance', Icons.directions),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: frequencyController,
                    decoration: fieldDecoration('Frequency', Icons.access_time),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (v) => status = v!,
                    decoration: fieldDecoration('Status', Icons.verified),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.secondaryTextColor,
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
                              final newRoute = MockRoute(
                                id: idController.text,
                                name: nameController.text,
                                stops: int.parse(stopsController.text),
                                distance: distanceController.text,
                                frequency: frequencyController.text,
                                activeBuses: route?.activeBuses ?? 0,
                                status: status,
                              );
                              if (isEdit) {
                                _editRoute(route!, newRoute);
                              } else {
                                _addRoute(newRoute);
                              }
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.cardColor,
                            elevation: 2,
                            shadowColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isEdit ? 'Save' : 'Add Route'),
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

  String _suggestRouteId() {
    int maxId = 1;
    for (final route in _routes) {
      final match = RegExp(r'R-(\d+)').firstMatch(route.id);
      if (match != null) {
        final num = int.tryParse(match.group(1)!);
        if (num != null && num > maxId) maxId = num;
      }
    }
    return 'R-${(maxId + 1).toString().padLeft(3, '0')}';
  }

  void _showAssignBusesDialog(MockRoute route) {
    final List<Map<String, dynamic>> mockBuses = [
      {'id': 'BUS-101', 'name': 'Bus 101'},
      {'id': 'BUS-102', 'name': 'Bus 102'},
      {'id': 'BUS-103', 'name': 'Bus 103'},
      {'id': 'BUS-104', 'name': 'Bus 104'},
      {'id': 'BUS-105', 'name': 'Bus 105'},
      {'id': 'BUS-106', 'name': 'Bus 106'},
    ];
    final Set<String> initiallyAssigned =
        mockBuses.take(route.activeBuses).map((b) => b['id'] as String).toSet();
    final ValueNotifier<Set<String>> assignedBuses =
        ValueNotifier<Set<String>>(Set.from(initiallyAssigned));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Assign Buses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Select buses to assign to this route:'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ValueListenableBuilder<Set<String>>(
                    valueListenable: assignedBuses,
                    builder: (context, assigned, _) {
                      return ListView(
                        children: mockBuses.map((bus) {
                          return CheckboxListTile(
                            value: assigned.contains(bus['id']),
                            onChanged: (checked) {
                              final newSet = Set<String>.from(assigned);
                              if (checked == true) {
                                newSet.add(bus['id'] as String);
                              } else {
                                newSet.remove(bus['id'] as String);
                              }
                              assignedBuses.value = newSet;
                            },
                            title: Text(bus['name']),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppTheme.primaryColor,
                            checkColor: AppTheme.cardColor,
                            fillColor:
                                MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.selected)) {
                                return AppTheme.primaryColor;
                              }
                              return AppTheme.secondaryColor;
                            }),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondaryTextColor,
                        side: BorderSide(
                            color: AppTheme.primaryColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: AppTheme.cardColor,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        final count = assignedBuses.value.length;
                        _changeActiveBuses(route, count);
                        Navigator.pop(context);
                        _showToast('Assigned $count buses to ${route.name}',
                            color: AppTheme.successColor);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.cardColor,
                        elevation: 2,
                        shadowColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save Assignments'),
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

  void _changeActiveBuses(MockRoute route, int newCount) {
    setState(() {
      final idx = _routes.indexWhere((r) => r.id == route.id);
      if (idx != -1) {
        _routes[idx] = MockRoute(
          id: route.id,
          name: route.name,
          stops: route.stops,
          distance: route.distance,
          frequency: route.frequency,
          activeBuses: newCount,
          status: route.status,
        );
      }
    });
  }

  void _showViewStopsDialog(BuildContext context, MockRoute route) {
    print('DEBUG: _showViewStopsDialog called for route: \'${route.name}\'');
    // Find the real stops for this route by name
    final busRoute = mockBusRoutes.firstWhere(
      (r) => r.name == route.name,
      orElse: () => null as dynamic,
    );
    List<BusStop> stops = busRoute?.stops ?? [];
    if (stops.length > route.stops) {
      stops = stops.sublist(0, route.stops);
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Stops for \'${route.name}\'',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (stops.isEmpty)
                  Text('No stops found for this route.',
                      style: TextStyle(color: AppTheme.errorColor)),
                if (stops.isNotEmpty)
                  Flexible(
                    child: ListView.separated(
                      itemCount: stops.length,
                      separatorBuilder: (context, i) => const Divider(),
                      itemBuilder: (context, i) {
                        final stop = stops[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(stop.order.toString(),
                                style: TextStyle(color: AppTheme.cardColor)),
                          ),
                          title: Text(stop.name,
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (stop.arrivalTime != null)
                                Text('Arrival: \'${stop.arrivalTime}\''),
                              if (stop.departureTime != null)
                                Text('Departure: \'${stop.departureTime}\''),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondaryTextColor,
                        side: BorderSide(
                            color: AppTheme.primaryColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: AppTheme.cardColor,
                      ),
                      child: const Text('Close'),
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

  void _showRouteDetailsDialog(BuildContext context, MockRoute route) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Route Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: route.status),
                  ],
                ),
                const SizedBox(height: 18),
                _detailRow('Route ID', route.id),
                _detailRow('Name', route.name),
                _detailRow('Number of Stops', route.stops.toString()),
                _detailRow('Distance', route.distance),
                _detailRow('Frequency', route.frequency),
                _detailRow('Active Buses', route.activeBuses.toString()),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                // Mock statistics
                Row(
                  children: [
                    Icon(Icons.people, size: 20, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text('Daily Passengers: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('~1200'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer, size: 20, color: AppTheme.warningColor),
                    SizedBox(width: 8),
                    Text('Avg. Delay: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('3 min'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 20, color: AppTheme.successColor),
                    SizedBox(width: 8),
                    Text('Peak Hours: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('7-9 AM, 4-6 PM'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 18, color: AppTheme.secondaryTextColor),
                    SizedBox(width: 8),
                    Text('Created: ',
                        style: TextStyle(color: AppTheme.textColor)),
                    Text(
                        DateFormat('yyyy-MM-dd').format(
                            DateTime.now().subtract(const Duration(days: 120))),
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.edit_calendar,
                        size: 18, color: AppTheme.secondaryTextColor),
                    SizedBox(width: 8),
                    Text('Last Modified: ',
                        style: TextStyle(color: AppTheme.textColor)),
                    Text(
                        DateFormat('yyyy-MM-dd').format(
                            DateTime.now().subtract(const Duration(days: 2))),
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondaryTextColor,
                        side: BorderSide(
                            color: AppTheme.primaryColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: AppTheme.cardColor,
                      ),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Future.delayed(Duration.zero, () {
                          _showViewStopsDialog(context, route);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.cardColor,
                        elevation: 2,
                        shadowColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('View Stops'),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Routes',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Manage and monitor all routes in the system.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search routes...',
                        hintStyle:
                            TextStyle(color: AppTheme.secondaryTextColor),
                        prefixIcon: Icon(Icons.search,
                            color: AppTheme.secondaryTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 8),
                      ),
                      onChanged: (value) => setState(() => _search = value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddEditRouteDialog(),
                      icon:
                          Icon(Icons.add, size: 20, color: AppTheme.cardColor),
                      label: Text('Add Route'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.cardColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text('Route ID',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: AppTheme.secondaryTextColor))),
                          Expanded(
                              flex: 3,
                              child: Text('Name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: AppTheme.secondaryTextColor))),
                          Expanded(
                              flex: 1,
                              child: Text('Stops',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: AppTheme.secondaryTextColor))),
                          Expanded(
                              flex: 2,
                              child: Text('Distance',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: AppTheme.secondaryTextColor))),
                          Expanded(
                              flex: 2,
                              child: Text('Frequency',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: AppTheme.secondaryTextColor))),
                          Expanded(
                              flex: 2,
                              child: Text('Active Buses',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: AppTheme.secondaryTextColor))),
                          Expanded(
                              flex: 2,
                              child: Text('Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: AppTheme.secondaryTextColor))),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                    // Rows
                    ...filteredRoutes.take(_rowsPerPage).map((route) {
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 24),
                            color: Colors.white,
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: Text(route.id,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15))),
                                Expanded(
                                    flex: 3,
                                    child: Text(route.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15))),
                                Expanded(
                                    flex: 1,
                                    child: Text(route.stops.toString(),
                                        style: const TextStyle(fontSize: 15))),
                                Expanded(
                                    flex: 2,
                                    child: Text(route.distance,
                                        style: const TextStyle(fontSize: 15))),
                                Expanded(
                                    flex: 2,
                                    child: Text(route.frequency,
                                        style: const TextStyle(fontSize: 15))),
                                Expanded(
                                    flex: 2,
                                    child: Text(route.activeBuses.toString(),
                                        style: const TextStyle(fontSize: 15))),
                                Expanded(
                                    flex: 2,
                                    child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _StatusBadge(
                                            status: route.status))),
                                SizedBox(
                                  width: 40,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _RouteActionsMenu(
                                      route: route,
                                      onEdit: (updated) =>
                                          _editRoute(route, updated),
                                      onRemove: () => _removeRoute(route),
                                      onChangeStatus: (status) =>
                                          _changeStatus(route, status),
                                      onShowAddEditRouteDialog: (route) =>
                                          _showAddEditRouteDialog(route: route),
                                      onAssignBuses: (route) =>
                                          _showAssignBusesDialog(route),
                                      onViewStops: (route) {
                                        Future.delayed(Duration.zero, () {
                                          _showViewStopsDialog(context, route);
                                        });
                                      },
                                      onViewDetails: (route) =>
                                          _showRouteDetailsDialog(
                                              context, route),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE5E7EB)),
                        ],
                      );
                    }).toList(),
                  ],
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
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'active':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.successColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Active',
            style: TextStyle(
              color: AppTheme.cardColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
        );
      case 'inactive':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Inactive',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.secondaryTextColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
        );
    }
  }
}

class _RouteActionsMenu extends StatelessWidget {
  final MockRoute route;
  final void Function(MockRoute updated) onEdit;
  final void Function() onRemove;
  final void Function(String status) onChangeStatus;
  final void Function(MockRoute route) onShowAddEditRouteDialog;
  final void Function(MockRoute route) onAssignBuses;
  final void Function(MockRoute route) onViewStops;
  final void Function(MockRoute route) onViewDetails;
  const _RouteActionsMenu({
    Key? key,
    required this.route,
    required this.onEdit,
    required this.onRemove,
    required this.onChangeStatus,
    required this.onShowAddEditRouteDialog,
    required this.onAssignBuses,
    required this.onViewStops,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: Icon(Icons.more_horiz, color: AppTheme.secondaryTextColor),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          enabled: false,
          height: 36,
          child: SizedBox(
            width: 90,
            child: Text('Actions',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textColor)),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          height: 36,
          child: SizedBox(
              width: 90,
              child: Text('View details', style: TextStyle(fontSize: 14))),
        ),
        PopupMenuItem<int>(
          value: 1,
          height: 36,
          child: SizedBox(
              width: 90,
              child: Text('Edit route', style: TextStyle(fontSize: 14))),
        ),
        PopupMenuItem<int>(
          value: 2,
          height: 36,
          child: SizedBox(
              width: 90,
              child: Text('View stops', style: TextStyle(fontSize: 14))),
        ),
        PopupMenuItem<int>(
          value: 3,
          height: 36,
          child: SizedBox(
              width: 90,
              child: Text('Assign buses', style: TextStyle(fontSize: 14))),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 4,
          height: 36,
          child: SizedBox(
            width: 90,
            child: Text(
              'Delete route',
              style: TextStyle(color: AppTheme.errorColor, fontSize: 14),
            ),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 0:
            onViewDetails(route);
            break;
          case 1:
            onShowAddEditRouteDialog(route);
            break;
          case 2:
            onViewStops(route);
            break;
          case 3:
            onAssignBuses(route);
            break;
          case 4:
            _showRemoveRouteDialog(context, route);
            break;
        }
      },
    );
  }

  void _showRemoveRouteDialog(BuildContext context, MockRoute route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete ${route.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
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
