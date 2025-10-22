import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({Key? key}) : super(key: key);

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startOfWeek = DateTime.now();
  String _routeFilter = 'All Routes';
  String _busFilter = 'All Buses';
  int _selectedDay = 0;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _routes = [
    'All Routes',
    'North Campus Loop',
    'South Campus Loop',
    'East Campus Loop',
    'West Campus Loop',
    'Downtown Connector',
  ];
  final List<String> _buses = [
    'All Buses',
    'Bus 101',
    'Bus 102',
    'Bus 103',
  ];
  final List<String> _drivers = [
    'John Smith',
    'Sarah Johnson',
    'Michael Brown',
    'Emily Davis',
    'Robert Wilson',
    'Anna Lee',
    'Brian Clark',
    'Cathy White',
    'Chris Green',
    'Diana Black',
    'Ethan Brown',
    'Emily White',
    'Frank Green',
    'Grace Lee',
    'David Black',
    'Helen Smith',
    'Ian Brown',
    'Sophia Brown',
    'Jack White',
    'Karen Green',
    'Liam Smith',
    'Mia Brown',
    'Noah Green',
  ];

  final List<Map<String, dynamic>> _mockSchedules = [
    // Monday
    {
      'day': 0,
      'route': 'North Campus Loop',
      'bus': 'Bus 101',
      'driver': 'John Smith',
      'start': '07:00',
      'end': '15:00',
    },
    {
      'day': 0,
      'route': 'South Campus Loop',
      'bus': 'Bus 102',
      'driver': 'Sarah Johnson',
      'start': '07:30',
      'end': '15:30',
    },
    {
      'day': 0,
      'route': 'East Campus Loop',
      'bus': 'Bus 103',
      'driver': 'Michael Brown',
      'start': '08:00',
      'end': '16:00',
    },
    {
      'day': 0,
      'route': 'Downtown Connector',
      'bus': 'Bus 104',
      'driver': 'Alice Green',
      'start': '09:00',
      'end': '17:00',
    },
    // Tuesday
    {
      'day': 1,
      'route': 'West Campus Loop',
      'bus': 'Bus 101',
      'driver': 'Anna Lee',
      'start': '09:00',
      'end': '17:00',
    },
    {
      'day': 1,
      'route': 'North Campus Loop',
      'bus': 'Bus 102',
      'driver': 'Brian Clark',
      'start': '10:00',
      'end': '18:00',
    },
    {
      'day': 1,
      'route': 'South Campus Loop',
      'bus': 'Bus 103',
      'driver': 'Cathy White',
      'start': '11:00',
      'end': '19:00',
    },
    // Wednesday
    {
      'day': 2,
      'route': 'Downtown Connector',
      'bus': 'Bus 102',
      'driver': 'Chris Green',
      'start': '10:00',
      'end': '18:00',
    },
    {
      'day': 2,
      'route': 'East Campus Loop',
      'bus': 'Bus 104',
      'driver': 'Diana Black',
      'start': '12:00',
      'end': '20:00',
    },
    {
      'day': 2,
      'route': 'West Campus Loop',
      'bus': 'Bus 105',
      'driver': 'Ethan Brown',
      'start': '13:00',
      'end': '21:00',
    },
    // Thursday
    {
      'day': 3,
      'route': 'North Campus Loop',
      'bus': 'Bus 103',
      'driver': 'Emily White',
      'start': '11:00',
      'end': '19:00',
    },
    {
      'day': 3,
      'route': 'South Campus Loop',
      'bus': 'Bus 104',
      'driver': 'Frank Green',
      'start': '12:00',
      'end': '20:00',
    },
    {
      'day': 3,
      'route': 'East Campus Loop',
      'bus': 'Bus 105',
      'driver': 'Grace Lee',
      'start': '13:00',
      'end': '21:00',
    },
    // Friday
    {
      'day': 4,
      'route': 'South Campus Loop',
      'bus': 'Bus 101',
      'driver': 'David Black',
      'start': '12:00',
      'end': '20:00',
    },
    {
      'day': 4,
      'route': 'Downtown Connector',
      'bus': 'Bus 102',
      'driver': 'Helen Smith',
      'start': '13:00',
      'end': '21:00',
    },
    {
      'day': 4,
      'route': 'West Campus Loop',
      'bus': 'Bus 103',
      'driver': 'Ian Brown',
      'start': '14:00',
      'end': '22:00',
    },
    // Saturday
    {
      'day': 5,
      'route': 'East Campus Loop',
      'bus': 'Bus 102',
      'driver': 'Sophia Brown',
      'start': '13:00',
      'end': '21:00',
    },
    {
      'day': 5,
      'route': 'North Campus Loop',
      'bus': 'Bus 104',
      'driver': 'Jack White',
      'start': '14:00',
      'end': '22:00',
    },
    {
      'day': 5,
      'route': 'South Campus Loop',
      'bus': 'Bus 105',
      'driver': 'Karen Green',
      'start': '15:00',
      'end': '23:00',
    },
    // Sunday
    {
      'day': 6,
      'route': 'West Campus Loop',
      'bus': 'Bus 103',
      'driver': 'Liam Smith',
      'start': '14:00',
      'end': '22:00',
    },
    {
      'day': 6,
      'route': 'Downtown Connector',
      'bus': 'Bus 104',
      'driver': 'Mia Brown',
      'start': '15:00',
      'end': '23:00',
    },
    {
      'day': 6,
      'route': 'East Campus Loop',
      'bus': 'Bus 105',
      'driver': 'Noah Green',
      'start': '16:00',
      'end': '00:00',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _startOfWeek = _getStartOfWeek(DateTime.now());
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _changeWeek(int delta) {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: 7 * delta));
    });
  }

  List<Map<String, dynamic>> _getSchedulesForDay(int day) {
    return _mockSchedules.where((s) {
      final matchesDay = s['day'] == day;
      final matchesRoute =
          _routeFilter == 'All Routes' || s['route'] == _routeFilter;
      final matchesBus = _busFilter == 'All Buses' || s['bus'] == _busFilter;
      return matchesDay && matchesRoute && matchesBus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = DateFormat('MMM d').format(_startOfWeek);
    final weekEnd = DateFormat('MMM d, yyyy')
        .format(_startOfWeek.add(const Duration(days: 6)));
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isVerySmall = width < 400;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          color: AppTheme.backgroundColor,
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      color: AppTheme.textColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'View and manage all bus schedules for the week.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                // Maximally flexible filters
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 44,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Color(0xFFE5EAF1), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left,
                                            size: 22, color: Color(0xFF222222)),
                                        splashRadius: 22,
                                        onPressed: () => _changeWeek(-1),
                                        padding: EdgeInsets.zero,
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            '$weekStart - $weekEnd',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF222222),
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right,
                                            size: 22, color: Color(0xFF222222)),
                                        splashRadius: 22,
                                        onPressed: () => _changeWeek(1),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButton2<String>(
                            isExpanded: true,
                            value: _routeFilter,
                            iconStyleData: const IconStyleData(
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 20, color: Color(0xFF94A3B8)),
                            ),
                            selectedItemBuilder: (context) => _routes
                                .map((r) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        r,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF222222),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            items: _routes
                                .map((r) => DropdownMenuItem<String>(
                                      value: r,
                                      child: Text(r),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _routeFilter = v!),
                            buttonStyleData: ButtonStyleData(
                              height: 40,
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Color(0xFFE5EAF1), width: 1),
                              ),
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 44,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            dropdownStyleData: DropdownStyleData(
                              width: double.infinity,
                              maxHeight: 300,
                              padding: EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE5EAF1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              elevation: 2,
                            ),
                            underline: SizedBox(),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton2<String>(
                            isExpanded: true,
                            value: _busFilter,
                            iconStyleData: const IconStyleData(
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 20, color: Color(0xFF94A3B8)),
                            ),
                            selectedItemBuilder: (context) => _buses
                                .map((b) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        b,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF222222),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            items: _buses
                                .map((b) => DropdownMenuItem<String>(
                                      value: b,
                                      child: Text(b),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _busFilter = v!),
                            buttonStyleData: ButtonStyleData(
                              height: 40,
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Color(0xFFE5EAF1), width: 1),
                              ),
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 44,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            dropdownStyleData: DropdownStyleData(
                              width: double.infinity,
                              maxHeight: 300,
                              padding: EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE5EAF1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              elevation: 2,
                            ),
                            underline: SizedBox(),
                          ),
                        ],
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Color(0xFFE5EAF1), width: 1),
                                ),
                                child: Center(
                                  child: IconButton(
                                    icon: const Icon(Icons.chevron_left,
                                        size: 22, color: Color(0xFF222222)),
                                    splashRadius: 22,
                                    onPressed: () => _changeWeek(-1),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$weekStart - $weekEnd',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Color(0xFFE5EAF1), width: 1),
                                ),
                                child: Center(
                                  child: IconButton(
                                    icon: const Icon(Icons.chevron_right,
                                        size: 22, color: Color(0xFF222222)),
                                    splashRadius: 22,
                                    onPressed: () => _changeWeek(1),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: isMobile ? double.infinity : 240,
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              value: _routeFilter,
                              iconStyleData: const IconStyleData(
                                icon: Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 20, color: Color(0xFF94A3B8)),
                              ),
                              selectedItemBuilder: (context) => _routes
                                  .map((r) => Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          r,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF222222),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              items: _routes
                                  .map((r) => DropdownMenuItem<String>(
                                        value: r,
                                        child: Text(r),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _routeFilter = v!),
                              buttonStyleData: ButtonStyleData(
                                height: 40,
                                width: isMobile ? double.infinity : 240,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Color(0xFFE5EAF1), width: 1),
                                ),
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 44,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                width: isMobile ? double.infinity : 220,
                                maxHeight: 300,
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE5EAF1)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                elevation: 2,
                              ),
                              underline: SizedBox(),
                            ),
                          ),
                          SizedBox(
                            width: isMobile ? double.infinity : 160,
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              value: _busFilter,
                              iconStyleData: const IconStyleData(
                                icon: Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 20, color: Color(0xFF94A3B8)),
                              ),
                              selectedItemBuilder: (context) => _buses
                                  .map((b) => Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          b,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF222222),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              items: _buses
                                  .map((b) => DropdownMenuItem<String>(
                                        value: b,
                                        child: Text(b),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _busFilter = v!),
                              buttonStyleData: ButtonStyleData(
                                height: 40,
                                width: isMobile ? double.infinity : 160,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Color(0xFFE5EAF1), width: 1),
                                ),
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 44,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                width: isMobile ? double.infinity : 200,
                                maxHeight: 300,
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE5EAF1)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                elevation: 2,
                              ),
                              underline: SizedBox(),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),
                // Responsive day tabs
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: isMobile
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_days.length, (i) {
                              final bool selected = _selectedDay == i;
                              return Flexible(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () =>
                                        setState(() => _selectedDay = i),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      decoration: selected
                                          ? BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppTheme.dividerColor,
                                                width: 1.5,
                                              ),
                                            )
                                          : null,
                                      alignment: Alignment.center,
                                      child: Text(
                                        _days[i],
                                        style: TextStyle(
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          fontSize: 14,
                                          color: selected
                                              ? Colors.black
                                              : AppTheme.secondaryTextColor,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(_days.length, (i) {
                            final bool selected = _selectedDay == i;
                            return Flexible(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(() => _selectedDay = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 4,
                                  ),
                                  decoration: selected
                                      ? BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppTheme.dividerColor,
                                            width: 1.5,
                                          ),
                                        )
                                      : null,
                                  alignment: Alignment.center,
                                  child: Text(
                                    _days[i],
                                    style: TextStyle(
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      fontSize: 14,
                                      color: selected
                                          ? Colors.black
                                          : AppTheme.secondaryTextColor,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                ),
                // Schedules for selected day
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Schedule title and add button
                        isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_days[_selectedDay]}day Schedule',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textColor)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 36,
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _showAddScheduleDialog(context);
                                      },
                                      icon: const Icon(
                                        Icons.add,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      label: const Text('Add Schedule'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 0),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        textStyle: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${_days[_selectedDay]}day Schedule',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textColor)),
                                  SizedBox(
                                    height: 36,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _showAddScheduleDialog(context);
                                      },
                                      icon: const Icon(
                                        Icons.add,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      label: const Text('Add Schedule'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 0),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        textStyle: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 18),
                        ..._getSchedulesForDay(_selectedDay)
                            .map((s) => isVerySmall
                                ? Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppTheme.dividerColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(s['route'],
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppTheme.textColor)),
                                        const SizedBox(height: 4),
                                        Text('${s['bus']} • ${s['driver']}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme
                                                    .secondaryTextColor)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time,
                                                size: 18,
                                                color: Color(0xFF64748B)),
                                            const SizedBox(width: 4),
                                            Text('${s['start']} - ${s['end']}',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textColor)),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 20),
                                              onPressed: () {
                                                final scheduleIndex =
                                                    _mockSchedules.indexOf(s);
                                                _showAddScheduleDialog(context,
                                                    editingIndex: scheduleIndex,
                                                    initialData: s);
                                              },
                                              tooltip: 'Edit',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 20),
                                              onPressed: () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    backgroundColor:
                                                        AppTheme.cardColor,
                                                    title: const Text(
                                                        'Delete Schedule'),
                                                    content: const Text(
                                                        'Are you sure you want to delete this schedule?'),
                                                    actions: [
                                                      OutlinedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        style: OutlinedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              AppTheme
                                                                  .textColor,
                                                          side: BorderSide(
                                                              color: AppTheme
                                                                  .primaryColor),
                                                          backgroundColor:
                                                              AppTheme
                                                                  .cardColor,
                                                        ),
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              AppTheme
                                                                  .errorColor,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                        child: const Text(
                                                            'Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  setState(() {
                                                    _mockSchedules.remove(s);
                                                  });
                                                }
                                              },
                                              tooltip: 'Delete',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                : isMobile
                                    ? Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: AppTheme.dividerColor),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(s['route'],
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: AppTheme.textColor)),
                                            const SizedBox(height: 4),
                                            Text('${s['bus']} • ${s['driver']}',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppTheme
                                                        .secondaryTextColor)),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time,
                                                    size: 18,
                                                    color: Color(0xFF64748B)),
                                                const SizedBox(width: 4),
                                                Text(
                                                    '${s['start']} - ${s['end']}',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: AppTheme
                                                            .textColor)),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      size: 20),
                                                  onPressed: () {
                                                    final scheduleIndex =
                                                        _mockSchedules
                                                            .indexOf(s);
                                                    _showAddScheduleDialog(
                                                        context,
                                                        editingIndex:
                                                            scheduleIndex,
                                                        initialData: s);
                                                  },
                                                  tooltip: 'Edit',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 20),
                                                  onPressed: () async {
                                                    final confirm =
                                                        await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        backgroundColor:
                                                            AppTheme.cardColor,
                                                        title: const Text(
                                                            'Delete Schedule'),
                                                        content: const Text(
                                                            'Are you sure you want to delete this schedule?'),
                                                        actions: [
                                                          OutlinedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    false),
                                                            style:
                                                                OutlinedButton
                                                                    .styleFrom(
                                                              foregroundColor:
                                                                  AppTheme
                                                                      .textColor,
                                                              side: BorderSide(
                                                                  color: AppTheme
                                                                      .primaryColor),
                                                              backgroundColor:
                                                                  AppTheme
                                                                      .cardColor,
                                                            ),
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    true),
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  AppTheme
                                                                      .errorColor,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                            child: const Text(
                                                                'Delete'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      setState(() {
                                                        _mockSchedules
                                                            .remove(s);
                                                      });
                                                    }
                                                  },
                                                  tooltip: 'Delete',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: AppTheme.dividerColor),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(s['route'],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: AppTheme
                                                            .textColor)),
                                                const SizedBox(height: 4),
                                                Text(
                                                    '${s['bus']} • ${s['driver']}',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: AppTheme
                                                            .secondaryTextColor)),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.access_time,
                                                        size: 18,
                                                        color:
                                                            Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                        '${s['start']} - ${s['end']}',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: AppTheme
                                                                .textColor)),
                                                  ],
                                                ),
                                                const SizedBox(width: 16),
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      size: 20),
                                                  onPressed: () {
                                                    final scheduleIndex =
                                                        _mockSchedules
                                                            .indexOf(s);
                                                    _showAddScheduleDialog(
                                                        context,
                                                        editingIndex:
                                                            scheduleIndex,
                                                        initialData: s);
                                                  },
                                                  tooltip: 'Edit',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 20),
                                                  onPressed: () async {
                                                    final confirm =
                                                        await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        backgroundColor:
                                                            AppTheme.cardColor,
                                                        title: const Text(
                                                            'Delete Schedule'),
                                                        content: const Text(
                                                            'Are you sure you want to delete this schedule?'),
                                                        actions: [
                                                          OutlinedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    false),
                                                            style:
                                                                OutlinedButton
                                                                    .styleFrom(
                                                              foregroundColor:
                                                                  AppTheme
                                                                      .textColor,
                                                              side: BorderSide(
                                                                  color: AppTheme
                                                                      .primaryColor),
                                                              backgroundColor:
                                                                  AppTheme
                                                                      .cardColor,
                                                            ),
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    true),
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  AppTheme
                                                                      .errorColor,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                            child: const Text(
                                                                'Delete'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      setState(() {
                                                        _mockSchedules
                                                            .remove(s);
                                                      });
                                                    }
                                                  },
                                                  tooltip: 'Delete',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )),
                      ],
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

  void _showAddScheduleDialog(BuildContext context,
      {int? editingIndex, Map<String, dynamic>? initialData}) {
    final _formKey = GlobalKey<FormState>();
    String? selectedRoute = initialData != null
        ? initialData['route']
        : _routes.firstWhere((r) => r != 'All Routes',
            orElse: () => _routes[1]);
    String? selectedBus = initialData != null
        ? initialData['bus']
        : _buses.firstWhere((b) => b != 'All Buses', orElse: () => _buses[1]);
    String? selectedDriver =
        initialData != null ? initialData['driver'] : _drivers.first;
    TimeOfDay? startTime =
        initialData != null ? _parseTime(initialData['start']) : null;
    TimeOfDay? endTime =
        initialData != null ? _parseTime(initialData['end']) : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Text(editingIndex != null ? 'Edit Schedule' : 'Add Schedule'),
          content: Form(
            key: _formKey,
            child: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedRoute,
                    items: _routes
                        .where((r) => r != 'All Routes')
                        .map((route) => DropdownMenuItem(
                              value: route,
                              child: Text(route),
                            ))
                        .toList(),
                    onChanged: (v) => selectedRoute = v,
                    decoration: const InputDecoration(labelText: 'Route'),
                    validator: (v) => v == null ? 'Select a route' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedBus,
                    items: _buses
                        .where((b) => b != 'All Buses')
                        .map((bus) => DropdownMenuItem(
                              value: bus,
                              child: Text(bus),
                            ))
                        .toList(),
                    onChanged: (v) => selectedBus = v,
                    decoration: const InputDecoration(labelText: 'Bus'),
                    validator: (v) => v == null ? 'Select a bus' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDriver,
                    items: _drivers
                        .map((driver) => DropdownMenuItem(
                              value: driver,
                              child: Text(driver),
                            ))
                        .toList(),
                    onChanged: (v) => selectedDriver = v,
                    decoration: const InputDecoration(labelText: 'Driver'),
                    validator: (v) => v == null ? 'Select a driver' : null,
                    menuMaxHeight: 240,
                    itemHeight: 48,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.access_time,
                              color: AppTheme.primaryColor),
                          label: Text(
                            startTime == null
                                ? 'Start Time'
                                : startTime!.format(context),
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppTheme.primaryColor,
                                      onPrimary: Colors.white,
                                      surface: AppTheme.cardColor,
                                      onSurface: AppTheme.textColor,
                                      background: AppTheme.cardColor,
                                      secondary: AppTheme.secondaryColor,
                                      onSecondary: AppTheme.primaryColor,
                                      secondaryContainer:
                                          AppTheme.secondaryColor,
                                      onSecondaryContainer:
                                          AppTheme.primaryColor,
                                    ),
                                    dialogBackgroundColor: AppTheme.cardColor,
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
                              startTime = picked;
                              (context as Element).markNeedsBuild();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.access_time,
                              color: AppTheme.primaryColor),
                          label: Text(
                            endTime == null
                                ? 'End Time'
                                : endTime!.format(context),
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppTheme.primaryColor,
                                      onPrimary: Colors.white,
                                      surface: AppTheme.cardColor,
                                      onSurface: AppTheme.textColor,
                                      background: AppTheme.cardColor,
                                      secondary: AppTheme.secondaryColor,
                                      onSecondary: AppTheme.primaryColor,
                                      secondaryContainer:
                                          AppTheme.secondaryColor,
                                      onSecondaryContainer:
                                          AppTheme.primaryColor,
                                    ),
                                    dialogBackgroundColor: AppTheme.cardColor,
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
                              endTime = picked;
                              (context as Element).markNeedsBuild();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textColor,
                side: BorderSide(color: AppTheme.primaryColor),
                backgroundColor: AppTheme.cardColor,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate() &&
                    startTime != null &&
                    endTime != null) {
                  setState(() {
                    final newSchedule = {
                      'day': _selectedDay,
                      'route': selectedRoute!,
                      'bus': selectedBus!,
                      'driver': selectedDriver!,
                      'start': startTime!.format(context),
                      'end': endTime!.format(context),
                    };
                    if (editingIndex != null) {
                      _mockSchedules[editingIndex] = newSchedule;
                    } else {
                      _mockSchedules.add(newSchedule);
                    }
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(editingIndex != null ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
