import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitracker/utils/responsive_utils.dart';
import 'package:unitracker/theme/app_theme.dart';
import 'package:unitracker/models/bus_route.dart' as bus_route_model;
import 'package:unitracker/models/bus_stop.dart' as bus_stop_model;
import 'package:intl/intl.dart';
import 'package:unitracker/services/reservation_service.dart';
import 'package:unitracker/widgets/reservation_countdown.dart';
import 'package:unitracker/services/notification_service.dart';

import '../../widgets/toggle_button.dart';

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

  final List<ReservationStep> _steps = [
    ReservationStep(number: '1', title: 'Route', isActive: true),
    ReservationStep(number: '2', title: 'Date', isActive: false),
    ReservationStep(number: '3', title: 'Time', isActive: false),
  ];

  static final List<bus_route_model.BusRoute> _routes = [
    bus_route_model.BusRoute(
      id: 'BA123',
      name: 'Maadi Shuttle',
      pickup: 'Maadi',
      drop: 'University',
      startTime: '07:30 AM',
      endTime: '09:00 AM',
      iconColor: 'E1F6EF',
      stops: [],
    ),
    bus_route_model.BusRoute(
      id: 'SZ',
      name: 'October Shuttle',
      pickup: 'October',
      drop: 'University',
      startTime: '07:45 AM',
      endTime: '09:15 AM',
      iconColor: 'FCF3E2',
      stops: [],
    ),
    bus_route_model.BusRoute(
      id: 'GZ',
      name: 'Giza Shuttle',
      pickup: 'Giza',
      drop: 'University',
      startTime: '07:15 AM',
      endTime: '08:45 AM',
      iconColor: 'FDE8E8',
      stops: [],
    ),
  ];

  List<bus_route_model.BusRoute> get availableRoutes => _routes;

  List<TimeOfDay> get timeSlots {
    if (_selectedRouteType == 'To University') {
      return [
        const TimeOfDay(hour: 9, minute: 0),
        const TimeOfDay(hour: 11, minute: 0),
      ];
    } else {
      return [
        const TimeOfDay(hour: 12, minute: 0),
        const TimeOfDay(hour: 14, minute: 0), // 2 PM
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedRouteType = 'To University'; // Ensure it's set in initState
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        AppBar().preferredSize.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        100, // Approximate height of bottom button
                  ),
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
              DropdownButtonFormField<bus_route_model.BusRoute>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(33),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(33),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(33),
                    borderSide:
                        BorderSide(color: theme.primaryColor, width: 2.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(20),
                    vertical: getProportionateScreenHeight(16),
                  ),
                  isDense: false,
                  hintText: 'Select a route',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: getProportionateScreenWidth(14),
                      ),
                ),
                menuMaxHeight: MediaQuery.of(context).size.height * 0.3,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
                dropdownColor: Colors.white,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                value: routes.contains(_selectedRoute) ? _selectedRoute : null,
                items: routes.map((route) {
                  return DropdownMenuItem<bus_route_model.BusRoute>(
                    value: route,
                    child: Text(
                      route.name,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (route) {
                  setState(() {
                    _selectedRoute = route;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
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
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 7)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: theme.primaryColor,
                        onPrimary: Colors.white,
                        surface: theme.cardColor,
                        onSurface: theme.primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                  _showDateError = false;
                });
              }
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
                children: timeSlots.map((time) {
                  final bool isSelected = _selectedTime?.hour == time.hour &&
                      _selectedTime?.minute == time.minute;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTime = time;
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
                            getProportionateScreenWidth(20)),
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
                        time.format(context),
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
            ],
          ),
        ),
        if (_selectedTime != null &&
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
              dateTime: DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _selectedTime?.hour ?? 0,
                _selectedTime?.minute ?? 0,
              ).toIso8601String(),
              selectedTime: _selectedTime!,
            ),
          ),
      ],
    );
  }

  Future<void> _handleReservation() async {
    if (_selectedRoute == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      return;
    }

    try {
      final reservationService = context.read<ReservationService>();
      final notificationService = context.read<NotificationService>();

      final reservationDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final reservation = await reservationService.createReservation(
        route: _selectedRoute!,
        date: reservationDateTime.toIso8601String(),
        pickupPoint: _selectedRouteType == 'To University'
            ? _selectedRoute!.pickup
            : 'EUI Campus',
        dropPoint: _selectedRouteType == 'To University'
            ? 'EUI Campus'
            : _selectedRoute!.pickup,
      );

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reservation confirmed!'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
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
        canProceed = _selectedTime != null;
        break;
    }

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
