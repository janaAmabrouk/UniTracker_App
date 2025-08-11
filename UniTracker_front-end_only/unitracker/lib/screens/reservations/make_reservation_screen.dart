import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitracker/utils/responsive_utils.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/models/bus_route.dart' as bus_route_model;
import 'package:unitracker/models/bus_stop.dart' as bus_stop_model;
import 'package:intl/intl.dart';
import 'package:unitracker/services/reservation_service.dart';
import 'package:unitracker/services/supabase_service.dart';
import 'package:unitracker/widgets/reservation_countdown.dart';
import 'package:unitracker/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unitracker/models/driver_notification.dart';

import '../../widgets/toggle_button.dart';
import '../../providers/route_provider.dart';

class ReservationStep {
  final String number;
  final String title;
  bool isActive;

  ReservationStep({
    required this.number,
    required this.title,
    required this.isActive,
  });
}

class ReservationSlotService {
  static Future<List<Map<String, dynamic>>> fetchAvailableSlots({
    String? routeId,
    String? direction,
    DateTime? afterDate,
  }) async {
    final query = Supabase.instance.client
        .from('reservation_slots')
        .select('*')
        .eq('is_active', true);
    if (routeId != null) query.eq('route_id', routeId);
    if (direction != null) query.eq('direction', direction);
    if (afterDate != null)
      query.gte('slot_date', afterDate.toIso8601String().split('T')[0]);
    final response = await query.order('slot_date');
    return List<Map<String, dynamic>>.from(response);
  }
}

class MakeReservationScreen extends StatefulWidget {
  const MakeReservationScreen({super.key});

  @override
  State<MakeReservationScreen> createState() => _MakeReservationScreenState();
}

class _MakeReservationScreenState extends State<MakeReservationScreen> {
  int _currentStep = 0;
  String _selectedRouteType = 'To University';
  bus_route_model.BusRoute? _selectedRoute;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedStop;
  bool _showDateError = false;
  List<Map<String, dynamic>> availableSlots = [];
  String? selectedSlotId;
  Map<String, dynamic>? selectedSlot;

  final List<ReservationStep> _steps = [
    ReservationStep(number: '1', title: 'Route', isActive: true),
    ReservationStep(number: '2', title: 'Date', isActive: false),
    ReservationStep(number: '3', title: 'Time', isActive: false),
  ];

  // Add your exception times here
  final List<TimeOfDay> exceptionTimes = [
    const TimeOfDay(hour: 7, minute: 35),
    const TimeOfDay(hour: 8, minute: 50),
    // Add more exception times as needed
  ];

  List<bus_route_model.BusRoute> get availableRoutes {
    final routeProvider = context.read<RouteProvider>();
    final routes = routeProvider.routes;

    // Debug: print available slots and selected direction
    print('DEBUG: Selected direction: \'$_selectedRouteType\'');
    print('DEBUG: Available slots:');
    for (final slot in availableSlots) {
      print(
          '  slot_id: \'${slot['id']}\', route_id: \'${slot['route_id']}\', direction: \'${slot['direction']}\'');
    }

    // Filter out any null or duplicate routes
    final uniqueRoutes = <String, bus_route_model.BusRoute>{};
    for (final route in routes) {
      if (route.id.isNotEmpty && route.name.isNotEmpty) {
        uniqueRoutes[route.id] = route;
      }
    }

    // Only include routes that have at least one slot for the selected direction
    final filteredRoutes = uniqueRoutes.values.where((route) {
      return availableSlots.any((slot) =>
          slot['route_id'] == route.id &&
          slot['direction'] == _selectedRouteType);
    }).toList();

    print('DEBUG: Filtered routes:');
    for (final route in filteredRoutes) {
      print('  route_id: \'${route.id}\', name: \'${route.name}\'');
    }

    return filteredRoutes;
  }

  List<TimeOfDay> get timeSlots {
    if (_selectedRoute == null) return [];

    if (_selectedRouteType == 'To University') {
      // Parse start time from route
      final startTime = _parseTimeString(_selectedRoute!.startTime);
      return [
        startTime,
        TimeOfDay(
            hour: startTime.hour + 2, minute: startTime.minute), // Add 2 hours
      ];
    } else {
      // Parse end time from route for return trips
      final endTime = _parseTimeString(_selectedRoute!.endTime);
      return [
        endTime,
        TimeOfDay(
            hour: endTime.hour + 2, minute: endTime.minute), // Add 2 hours
      ];
    }
  }

  TimeOfDay _parseTimeString(String timeString) {
    // Handle formats like "9:00 AM", "09:00", etc.
    final cleanTime = timeString.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = cleanTime.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;

      // Adjust for AM/PM if original string contained it
      if (timeString.toLowerCase().contains('pm') && hour < 12) {
        return TimeOfDay(hour: hour + 12, minute: minute);
      }
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 9, minute: 0); // Default fallback
  }

  Future<String> _getPickupPoint() async {
    if (_selectedRoute == null) return 'Unknown';

    // For "To University": pickup is the main pickup location (gate 1)
    // For "From University": pickup is the main drop location (gate 4)
    if (_selectedRouteType == 'To University') {
      return _selectedRoute!.pickup; // gate 1
    } else {
      return _selectedRoute!.drop; // gate 4 (university)
    }
  }

  Future<String> _getDropPoint() async {
    if (_selectedRoute == null) return 'Unknown';

    // For "To University": drop is the main drop location (gate 4)
    // For "From University": drop is the main pickup location (gate 1)
    if (_selectedRouteType == 'To University') {
      return _selectedRoute!.drop; // gate 4 (university)
    } else {
      return _selectedRoute!.pickup; // gate 1
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedRouteType = 'To University'; // Ensure it's set in initState

    // Load routes from Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteProvider>().loadRoutes();
      _fetchSlots();
    });
  }

  Future<void> _fetchSlots() async {
    // Fetch all slots, no filtering
    availableSlots = await ReservationSlotService.fetchAvailableSlots();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: const BackButton(color: Colors.black),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: const Text(
            'Bus Reservations',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(theme),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(16),
                    vertical: getProportionateScreenHeight(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentStepContent(theme),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(16),
        vertical: getProportionateScreenHeight(12),
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerTheme.color ?? const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem(_steps[0], theme),
          _buildStepConnector(_steps[0].isActive && _steps[1].isActive, theme),
          _buildStepItem(_steps[1], theme),
          _buildStepConnector(_steps[1].isActive && _steps[2].isActive, theme),
          _buildStepItem(_steps[2], theme),
        ],
      ),
    );
  }

  Widget _buildStepItem(ReservationStep step, ThemeData theme) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: getProportionateScreenWidth(32),
            height: getProportionateScreenWidth(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.isActive
                  ? theme.primaryColor
                  : theme.colorScheme.surface,
              boxShadow: step.isActive
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                step.number,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: step.isActive ? Colors.white : theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Text(
            step.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: step.isActive
                  ? theme.primaryColor
                  : theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive, ThemeData theme) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 32),
        color: isActive ? theme.primaryColor : theme.dividerTheme.color,
      ),
    );
  }

  Widget _buildCurrentStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildRouteStep();
      case 1:
        return _buildDateStep();
      case 2:
        return _buildTimeStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRouteStep() {
    final theme = Theme.of(context);
    final routes = availableRoutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToggleButtonPair(
          firstText: 'To University',
          firstIcon: Icons.school_outlined,
          secondText: 'From University',
          secondIcon: Icons.apartment_outlined,
          isFirstSelected: _selectedRouteType == 'To University',
          onToggle: (isFirst) {
            setState(() {
              _selectedRouteType =
                  isFirst ? 'To University' : 'From University';
              _selectedRoute = null;
            });
          },
        ),
        SizedBox(height: getProportionateScreenHeight(24)),
        Container(
          padding: EdgeInsets.all(getProportionateScreenWidth(20)),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius:
                BorderRadius.circular(getProportionateScreenWidth(16)),
            border: Border.all(
              color: theme.dividerTheme.color ?? const Color(0xFFEEEEEE),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Route',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                    ),
              ),
              SizedBox(height: getProportionateScreenHeight(16)),
              routes.isEmpty
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(20),
                        vertical: getProportionateScreenHeight(16),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(33),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                                right: getProportionateScreenWidth(12)),
                            padding:
                                EdgeInsets.all(getProportionateScreenWidth(8)),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_bus_rounded,
                              color: Colors.grey,
                              size: getProportionateScreenWidth(20),
                            ),
                          ),
                          Text(
                            'No routes available',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: routes.map((route) {
                        final isSelected = _selectedRoute?.id == route.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRoute = route;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                                bottom: getProportionateScreenHeight(8)),
                            padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(20),
                              vertical: getProportionateScreenHeight(16),
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(33),
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
                                    : Colors.grey.shade300,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(
                                      right: getProportionateScreenWidth(12)),
                                  padding: EdgeInsets.all(
                                      getProportionateScreenWidth(8)),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.primaryColor
                                        : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.directions_bus_rounded,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.primaryColor,
                                    size: getProportionateScreenWidth(20),
                                  ),
                                ),
                                Text(
                                  route.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? theme.primaryColor
                                        : Colors.black87,
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                Spacer(),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: theme.primaryColor,
                                    size: getProportionateScreenWidth(20),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    // Get allowed dates for the selected route and direction
    final allowedDates = availableSlots
        .where((slot) =>
            slot['route_id'] == _selectedRoute?.id &&
            slot['direction'] == _selectedRouteType)
        .map<DateTime>((slot) => DateTime.parse(slot['slot_date']))
        .toSet();

    if (allowedDates.isEmpty) {
      // Optionally show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No available dates for this route and direction.')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: allowedDates.first,
      firstDate: allowedDates.reduce((a, b) => a.isBefore(b) ? a : b),
      lastDate: allowedDates.reduce((a, b) => a.isAfter(b) ? a : b),
      selectableDayPredicate: (date) =>
          allowedDates.contains(DateTime(date.year, date.month, date.day)),
    );

    if (picked != null &&
        allowedDates
            .contains(DateTime(picked.year, picked.month, picked.day))) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildDateStep() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(16)),
        border: Border.all(
          color: theme.dividerTheme.color ?? const Color(0xFFEEEEEE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 16),
          if (_showDateError)
            Container(
              margin: EdgeInsets.only(bottom: getProportionateScreenHeight(16)),
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(12),
                  vertical: getProportionateScreenHeight(8)),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(getProportionateScreenWidth(8)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: getProportionateScreenWidth(16),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  Text(
                    'Please select a valid date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: () async {
              await _selectDate(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(20),
                vertical: getProportionateScreenHeight(12),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(33),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(getProportionateScreenWidth(8)),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: theme.primaryColor,
                      size: getProportionateScreenWidth(20),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(12)),
                  Text(
                    _selectedDate != null
                        ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)
                        : 'Select a date',
                    style: TextStyle(
                      color: _selectedDate != null
                          ? Colors.black
                          : Colors.grey.shade500,
                      fontSize: getProportionateScreenWidth(14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStep() {
    final theme = Theme.of(context);
    // Show available slots for the selected route, direction, and date
    final slotsForDate = availableSlots.where((slot) {
      if (_selectedDate == null) return false;
      return slot['route_id'] == _selectedRoute?.id &&
          slot['direction'] == _selectedRouteType &&
          slot['slot_date'] == DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }).toList();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(getProportionateScreenWidth(20)),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius:
                BorderRadius.circular(getProportionateScreenWidth(16)),
            border: Border.all(
              color: theme.dividerTheme.color ?? const Color(0xFFEEEEEE),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Time',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                    ),
              ),
              SizedBox(height: getProportionateScreenHeight(16)),
              Wrap(
                spacing: getProportionateScreenWidth(8),
                runSpacing: getProportionateScreenHeight(12),
                children: slotsForDate.map((slot) {
                  final slotTime = slot['slot_time'];
                  final isSelected = selectedSlot?['id'] == slot['id'];
                  final time = slotTime != null && slotTime is String
                      ? DateFormat('h:mm a')
                          .format(DateFormat('HH:mm:ss').parse(slotTime))
                      : '';
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSlot = slot;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(20),
                        vertical: getProportionateScreenHeight(10),
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? theme.primaryColor
                              : theme.dividerTheme.color ??
                                  const Color(0xFFEEEEEE),
                        ),
                        borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(33)),
                        color:
                            isSelected ? theme.primaryColor : theme.cardColor,
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                        ],
                      ),
                      child: Text(
                        time,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : theme.textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Add the warning/info box below the time selection
              Padding(
                padding: EdgeInsets.only(top: getProportionateScreenHeight(16)),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(12),
                    vertical: getProportionateScreenHeight(8),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: const Color(0xFFE53935),
                        size: getProportionateScreenWidth(16),
                      ),
                      SizedBox(width: getProportionateScreenWidth(8)),
                      Expanded(
                        child: Text(
                          'Reservations close 2 hours before departure time',
                          style: TextStyle(
                            color: const Color(0xFFE53935),
                            fontSize: getProportionateScreenWidth(12),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (selectedSlot != null &&
            _selectedRoute != null &&
            _selectedDate != null)
          Padding(
            padding: EdgeInsets.only(
              top: getProportionateScreenHeight(24),
              bottom: getProportionateScreenHeight(24),
            ),
            child: ReservationCountdown(
              routeId: _selectedRoute!.id,
              travelDate: _selectedDate!,
              pickupPoint: _selectedRouteType == 'To University'
                  ? _selectedRoute!.pickup
                  : 'EUI Campus',
              dropPoint: _selectedRouteType == 'To University'
                  ? 'EUI Campus'
                  : _selectedRoute!.pickup,
              dateTime: DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                int.tryParse(
                        selectedSlot?['slot_time']?.split(':')[0] ?? '0') ??
                    0,
                int.tryParse(
                        selectedSlot?['slot_time']?.split(':')[1] ?? '0') ??
                    0,
              ).toIso8601String(),
              selectedTime: TimeOfDay(
                hour: int.tryParse(
                        selectedSlot?['slot_time']?.split(':')[0] ?? '0') ??
                    0,
                minute: int.tryParse(
                        selectedSlot?['slot_time']?.split(':')[1] ?? '0') ??
                    0,
              ),
              slotId: selectedSlot?['id'],
              slotCapacity: selectedSlot?['capacity'],
            ),
          ),
      ],
    );
  }

  Future<void> _handleReservation() async {
    print('DEBUG: _handleReservation called');
    if (_selectedRoute == null || selectedSlot == null) {
      print('DEBUG: _selectedRoute or selectedSlot is null');
      return;
    }
    try {
      print('DEBUG: Creating reservation...');
      final reservationService = context.read<ReservationService>();
      await reservationService.createReservation(
        route: _selectedRoute!,
        date: '${selectedSlot!['slot_date']}T${selectedSlot!['slot_time']}',
        pickupPoint: await _getPickupPoint(),
        dropPoint: await _getDropPoint(),
        slotId: selectedSlot!['id'],
      );
      print('DEBUG: Reservation created, loading reservations...');
      await reservationService.loadReservations();
      // Notification is now only handled by the backend and real-time listener
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      final errorMsg = e.toString().contains('unique_user_slot')
          ? 'You already have a reservation for this slot.'
          : 'Failed to create reservation. Please try again.';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reservation Failed'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      final notificationService = context.read<NotificationService>();
      await notificationService.addNotification(
        title: 'Reservation Failed',
        message: errorMsg,
        type: NotificationType.alert,
      );
      if (!mounted) return;
    }
  }

  Widget _buildBottomButton(ThemeData theme) {
    bool canProceed = false;

    switch (_currentStep) {
      case 0:
        canProceed = _selectedRoute != null;
        break;
      case 1:
        canProceed = _selectedDate != null;
        break;
      case 2:
        canProceed = selectedSlot != null;
        break;
    }

    print('DEBUG: canProceed=[32m$canProceed[0m, _currentStep=$_currentStep');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(16),
        vertical: getProportionateScreenHeight(12),
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerTheme.color ?? const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: canProceed
            ? () async {
                if (_currentStep < _steps.length - 1) {
                  setState(() {
                    _currentStep++;
                    _steps[_currentStep].isActive = true;
                  });
                } else {
                  await _handleReservation();
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[500],
          minimumSize: Size(
            double.infinity,
            getProportionateScreenHeight(48),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(33),
          ),
          elevation: 0,
        ),
        child: Text(
          _currentStep < _steps.length - 1 ? 'Next' : 'Confirm Reservation',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
