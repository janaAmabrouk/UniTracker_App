import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import '../services/admin_data_service.dart';

class SimpleRoutesScreen extends StatefulWidget {
  const SimpleRoutesScreen({Key? key}) : super(key: key);

  @override
  State<SimpleRoutesScreen> createState() => _SimpleRoutesScreenState();
}

class _SimpleRoutesScreenState extends State<SimpleRoutesScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await AdminDataService().getAllRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load routes: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get filteredRoutes {
    if (_search.isEmpty) return _routes;
    return _routes
        .where((route) =>
            (route['name']
                    ?.toString()
                    .toLowerCase()
                    .contains(_search.toLowerCase()) ??
                false) ||
            (route['id']
                    ?.toString()
                    .toLowerCase()
                    .contains(_search.toLowerCase()) ??
                false))
        .toList();
  }

  Future<void> _deleteRoute(String routeId) async {
    try {
      await AdminDataService().deleteRoute(routeId);
      await _loadRoutes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete route: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search routes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 16),

            // Routes List
            Expanded(
              child: filteredRoutes.isEmpty
                  ? const Center(child: Text('No routes found'))
                  : ListView.builder(
                      itemCount: filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = filteredRoutes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                route['name']?.toString().substring(0, 1) ??
                                    'R',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              route['name'] ?? 'Unknown Route',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'From: ${route['pickupLocation'] ?? 'N/A'}'),
                                Text('To: ${route['dropLocation'] ?? 'N/A'}'),
                                Text(
                                    'Time: ${route['startTime']} - ${route['endTime']}'),
                                Text('Status: ${route['status'] ?? 'Unknown'}'),
                                Text(
                                    'Stops: ${(route['stops'] as List?)?.length ?? 0}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info,
                                      color: Colors.blue),
                                  onPressed: () => _showRouteDetails(route),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _confirmDelete(route),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRouteDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showRouteDetails(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Route Details - ${route['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${route['id']}'),
            Text('Name: ${route['name']}'),
            Text('Pickup: ${route['pickupLocation']}'),
            Text('Drop: ${route['dropLocation']}'),
            Text('Start Time: ${route['startTime']}'),
            Text('End Time: ${route['endTime']}'),
            Text('Status: ${route['status']}'),
            Text('Color Code: ${route['colorCode']}'),
            Text('Stops: ${(route['stops'] as List?)?.length ?? 0}'),
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

  void _confirmDelete(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            Text('Are you sure you want to delete route ${route['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoute(route['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddRouteDialog() {
    final nameController = TextEditingController();
    final pickupController = TextEditingController();
    final dropController = TextEditingController();
    final startTimeController = TextEditingController(text: '08:00');
    final endTimeController = TextEditingController(text: '18:00');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Route'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Route Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pickupController,
                decoration: const InputDecoration(labelText: 'Pickup Location'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dropController,
                decoration: const InputDecoration(labelText: 'Drop Location'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: endTimeController,
                decoration: const InputDecoration(labelText: 'End Time'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await AdminDataService().createRoute(
                    name: nameController.text,
                    pickupLocation: pickupController.text,
                    dropLocation: dropController.text,
                    startTime: startTimeController.text,
                    endTime: endTimeController.text,
                  );
                  Navigator.pop(context);
                  await _loadRoutes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Route added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add route: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
