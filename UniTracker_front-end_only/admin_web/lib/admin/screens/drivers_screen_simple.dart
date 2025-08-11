import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import '../services/admin_data_service.dart';

class SimpleDriversScreen extends StatefulWidget {
  const SimpleDriversScreen({Key? key}) : super(key: key);

  @override
  State<SimpleDriversScreen> createState() => _SimpleDriversScreenState();
}

class _SimpleDriversScreenState extends State<SimpleDriversScreen> {
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final drivers = await AdminDataService().getAllDrivers();
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load drivers: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get filteredDrivers {
    if (_search.isEmpty) return _drivers;
    return _drivers
        .where((driver) =>
            (driver['fullName']
                    ?.toString()
                    .toLowerCase()
                    .contains(_search.toLowerCase()) ??
                false) ||
            (driver['email']
                    ?.toString()
                    .toLowerCase()
                    .contains(_search.toLowerCase()) ??
                false) ||
            (driver['driverId']
                    ?.toString()
                    .toLowerCase()
                    .contains(_search.toLowerCase()) ??
                false))
        .toList();
  }

  Future<void> _deleteDriver(String driverId) async {
    try {
      await AdminDataService().deleteDriver(driverId);
      await _loadDrivers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete driver: $e')),
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
        title: const Text('Drivers Management'),
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
                hintText: 'Search drivers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 16),

            // Drivers List
            Expanded(
              child: filteredDrivers.isEmpty
                  ? const Center(child: Text('No drivers found'))
                  : ListView.builder(
                      itemCount: filteredDrivers.length,
                      itemBuilder: (context, index) {
                        final driver = filteredDrivers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                (driver['fullName']?.toString().isNotEmpty ==
                                        true)
                                    ? driver['fullName']
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : 'D',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              driver['fullName'] ?? 'Unknown Driver',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email: ${driver['email'] ?? 'N/A'}'),
                                Text(
                                    'Driver ID: ${driver['driverId'] ?? 'N/A'}'),
                                Text(
                                    'License: ${driver['licenseNumber'] ?? 'N/A'}'),
                                Text(
                                    'License Expires: ${driver['licenseExpiration'] ?? 'N/A'}'),
                                Text(
                                    'Student ID: ${driver['studentId'] ?? 'N/A'}'),
                                Text(
                                    'Assigned Buses: ${(driver['assignedBuses'] as List?)?.length ?? 0}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info,
                                      color: Colors.blue),
                                  onPressed: () => _showDriverDetails(driver),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _confirmDelete(driver),
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
        onPressed: _showAddDriverDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Driver Details - ${driver['fullName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${driver['id']}'),
            Text('Full Name: ${driver['fullName']}'),
            Text('Email: ${driver['email']}'),
            Text('Student ID: ${driver['studentId'] ?? 'N/A'}'),
            Text('Driver ID: ${driver['driverId']}'),
            Text('License Number: ${driver['licenseNumber']}'),
            Text('License Expiration: ${driver['licenseExpiration']}'),
            Text(
                'Assigned Buses: ${(driver['assignedBuses'] as List?)?.length ?? 0}'),
            Text(
                'Created: ${driver['createdAt']?.toString().split('T')[0] ?? 'N/A'}'),
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

  void _confirmDelete(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete driver ${driver['fullName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDriver(driver['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDriverDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final licenseController = TextEditingController();
    final expirationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Driver'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: licenseController,
                decoration: const InputDecoration(labelText: 'License Number'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: expirationController,
                decoration: const InputDecoration(
                    labelText: 'License Expiration (YYYY-MM-DD)'),
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
              if (nameController.text.isNotEmpty &&
                  emailController.text.isNotEmpty) {
                try {
                  await AdminDataService().createDriver(
                    fullName: nameController.text,
                    phoneNumber: phoneController.text,
                    licenseNumber: licenseController.text,
                    status: 'active',
                  );
                  Navigator.pop(context);
                  await _loadDrivers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Driver added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add driver: $e')),
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
