import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/widgets/animated_widgets.dart';
import '../services/admin_data_service.dart';
import 'package:intl/intl.dart';

class DriverDetailScreen extends StatefulWidget {
  final Map<String, dynamic> driver;

  const DriverDetailScreen({
    Key? key,
    required this.driver,
  }) : super(key: key);

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  Map<String, dynamic>? _tripStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadTripStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTripStats() async {
    try {
      final stats = await AdminDataService()
          .getDriverTripStats(widget.driver['driverId']);
      if (mounted) {
        setState(() {
          _tripStats = stats;
          _isLoading = false;
        });
      }
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Driver Details',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDriverProfile(),
                    const SizedBox(height: 24),
                    _buildTripStatistics(),
                    const SizedBox(height: 24),
                    _buildRecentTrips(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDriverProfile() {
    final driver = widget.driver;
    final isActive = driver['isActive'] == true;

    return AnimatedWidgets.modernCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isActive
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  child: Icon(
                    Icons.person_rounded,
                    color: isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver['fullName'] ?? 'Unknown Driver',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Driver ID: ${driver['driverId'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : const Color(0xFFF59E0B).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
                'Phone', driver['phone'] ?? 'N/A', Icons.phone_rounded),
            const SizedBox(height: 8),
            _buildInfoRow('License', driver['licenseNumber'] ?? 'N/A',
                Icons.card_membership_rounded),
            if (driver['licenseExpiration'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('License Expires', driver['licenseExpiration'],
                  Icons.calendar_today_rounded),
            ],
            const SizedBox(height: 8),
            _buildInfoRow('Joined', _formatDate(driver['createdAt']),
                Icons.event_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF64748B),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripStatistics() {
    if (_tripStats == null) return const SizedBox.shrink();

    final stats = _tripStats!;

    return AnimatedWidgets.modernCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: const Color(0xFF3B82F6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Trip Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Trips',
                    '${stats['totalTrips']}',
                    Icons.route_rounded,
                    const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    '${stats['completedTrips']}',
                    Icons.check_circle_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'On Time Rate',
                    '${stats['onTimeRate']}%',
                    Icons.schedule_rounded,
                    const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'On Time Trips',
                    '${stats['onTimeTrips']}',
                    Icons.timer_rounded,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrips() {
    if (_tripStats == null || (_tripStats!['recentTrips'] as List).isEmpty) {
      return AnimatedWidgets.modernCard(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: Column(
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 48,
                  color: Color(0xFF64748B),
                ),
                SizedBox(height: 16),
                Text(
                  'No trips recorded yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final recentTrips = _tripStats!['recentTrips'] as List;

    return AnimatedWidgets.modernCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  color: const Color(0xFF3B82F6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recent Trips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recentTrips.map<Widget>((trip) => _buildTripItem(trip)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTripItem(Map<String, dynamic> trip) {
    final isCompleted = trip['status'] == 'completed';
    final isOnTime = trip['onTime'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? (isOnTime ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted
                  ? (isOnTime
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1))
                  : const Color(0xFF64748B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: isCompleted
                  ? (isOnTime
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B))
                  : const Color(0xFF64748B),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip['routeName'] ?? 'Unknown Route',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${_formatDate(trip['tripDate'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isCompleted ? 'Completed' : 'In Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? (isOnTime
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B))
                      : const Color(0xFF64748B),
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 2),
                Text(
                  isOnTime ? 'On Time' : 'Late',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOnTime
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
