import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/widgets/animated_widgets.dart';
import '../services/admin_data_service.dart';

class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _onTimeData;
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final stats = await AdminDataService().getDashboardStats();
      final onTimeData = await AdminDataService().getOnTimeRate();
      final alerts = await AdminDataService().getRecentAlerts();

      if (mounted) {
        setState(() {
          _stats = stats;
          _onTimeData = onTimeData;
          _alerts = alerts;
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 32),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRecentAlertsCard(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildQuickActionsCard(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildPerformanceChart(),
          ],
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
              'Loading Dashboard...',
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

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
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
                  'Welcome back, Admin',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening with your university transport today.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'System Performance: Excellent',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': 'Total Buses',
        'value': '${_stats?['totalBuses'] ?? 0}',
        'icon': Icons.directions_bus_rounded,
        'color': const Color(0xFF3B82F6),
        'trend': '+2 this week',
      },
      {
        'title': 'Active Routes',
        'value': '${_stats?['totalRoutes'] ?? 0}',
        'icon': Icons.route_rounded,
        'color': const Color(0xFF10B981),
        'trend': 'All operational',
      },
      {
        'title': 'Total Drivers',
        'value': '${_stats?['totalDrivers'] ?? 0}',
        'icon': Icons.person_rounded,
        'color': const Color(0xFF8B5CF6),
        'trend': '+1 this month',
      },
      {
        'title': 'On-Time Rate',
        'value': '${_onTimeData?['rate'] ?? 95}%',
        'icon': Icons.schedule_rounded,
        'color': const Color(0xFF06B6D4),
        'trend':
            '${_onTimeData?['completedTrips'] ?? 0}/${_onTimeData?['totalTrips'] ?? 0} trips',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        double width = constraints.maxWidth;
        if (width < 600) {
          crossAxisCount = 1;
        } else if (width < 900) {
          crossAxisCount = 2;
        } else if (width < 1200) {
          crossAxisCount = 3;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 0.9,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildStatCard(stat, index);
          },
        );
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, int index) {
    return GestureDetector(
      onTap: () {
        // Add navigation to detailed view
      },
      child: AnimatedWidgets.modernCard(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (stat['color'] as Color).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (stat['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      stat['icon'],
                      color: stat['color'],
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.trending_up,
                    color: const Color(0xFF10B981),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                stat['value'],
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat['title'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stat['trend'],
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAlertsCard() {
    return AnimatedWidgets.modernCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recent Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_alerts.length} alerts',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ..._alerts.take(5).map((alert) => _buildAlertItem(alert)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    Color getAlertColor(String? severity) {
      switch (severity) {
        case 'error':
          return const Color(0xFFEF4444);
        case 'warning':
          return const Color(0xFFF59E0B);
        case 'success':
          return const Color(0xFF10B981);
        default:
          return const Color(0xFF3B82F6);
      }
    }

    IconData getAlertIcon(String? type) {
      switch (type) {
        case 'maintenance':
          return Icons.build_rounded;
        case 'cancellation':
          return Icons.cancel_rounded;
        case 'system':
          return Icons.info_rounded;
        default:
          return Icons.notifications_rounded;
      }
    }

    final color = getAlertColor(alert['severity']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              getAlertIcon(alert['type']),
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert['message'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(alert['time']),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    final actions = [
      {
        'title': 'Add New Bus',
        'icon': Icons.add_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Create Route',
        'icon': Icons.route_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Add Driver',
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'View Reports',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF06B6D4),
      },
    ];

    return AnimatedWidgets.modernCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 24),
            ...actions.map((action) => _buildQuickActionItem(action)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(Map<String, dynamic> action) {
    return AnimatedWidgets.scaleButton(
      onTap: () => _handleQuickAction(action['title']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (action['color'] as Color).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (action['color'] as Color).withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (action['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action['icon'],
                color: action['color'],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              action['title'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF94A3B8),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return AnimatedWidgets.modernCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Real-time Bus Locations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildRealTimeMap(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeMap() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Stack(
        children: [
          // Map background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF06B6D4).withOpacity(0.1),
                  const Color(0xFF3B82F6).withOpacity(0.1),
                ],
              ),
            ),
          ),
          // Simulated bus locations
          ...List.generate(5, (index) => _buildBusMarker(index)),
          // Map controls
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _buildMapControl(Icons.add, 'Zoom In'),
                const SizedBox(height: 8),
                _buildMapControl(Icons.remove, 'Zoom Out'),
                const SizedBox(height: 8),
                _buildMapControl(Icons.my_location, 'Center'),
              ],
            ),
          ),
          // Legend
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(const Color(0xFF10B981), 'Active Buses'),
                  const SizedBox(height: 4),
                  _buildLegendItem(const Color(0xFFF59E0B), 'In Transit'),
                  const SizedBox(height: 4),
                  _buildLegendItem(const Color(0xFFEF4444), 'Delayed'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusMarker(int index) {
    final positions = [
      {
        'left': 50.0,
        'top': 40.0,
        'color': const Color(0xFF10B981),
        'bus': 'BUS-001'
      },
      {
        'left': 120.0,
        'top': 80.0,
        'color': const Color(0xFF10B981),
        'bus': 'BUS-002'
      },
      {
        'left': 200.0,
        'top': 60.0,
        'color': const Color(0xFFF59E0B),
        'bus': 'BUS-003'
      },
      {
        'left': 280.0,
        'top': 100.0,
        'color': const Color(0xFF10B981),
        'bus': 'BUS-004'
      },
      {
        'left': 180.0,
        'top': 140.0,
        'color': const Color(0xFFEF4444),
        'bus': 'BUS-005'
      },
    ];

    if (index >= positions.length) return const SizedBox.shrink();

    final position = positions[index];
    return Positioned(
      left: position['left'] as double,
      top: position['top'] as double,
      child: GestureDetector(
        onTap: () => _showBusInfo(position['bus'] as String),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: position['color'] as Color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: (position['color'] as Color).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMapControl(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 16,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  void _showBusInfo(String busNumber) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.directions_bus_rounded, color: const Color(0xFF06B6D4)),
            const SizedBox(width: 12),
            Text('$busNumber - Live Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Status', 'In Transit', const Color(0xFF10B981)),
            _buildInfoRow('Route', 'Campus to Downtown', null),
            _buildInfoRow('Driver', 'John Smith', null),
            _buildInfoRow('Passengers', '24/50', null),
            _buildInfoRow('Next Stop', 'Main Street Station', null),
            _buildInfoRow('ETA', '5 minutes', const Color(0xFF06B6D4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/buses');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return '';
    try {
      final time = DateTime.parse(timeString);
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (e) {
      return timeString;
    }
  }

  void _handleQuickAction(String actionTitle) {
    switch (actionTitle) {
      case 'Add New Bus':
        _showAddBusDialog();
        break;
      case 'Create Route':
        _showCreateRouteDialog();
        break;
      case 'Add Driver':
        _showAddDriverDialog();
        break;
      case 'View Reports':
        _showReportsDialog();
        break;
    }
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.analytics_rounded, color: const Color(0xFF06B6D4)),
            const SizedBox(width: 12),
            const Text('Reports & Analytics'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportOption(
                'Bus Performance Report', Icons.directions_bus_rounded),
            _buildReportOption('Route Efficiency Report', Icons.route_rounded),
            _buildReportOption(
                'Driver Performance Report', Icons.person_rounded),
            _buildReportOption('Financial Summary', Icons.attach_money_rounded),
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

  Widget _buildReportOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF06B6D4)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title - Coming Soon!')),
        );
      },
    );
  }

  void _showAddBusDialog() async {
    // Load required data for dropdowns
    final routes = await AdminDataService().getAllRoutes();
    final drivers = await AdminDataService().getAllDrivers();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _AddBusDialog(
        routes: routes,
        drivers: drivers,
        onBusAdded: () {
          // Refresh dashboard data if needed
          _loadData();
        },
      ),
    );
  }

  void _showCreateRouteDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _AddRouteDialog(
        onRouteAdded: () {
          // Refresh dashboard data if needed
          _loadData();
        },
      ),
    );
  }

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _AddDriverDialog(
        onDriverAdded: () {
          // Refresh dashboard data if needed
          _loadData();
        },
      ),
    );
  }
}

// Add Bus Dialog Widget - Exact copy from modern_buses_screen.dart
class _AddBusDialog extends StatefulWidget {
  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> drivers;
  final VoidCallback onBusAdded;

  const _AddBusDialog({
    required this.routes,
    required this.drivers,
    required this.onBusAdded,
  });

  @override
  State<_AddBusDialog> createState() => _AddBusDialogState();
}

class _AddBusDialogState extends State<_AddBusDialog> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _capacityController = TextEditingController();

  String _selectedStatus = 'active';
  String? _selectedRouteId;
  String? _selectedDriverId;
  bool _isLoading = false;

  @override
  void dispose() {
    _busNumberController.dispose();
    _plateNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _saveBus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AdminDataService().createBus(
        busNumber: _busNumberController.text,
        plateNumber: _plateNumberController.text,
        capacity: int.parse(_capacityController.text),
        status: _selectedStatus,
        driverId: _selectedDriverId,
        routeId: _selectedRouteId,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onBusAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bus added successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add bus: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Add New Bus',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _busNumberController,
                          decoration: InputDecoration(
                            labelText: 'Bus Number',
                            hintText: 'e.g., BUS-001',
                            prefixIcon: const Icon(Icons.numbers_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter bus number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _plateNumberController,
                          decoration: InputDecoration(
                            labelText: 'Plate Number',
                            hintText: 'e.g., ABC-123',
                            prefixIcon:
                                const Icon(Icons.confirmation_number_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter plate number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    decoration: InputDecoration(
                      labelText: 'Capacity',
                      hintText: 'Number of passengers',
                      prefixIcon: const Icon(Icons.people_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter capacity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedRouteId,
                        decoration: InputDecoration(
                          labelText: 'Route',
                          prefixIcon: const Icon(Icons.route_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No route assigned'),
                          ),
                          ...widget.routes.map((route) => DropdownMenuItem(
                                value: route['id'],
                                child: Text(
                                  route['name'] != null
                                      ? '${route['name']} (${(route['is_active'] == true ? 'Active' : 'Inactive')})'
                                      : 'Unknown Route',
                                ),
                              )),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedRouteId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDriverId,
                        decoration: InputDecoration(
                          labelText: 'Driver',
                          prefixIcon: const Icon(Icons.person_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No driver assigned'),
                          ),
                          ...widget.drivers.map((driver) => DropdownMenuItem(
                                value: driver['id'],
                                child: Text(
                                    driver['fullName'] ?? 'Unknown Driver'),
                              )),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedDriverId = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: const Icon(Icons.info_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'inactive', child: Text('Inactive')),
                      DropdownMenuItem(
                          value: 'maintenance', child: Text('Maintenance')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveBus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Add Bus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Add Route Dialog Widget - Exact copy from modern_routes_screen.dart with bus stops
class _AddRouteDialog extends StatefulWidget {
  final VoidCallback onRouteAdded;

  const _AddRouteDialog({required this.onRouteAdded});

  @override
  State<_AddRouteDialog> createState() => _AddRouteDialogState();
}

class _AddRouteDialogState extends State<_AddRouteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _stopNameController = TextEditingController();
  final _stopTimeController = TextEditingController();

  String _selectedStatus = 'active';
  bool _isLoading = false;
  List<Map<String, dynamic>> _busStops = [];

  @override
  void dispose() {
    _nameController.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _stopNameController.dispose();
    _stopTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Add New Route',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Route Name',
                      hintText: 'e.g., Campus to Downtown',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Route name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pickupController,
                          decoration: const InputDecoration(
                            labelText: 'Pickup Location',
                            hintText: 'e.g., University Campus',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Pickup location is required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _dropController,
                          decoration: const InputDecoration(
                            labelText: 'Drop Location',
                            hintText: 'e.g., Maadi Metro',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Drop location is required';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            hintText: 'e.g., 07:00',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Start time is required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _endTimeController,
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            hintText: 'e.g., 22:00',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'End time is required';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value!),
                  ),
                  const SizedBox(height: 24),
                  _buildBusStopsSection(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Add Route'),
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

  Widget _buildBusStopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Bus Stops',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addBusStop,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Stop'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_busStops.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No bus stops added yet. Click "Add Stop" to add stops.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _busStops.asMap().entries.map((entry) {
                final index = entry.key;
                final stop = entry.value;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: index > 0
                        ? Border(top: BorderSide(color: Colors.grey[200]!))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Arrival: ${stop['time']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeBusStop(index),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        iconSize: 20,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _addBusStop() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bus Stop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _stopNameController,
              decoration: const InputDecoration(
                labelText: 'Stop Name',
                hintText: 'e.g., Shopping Mall',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stopTimeController,
              decoration: const InputDecoration(
                labelText: 'Arrival Time',
                hintText: 'e.g., 08:15',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_stopNameController.text.isNotEmpty &&
                  _stopTimeController.text.isNotEmpty) {
                setState(() {
                  _busStops.add({
                    'name': _stopNameController.text,
                    'time': _stopTimeController.text,
                    'order': _busStops.length + 1,
                  });
                });
                _stopNameController.clear();
                _stopTimeController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeBusStop(int index) {
    setState(() {
      _busStops.removeAt(index);
      // Update order for remaining stops
      for (int i = 0; i < _busStops.length; i++) {
        _busStops[i]['order'] = i + 1;
      }
    });
  }

  Future<void> _addRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AdminDataService().createRouteWithStops(
        name: _nameController.text,
        pickupLocation: _pickupController.text,
        dropLocation: _dropController.text,
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        status: _selectedStatus,
        busStops: _busStops,
      );

      Navigator.pop(context);
      widget.onRouteAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route added successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add route: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Add Driver Dialog Widget
class _AddDriverDialog extends StatefulWidget {
  final VoidCallback onDriverAdded;

  const _AddDriverDialog({required this.onDriverAdded});

  @override
  State<_AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<_AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _saveDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AdminDataService().createDriver(
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        licenseNumber: _licenseController.text,
        status: _isActive ? 'active' : 'inactive',
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onDriverAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver added successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add driver: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_add_rounded,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Add New Driver'),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Driver full name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Contact number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(
                        labelText: 'License Number',
                        hintText: 'Driver license ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter license number';
                        }
                        return null;
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
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveDriver,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Add Driver'),
        ),
      ],
    );
  }
}
