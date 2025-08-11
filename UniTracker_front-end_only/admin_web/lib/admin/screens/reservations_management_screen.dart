import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/admin/services/admin_data_service.dart';

class ReservationsManagementScreen extends StatefulWidget {
  const ReservationsManagementScreen({Key? key}) : super(key: key);

  @override
  State<ReservationsManagementScreen> createState() =>
      _ReservationsManagementScreenState();
}

class _ReservationsManagementScreenState
    extends State<ReservationsManagementScreen> {
  String _search = '';
  String _statusFilter = 'All';
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;
  int _rowsPerPage = 10;
  int? _hoveredRowIndex;

  final List<String> _statusOptions = ['All', 'confirmed', 'cancelled', 'completed'];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      final reservations = await AdminDataService().getAllReservations();
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reservations: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get filteredReservations {
    var reservations = _reservations;
    
    if (_statusFilter != 'All') {
      reservations = reservations.where((r) => r['status'] == _statusFilter).toList();
    }
    
    if (_search.isNotEmpty) {
      reservations = reservations.where((r) =>
          (r['userName']?.toString().toLowerCase().contains(_search.toLowerCase()) ?? false) ||
          (r['userEmail']?.toString().toLowerCase().contains(_search.toLowerCase()) ?? false) ||
          (r['studentId']?.toString().toLowerCase().contains(_search.toLowerCase()) ?? false) ||
          (r['routeName']?.toString().toLowerCase().contains(_search.toLowerCase()) ?? false)
      ).toList();
    }
    
    return reservations;
  }

  Future<void> _updateReservationStatus(String reservationId, String newStatus) async {
    try {
      await AdminDataService().updateReservationStatus(
        reservationId: reservationId,
        status: newStatus,
      );
      await _loadReservations(); // Reload data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservation status updated to $newStatus'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update reservation: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteReservation(String reservationId) async {
    try {
      await AdminDataService().deleteReservation(reservationId);
      await _loadReservations(); // Reload data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reservation deleted'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete reservation: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 54),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reservations Management',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage student bus reservations',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _loadReservations,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Filters and Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by student name, email, ID, or route...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) => setState(() => _search = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Status Filter',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _statusOptions.map((status) => 
                          DropdownMenuItem(value: status, child: Text(status))
                        ).toList(),
                        onChanged: (value) => setState(() => _statusFilter = value ?? 'All'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reservations Table
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 2, child: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Route', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Seat', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      
                      // Table Body
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredReservations.length,
                        itemBuilder: (context, index) {
                          final reservation = filteredReservations[index];
                          return MouseRegion(
                            onEnter: (_) => setState(() => _hoveredRowIndex = index),
                            onExit: (_) => setState(() => _hoveredRowIndex = null),
                            child: Container(
                              color: _hoveredRowIndex == index 
                                  ? AppTheme.primaryColor.withOpacity(0.05)
                                  : null,
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reservation['userName']?.toString() ?? 'N/A',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          reservation['userEmail']?.toString() ?? 'N/A',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          'ID: ${reservation['studentId']?.toString() ?? 'N/A'}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reservation['routeName']?.toString() ?? 'N/A',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '${reservation['pickupStop']} → ${reservation['dropStop']}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(reservation['reservationDate']?.toString() ?? 'N/A'),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(reservation['seatNumber']?.toString() ?? 'N/A'),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: _StatusBadge(status: reservation['status']?.toString() ?? 'unknown'),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        if (reservation['status'] != 'cancelled')
                                          IconButton(
                                            icon: const Icon(Icons.cancel, color: Colors.orange),
                                            tooltip: 'Cancel',
                                            onPressed: () => _updateReservationStatus(
                                              reservation['id'], 'cancelled'
                                            ),
                                          ),
                                        if (reservation['status'] == 'confirmed')
                                          IconButton(
                                            icon: const Icon(Icons.check_circle, color: Colors.green),
                                            tooltip: 'Complete',
                                            onPressed: () => _updateReservationStatus(
                                              reservation['id'], 'completed'
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Delete',
                                          onPressed: () => _deleteReservation(reservation['id']),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
