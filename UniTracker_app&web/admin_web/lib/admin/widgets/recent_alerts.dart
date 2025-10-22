import 'package:flutter/material.dart';

class RecentAlerts extends StatefulWidget {
  const RecentAlerts({Key? key}) : super(key: key);

  @override
  State<RecentAlerts> createState() => _RecentAlertsState();
}

class _RecentAlertsState extends State<RecentAlerts> {
  List<Map<String, dynamic>> alerts = [
    {
      'id': 1,
      'title': 'Bus 103 Delayed',
      'description': 'Mechanical issue, estimated 15 min delay',
      'timestamp': '10:23 AM',
      'severity': 'warning',
      'resolved': false,
    },
    {
      'id': 2,
      'title': 'Route Diversion',
      'description': 'Construction on Main St, buses rerouted via College Ave',
      'timestamp': '9:15 AM',
      'severity': 'info',
      'resolved': false,
    },
    {
      'id': 3,
      'title': 'Bus 105 Out of Service',
      'description': 'Maintenance required, replacement bus dispatched',
      'timestamp': 'Yesterday',
      'severity': 'error',
      'resolved': true,
    },
    {
      'id': 4,
      'title': 'Schedule Change',
      'description': 'Weekend schedule adjusted for campus event',
      'timestamp': 'Yesterday',
      'severity': 'info',
      'resolved': true,
    },
  ];
  String filter = 'all';

  List<Map<String, dynamic>> get filteredAlerts {
    return alerts.where((alert) {
      if (filter == 'all') return true;
      if (filter == 'active') return !(alert['resolved'] as bool);
      if (filter == 'resolved') return alert['resolved'] as bool;
      return true;
    }).toList();
  }

  void resolveAlert(int id) {
    setState(() {
      alerts = alerts.map((alert) {
        if (alert['id'] == id) {
          return {...alert, 'resolved': true};
        }
        return alert;
      }).toList();
    });
  }

  Widget getSeverityIcon(String severity) {
    switch (severity) {
      case 'error':
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case 'warning':
        return const Icon(Icons.warning, color: Colors.amber, size: 20);
      case 'info':
        return const Icon(Icons.info, color: Colors.blue, size: 20);
      default:
        return const Icon(Icons.info, size: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Alerts',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _FilterButton(
                  label: 'All',
                  isSelected: filter == 'all',
                  onPressed: () => setState(() => filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  label: 'Active',
                  isSelected: filter == 'active',
                  onPressed: () => setState(() => filter = 'active'),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  label: 'Resolved',
                  isSelected: filter == 'resolved',
                  onPressed: () => setState(() => filter = 'resolved'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filteredAlerts.isEmpty)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text('No alerts to display',
                      style: TextStyle(color: Colors.grey[600])),
                ),
              )
            else
              Column(
                children: filteredAlerts.map((alert) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (alert['resolved'] as bool)
                          ? Colors.grey[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        getSeverityIcon(alert['severity'] as String),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    alert['title'] as String,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  if (alert['resolved'] as bool)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('Resolved',
                                          style: TextStyle(fontSize: 10)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alert['description'] as String,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alert['timestamp'] as String,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (!(alert['resolved'] as bool))
                          TextButton(
                            onPressed: () => resolveAlert(alert['id'] as int),
                            child: const Text('Resolve'),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  const _FilterButton(
      {required this.label, required this.isSelected, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[50] : null,
        side: BorderSide(color: isSelected ? Colors.blue : Colors.grey[300]!),
      ),
      child: Text(label,
          style: TextStyle(color: isSelected ? Colors.blue : Colors.black)),
    );
  }
}
