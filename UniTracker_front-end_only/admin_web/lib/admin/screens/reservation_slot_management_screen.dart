import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/admin/widgets/animated_widgets.dart';
import 'package:admin_web/admin/services/admin_data_service.dart';
import 'package:intl/intl.dart';

class ReservationSlot {
  final String id;
  final String direction;
  final String routeId;
  final String routeName;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> times; // HH:mm
  final String busId;
  final String busNumber;
  final int capacity;

  ReservationSlot({
    required this.id,
    required this.direction,
    required this.routeId,
    required this.routeName,
    required this.startDate,
    required this.endDate,
    required this.times,
    required this.busId,
    required this.busNumber,
    required this.capacity,
  });
}

class ReservationSlotManagementScreen extends StatefulWidget {
  const ReservationSlotManagementScreen({Key? key}) : super(key: key);

  @override
  State<ReservationSlotManagementScreen> createState() =>
      _ReservationSlotManagementScreenState();
}

class _ReservationSlotManagementScreenState
    extends State<ReservationSlotManagementScreen> {
  List<ReservationSlot> _reservationSlots = [];
  String _direction = 'To University';
  String? _routeId;
  String? _routeName;
  DateTime? _startDate;
  DateTime? _endDate;
  List<TimeOfDay> _times = [];
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _buses = [];
  String? _selectedBusId;
  int? _selectedBusCapacity;
  String? _selectedBusNumber;
  List<Map<String, dynamic>> _routes = [];
  bool _isLoadingBuses = false;
  bool _isLoadingRoutes = false;
  bool _isLoadingSlots = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoadingBuses = true;
      _isLoadingRoutes = true;
      _isLoadingSlots = true;
    });
    try {
      final buses = await AdminDataService().getAllBuses();
      final routes = await AdminDataService().getAllRoutes();
      await _fetchSlots(routes: routes, buses: buses);
      setState(() {
        _buses = buses;
        _routes = routes;
        _isLoadingBuses = false;
        _isLoadingRoutes = false;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBuses = false;
        _isLoadingRoutes = false;
        _isLoadingSlots = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  Future<void> _fetchSlots(
      {List<Map<String, dynamic>>? routes,
      List<Map<String, dynamic>>? buses}) async {
    setState(() => _isLoadingSlots = true);
    try {
      final slotRows = await AdminDataService().getAllReservationSlots();
      final routeList = routes ?? _routes;
      final busList = buses ?? _buses;
      // Group slots by (routeId, direction, busId, date range, times)
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final row in slotRows) {
        final key =
            '${row['route_id']}_${row['direction']}_${row['capacity']}_${row['slot_date']}_${row['slot_time']}_${row['id']}';
        grouped[key] = [row];
      }
      // For this UI, we want to group by (routeId, direction, busId, date range, times)
      // But since DB stores one row per (date, time), we can group by (routeId, direction, busId, capacity)
      final Map<String, List<Map<String, dynamic>>> logicalGroups = {};
      for (final row in slotRows) {
        final groupKey =
            '${row['route_id']}_${row['direction']}_${row['capacity']}_${row['route_id']}_${row['direction']}_${row['capacity']}_${row['route_id']}';
        logicalGroups.putIfAbsent(groupKey, () => []).add(row);
      }
      final List<ReservationSlot> slots = [];
      logicalGroups.forEach((key, rows) {
        if (rows.isEmpty) return;
        final first = rows.first;
        final route = routeList.firstWhere((r) => r['id'] == first['route_id'],
            orElse: () => {});
        final bus = busList.firstWhere(
            (b) => b['capacity'] == first['capacity'],
            orElse: () => {});
        final dates = rows.map((r) => DateTime.parse(r['slot_date'])).toList()
          ..sort();
        final times = rows.map((r) => r['slot_time'] as String).toSet().toList()
          ..sort();
        slots.add(ReservationSlot(
          id: first['id'],
          direction: first['direction'],
          routeId: first['route_id'],
          routeName: route['name']?.toString() ?? 'Unknown',
          startDate: dates.first,
          endDate: dates.last,
          times: times,
          busId: bus['id']?.toString() ?? '',
          busNumber: bus['busNumber']?.toString() ?? '',
          capacity: first['capacity'] ?? 0,
        ));
      });
      setState(() {
        _reservationSlots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() => _isLoadingSlots = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reservation slots: $e')),
      );
    }
  }

  Future<void> _addReservationSlot() async {
    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _endDate != null &&
        _times.isNotEmpty &&
        _routeId != null &&
        _selectedBusId != null &&
        _selectedBusCapacity != null) {
      setState(() => _isSaving = true);
      try {
        await AdminDataService().addReservationSlots(
          routeId: _routeId!,
          direction: _direction,
          startDate: _startDate!,
          endDate: _endDate!,
          times: List<TimeOfDay>.from(_times),
          busId: _selectedBusId!,
          capacity: _selectedBusCapacity!,
        );
        await _fetchSlots();
        setState(() {
          _routeId = null;
          _routeName = null;
          _startDate = null;
          _endDate = null;
          _times = [];
          _selectedBusId = null;
          _selectedBusCapacity = null;
          _selectedBusNumber = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reservation slot added!'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add reservation slot: $e'),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteReservationSlot(ReservationSlot slot) async {
    setState(() => _isSaving = true);
    try {
      await AdminDataService().deleteReservationSlots(
        routeId: slot.routeId,
        direction: slot.direction,
        startDate: slot.startDate,
        endDate: slot.endDate,
        times: slot.times,
      );
      await _fetchSlots();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Reservation slot deleted!'),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to delete reservation slot: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _formatTimeForDisplay(String timeStr) {
    // Handles 'HH:mm:ss' or 'HH:mm'
    try {
      final parts = timeStr.split(":");
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(0, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern header
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2563EB), // Blue 600
                      Color(0xFF60A5FA), // Blue 400
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reservation Slot Management',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Set up and manage available reservation slots for students.',
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
                          Icons.event_available_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Modern form card
            AnimatedWidgets.modernCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    final routeDropdownItems = _routes
                        .map((route) => DropdownMenuItem<String>(
                              value: route['id'],
                              child: Text(route['name'] ?? 'Unknown Route'),
                            ))
                        .toList();
                    final busDropdownItems = _buses
                        .map((bus) => DropdownMenuItem<String>(
                              value: bus['id']?.toString() ?? '',
                              child: Text(
                                  'Bus ${bus['busNumber']?.toString() ?? ''}'),
                            ))
                        .toList();
                    if (isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Direction Toggle
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Direction',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    ToggleButtons(
                                      borderRadius: BorderRadius.circular(8),
                                      isSelected: [
                                        _direction == 'To University',
                                        _direction == 'From University'
                                      ],
                                      onPressed: (index) {
                                        setState(() {
                                          _direction = index == 0
                                              ? 'To University'
                                              : 'From University';
                                        });
                                      },
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text('To University'),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text('From University'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Route Dropdown
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value: _routeId,
                                  decoration:
                                      const InputDecoration(labelText: 'Route'),
                                  items: routeDropdownItems,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Select route'
                                          : null,
                                  onChanged: (value) {
                                    setState(() {
                                      _routeId = value;
                                      _routeName = _routes
                                          .firstWhere((r) => r['id'] == value,
                                              orElse: () => {})['name']
                                          ?.toString();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Date Range Picker
                              Expanded(
                                flex: 3,
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)),
                                      initialDateRange:
                                          _startDate != null && _endDate != null
                                              ? DateTimeRange(
                                                  start: _startDate!,
                                                  end: _endDate!)
                                              : null,
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _startDate = picked.start;
                                        _endDate = picked.end;
                                      });
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Date Range',
                                        suffixIcon: Icon(Icons.date_range),
                                      ),
                                      controller: TextEditingController(
                                        text: _startDate != null &&
                                                _endDate != null
                                            ? '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year} - '
                                                '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
                                            : '',
                                      ),
                                      validator: (value) =>
                                          _startDate == null || _endDate == null
                                              ? 'Select date range'
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Multiple Times Picker
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Times',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          tooltip: 'Add Time',
                                          onPressed: () async {
                                            final picked = await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null &&
                                                !_times.contains(picked)) {
                                              setState(
                                                  () => _times.add(picked));
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      children: _times
                                          .map((t) => Chip(
                                                label: Text(t.format(context)),
                                                onDeleted: () => setState(
                                                    () => _times.remove(t)),
                                              ))
                                          .toList(),
                                    ),
                                    if (_times.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text('Add at least one time',
                                            style: TextStyle(
                                                color: Colors.red[400],
                                                fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Bus Dropdown
                              Expanded(
                                flex: 3,
                                child: _isLoadingBuses
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : DropdownButtonFormField<String>(
                                        value: _selectedBusId,
                                        decoration: const InputDecoration(
                                            labelText: 'Bus'),
                                        items: busDropdownItems,
                                        validator: (value) =>
                                            value == null ? 'Select bus' : null,
                                        onChanged: (value) {
                                          final bus = _buses.firstWhere(
                                              (b) => b['id'] == value,
                                              orElse: () => {});
                                          setState(() {
                                            _selectedBusId = value;
                                            _selectedBusCapacity =
                                                bus['capacity'] ?? 0;
                                            _selectedBusNumber =
                                                bus['busNumber']?.toString() ??
                                                    '';
                                          });
                                        },
                                      ),
                              ),
                              const SizedBox(width: 24),
                              // Add Button
                              ElevatedButton.icon(
                                icon:
                                    const Icon(Icons.add, color: Colors.white),
                                label: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('Add Reservation Slot'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed:
                                    _isSaving ? null : _addReservationSlot,
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // Column layout for mobile/narrow screens
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Direction',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ToggleButtons(
                            borderRadius: BorderRadius.circular(8),
                            isSelected: [
                              _direction == 'To University',
                              _direction == 'From University'
                            ],
                            onPressed: (index) {
                              setState(() {
                                _direction = index == 0
                                    ? 'To University'
                                    : 'From University';
                              });
                            },
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('To University'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('From University'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _routeId,
                            decoration:
                                const InputDecoration(labelText: 'Route'),
                            items: routeDropdownItems,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Select route'
                                : null,
                            onChanged: (value) {
                              setState(() {
                                _routeId = value;
                                _routeName = _routes
                                    .firstWhere((r) => r['id'] == value,
                                        orElse: () => {})['name']
                                    ?.toString();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date Range',
                              suffixIcon: Icon(Icons.date_range),
                            ),
                            controller: TextEditingController(
                              text: _startDate != null && _endDate != null
                                  ? '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year} - '
                                      '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
                                  : '',
                            ),
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                                initialDateRange:
                                    _startDate != null && _endDate != null
                                        ? DateTimeRange(
                                            start: _startDate!, end: _endDate!)
                                        : null,
                              );
                              if (picked != null) {
                                setState(() {
                                  _startDate = picked.start;
                                  _endDate = picked.end;
                                });
                              }
                            },
                            validator: (value) =>
                                _startDate == null || _endDate == null
                                    ? 'Select date range'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Times',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    tooltip: 'Add Time',
                                    onPressed: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null &&
                                          !_times.contains(picked)) {
                                        setState(() => _times.add(picked));
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: _times
                                    .map((t) => Chip(
                                          label: Text(t.format(context)),
                                          onDeleted: () =>
                                              setState(() => _times.remove(t)),
                                        ))
                                    .toList(),
                              ),
                              if (_times.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Add at least one time',
                                      style: TextStyle(
                                          color: Colors.red[400],
                                          fontSize: 12)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _isLoadingBuses
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  value: _selectedBusId,
                                  decoration:
                                      const InputDecoration(labelText: 'Bus'),
                                  items: busDropdownItems,
                                  validator: (value) =>
                                      value == null ? 'Select bus' : null,
                                  onChanged: (value) {
                                    final bus = _buses.firstWhere(
                                        (b) => b['id'] == value,
                                        orElse: () => {});
                                    setState(() {
                                      _selectedBusId = value;
                                      _selectedBusCapacity =
                                          bus['capacity'] ?? 0;
                                      _selectedBusNumber =
                                          bus['busNumber']?.toString() ?? '';
                                    });
                                  },
                                ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Add Reservation Slot'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isSaving ? null : _addReservationSlot,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Available Reservation Slots:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _isLoadingSlots
                ? const Center(child: CircularProgressIndicator())
                : _reservationSlots.isEmpty
                    ? const Text('No slots added yet.',
                        style: TextStyle(color: Colors.grey))
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reservationSlots.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final slot = _reservationSlots[index];
                          final Color slotColor =
                              slot.direction == 'To University'
                                  ? AppTheme.primaryColor
                                  : AppTheme.successColor;
                          final dateRange =
                              '${slot.startDate.year}-${slot.startDate.month.toString().padLeft(2, '0')}-${slot.startDate.day.toString().padLeft(2, '0')}'
                              ' to '
                              '${slot.endDate.year}-${slot.endDate.month.toString().padLeft(2, '0')}-${slot.endDate.day.toString().padLeft(2, '0')}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: AnimatedWidgets.modernCard(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: slotColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.event_seat_rounded,
                                        color: slotColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${slot.direction} - ${slot.routeName}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_rounded,
                                                  color:
                                                      const Color(0xFF94A3B8),
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text(dateRange,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Color(0xFF94A3B8))),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.directions_bus_rounded,
                                                  color:
                                                      const Color(0xFF94A3B8),
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text('Bus: ${slot.busNumber}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Color(0xFF94A3B8))),
                                              const SizedBox(width: 16),
                                              Icon(Icons.people_alt_rounded,
                                                  color: Color(0xFF94A3B8),
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text('Capacity: ${slot.capacity}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Color(0xFF94A3B8))),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_rounded,
                                                  color:
                                                      const Color(0xFF94A3B8),
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              ...slot.times.map((t) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8),
                                                    child: Text(
                                                      _formatTimeForDisplay(t),
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(
                                                              0xFF94A3B8)),
                                                    ),
                                                  )),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedWidgets.scaleButton(
                                      onTap: _isSaving
                                          ? () {}
                                          : () => _deleteReservationSlot(slot),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Color(0xFFEF4444),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
