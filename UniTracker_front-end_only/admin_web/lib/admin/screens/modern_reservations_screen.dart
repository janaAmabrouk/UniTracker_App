import 'package:flutter/material.dart';
import 'package:admin_web/admin/services/admin_data_service.dart';
import 'package:admin_web/admin/widgets/animated_widgets.dart';
import 'package:admin_web/admin/widgets/staggered_animations.dart';
import 'reservation_slot_management_screen.dart';
import 'package:intl/intl.dart';

class ModernReservationsScreen extends StatefulWidget {
  const ModernReservationsScreen({super.key});

  @override
  State<ModernReservationsScreen> createState() =>
      _ModernReservationsScreenState();
}

class _ModernReservationsScreenState extends State<ModernReservationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _routeFilter = 'all';
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final reservations = await AdminDataService().getAllReservations();
      final routes = await AdminDataService().getAllRoutes();
      setState(() {
        _reservations = reservations;
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

  List<Map<String, dynamic>> get filteredReservations {
    var filtered = _reservations;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((reservation) {
        final userName =
            reservation['userName']?.toString().toLowerCase() ?? '';
        final routeName =
            reservation['routeName']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return userName.contains(query) || routeName.contains(query);
      }).toList();
    }

    if (_statusFilter != 'all') {
      filtered = filtered
          .where((reservation) => reservation['status'] == _statusFilter)
          .toList();
    }

    if (_routeFilter != 'all') {
      filtered = filtered
          .where((reservation) => reservation['routeName'] == _routeFilter)
          .toList();
    }

    // Filter by selected date
    if (_selectedDate != null) {
      final selectedDateStr = _selectedDate!.toIso8601String().split('T')[0];
      filtered = filtered.where((reservation) {
        final reservationDate =
            reservation['reservationDate']?.toString() ?? '';
        return reservationDate.startsWith(selectedDateStr);
      }).toList();
    }

    return filtered;
  }

  int _getConfirmedReservationsForRouteAndDate() {
    var reservations = _reservations.where((r) => r['status'] == 'confirmed');

    if (_routeFilter != 'all') {
      reservations = reservations.where((r) => r['routeName'] == _routeFilter);
    }

    if (_selectedDate != null) {
      final selectedDateStr = _selectedDate!.toIso8601String().split('T')[0];
      reservations = reservations.where((r) {
        final reservationDate = r['reservationDate']?.toString() ?? '';
        return reservationDate.startsWith(selectedDateStr);
      });
    }

    return reservations.length;
  }

  String _getRouteAndDateDescription() {
    if (_routeFilter != 'all' && _selectedDate != null) {
      return 'Confirmed for route & date';
    } else if (_routeFilter != 'all') {
      return 'Confirmed for route';
    } else if (_selectedDate != null) {
      return 'Confirmed for date';
    } else {
      return 'Select route & date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Reservations'),
              Tab(text: 'Reservation Slots'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReservationsTab(),
              const ReservationSlotManagementScreen(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReservationsTab() {
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
              _buildReservationsList(),
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
              'Loading Reservations...',
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
            const Color(0xFFFF9800),
            const Color(0xFFFF9800).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.3),
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
                  'Reservation Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor and manage student bus reservations and bookings.',
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
              Icons.event_seat_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Row(
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
                    hintText: 'Search reservations by user or route...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
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
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(
                        value: 'confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value!),
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
                  value: _routeFilter,
                  items: [
                    const DropdownMenuItem(
                        value: 'all', child: Text('All Routes')),
                    ..._routes.map((route) => DropdownMenuItem(
                          value: route['name']?.toString() ?? '',
                          child: Text(
                              route['name']?.toString() ?? 'Unknown Route'),
                        )),
                  ],
                  onChanged: (value) => setState(() => _routeFilter = value!),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 200,
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
                controller: _dateController,
                decoration: InputDecoration(
                  hintText: 'Filter by date',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.calendar_today,
                      color: Color(0xFF94A3B8)),
                  suffixIcon: _selectedDate != null
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                              _dateController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                      _dateController.text =
                          '${date.day}/${date.month}/${date.year}';
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final totalReservations = filteredReservations.length;
    final confirmedReservations =
        filteredReservations.where((r) => r['status'] == 'confirmed').length;
    final pendingReservations =
        filteredReservations.where((r) => r['status'] == 'pending').length;
    final cancelledReservations =
        filteredReservations.where((r) => r['status'] == 'cancelled').length;

    // Get confirmed reservations for selected route and date
    final confirmedForRouteAndDate = _getConfirmedReservationsForRouteAndDate();

    final stats = [
      {
        'title': 'Total',
        'value': totalReservations.toString(),
        'icon': Icons.event_seat_rounded,
        'color': const Color(0xFF3B82F6),
        'description': 'Filtered reservations',
      },
      {
        'title': 'Confirmed',
        'value': confirmedReservations.toString(),
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF10B981),
        'description': 'Active bookings',
      },
      {
        'title': 'Route & Date',
        'value': confirmedForRouteAndDate.toString(),
        'icon': Icons.route_rounded,
        'color': const Color(0xFF8B5CF6),
        'description': _getRouteAndDateDescription(),
      },
      {
        'title': 'Cancelled',
        'value': cancelledReservations.toString(),
        'icon': Icons.cancel_rounded,
        'color': const Color(0xFFEF4444),
        'description': 'Cancelled bookings',
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

  Widget _buildReservationsList() {
    if (filteredReservations.isEmpty) {
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
                Icons.event_seat_outlined,
                size: 48,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No reservations found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reservations will appear here when students make bookings',
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
      itemCount: filteredReservations.length,
      itemBuilder: (context, index) {
        final reservation = filteredReservations[index];
        return _buildReservationCard(reservation, index);
      },
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation, int index) {
    Color getStatusColor(String? status) {
      switch (status?.toLowerCase()) {
        case 'confirmed':
          return const Color(0xFF10B981);
        case 'pending':
          return const Color(0xFFF59E0B);
        case 'cancelled':
          return const Color(0xFFEF4444);
        default:
          return const Color(0xFF64748B);
      }
    }

    final statusColor = getStatusColor(reservation['status']);
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
                  Icons.event_seat_rounded,
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
                          reservation['userName'] ?? 'Unknown User',
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
                            reservation['status']?.toString().toUpperCase() ??
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
                          Icons.route_rounded,
                          color: const Color(0xFF64748B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reservation['routeName'] ?? 'Unknown Route',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.event_seat_rounded,
                          color: const Color(0xFF64748B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Seat ${reservation['seatNumber'] ?? 'N/A'}',
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
                          Icons.calendar_today_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reservation['slotDate'] ??
                              reservation['reservationDate'] ??
                              'N/A',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('h:mm a').format(DateFormat('HH:mm:ss')
                              .parse(reservation['slotTime'] ?? '')),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.compare_arrows_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reservation['slotDirection'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.email_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reservation['userEmail'] ?? 'N/A',
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
                    onTap: () => _editReservation(reservation),
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
                    onTap: () => _viewReservationDetails(reservation),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editReservation(Map<String, dynamic> reservation) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditReservationDialog(
        reservation: reservation,
        onSave: (updatedReservation) async {
          try {
            await AdminDataService().updateReservation(updatedReservation);
            if (mounted) {
              _loadData(); // Refresh the list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservation updated successfully'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update reservation: $e'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _viewReservationDetails(Map<String, dynamic> reservation) {
    showDialog(
      context: context,
      builder: (context) => _ViewReservationDialog(reservation: reservation),
    );
  }
}

class _ViewReservationDialog extends StatelessWidget {
  final Map<String, dynamic> reservation;

  const _ViewReservationDialog({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
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
                  child: const Icon(
                    Icons.visibility_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Reservation Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('User Name', reservation['userName'] ?? 'N/A'),
            _buildDetailRow('Email', reservation['userEmail'] ?? 'N/A'),
            _buildDetailRow('Student ID', reservation['studentId'] ?? 'N/A'),
            _buildDetailRow('Route', reservation['routeName'] ?? 'N/A'),
            _buildDetailRow(
                'Seat Number', reservation['seatNumber']?.toString() ?? 'N/A'),
            _buildDetailRow(
                'Slot Date',
                reservation['slotDate'] ??
                    reservation['reservationDate'] ??
                    'N/A'),
            _buildDetailRow('Slot Time', reservation['slotTime'] ?? 'N/A'),
            _buildDetailRow('Direction', reservation['slotDirection'] ?? 'N/A'),
            _buildDetailRow('Slot Capacity',
                reservation['slotCapacity']?.toString() ?? 'N/A'),
            _buildDetailRow('Status', reservation['status'] ?? 'N/A'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditReservationDialog extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final Function(Map<String, dynamic>) onSave;

  const _EditReservationDialog({
    required this.reservation,
    required this.onSave,
  });

  @override
  State<_EditReservationDialog> createState() => _EditReservationDialogState();
}

class _EditReservationDialogState extends State<_EditReservationDialog> {
  late TextEditingController _userNameController;
  late TextEditingController _seatNumberController;
  late String _selectedStatus;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _userNameController =
        TextEditingController(text: widget.reservation['userName'] ?? '');
    _seatNumberController = TextEditingController(
        text: widget.reservation['seatNumber']?.toString() ?? '');
    _selectedStatus = widget.reservation['status'] ?? 'confirmed';
    _selectedDate =
        DateTime.tryParse(widget.reservation['reservationDate'] ?? '') ??
            DateTime.now();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _seatNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Edit Reservation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _userNameController,
              decoration: InputDecoration(
                labelText: 'User Name',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seatNumberController,
              decoration: InputDecoration(
                labelText: 'Seat Number',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: const [
                DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final updatedReservation =
                        Map<String, dynamic>.from(widget.reservation);
                    updatedReservation['userName'] = _userNameController.text;
                    updatedReservation['seatNumber'] =
                        int.tryParse(_seatNumberController.text) ?? 0;
                    updatedReservation['status'] = _selectedStatus;
                    updatedReservation['reservationDate'] =
                        _selectedDate.toIso8601String();

                    widget.onSave(updatedReservation);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
