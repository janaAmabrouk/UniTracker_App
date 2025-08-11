import 'package:flutter/material.dart';
import 'services/supabase_service.dart';

class TestSupabaseIntegration extends StatefulWidget {
  const TestSupabaseIntegration({super.key});

  @override
  State<TestSupabaseIntegration> createState() => _TestSupabaseIntegrationState();
}

class _TestSupabaseIntegrationState extends State<TestSupabaseIntegration> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  String _testResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Integration Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Test Supabase Connection'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testRoutes,
              child: const Text('Test Routes API'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAuth,
              child: const Text('Test Authentication'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty ? 'No tests run yet' : _testResults,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing Supabase connection...\n';
    });

    try {
      final user = _supabaseService.currentUser;
      setState(() {
        _testResults += 'Connection: SUCCESS\n';
        _testResults += 'Current user: ${user?.email ?? 'Not authenticated'}\n';
        _testResults += 'User ID: ${user?.id ?? 'N/A'}\n\n';
      });
    } catch (e) {
      setState(() {
        _testResults += 'Connection: FAILED\n';
        _testResults += 'Error: $e\n\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testRoutes() async {
    setState(() {
      _isLoading = true;
      _testResults += 'Testing Routes API...\n';
    });

    try {
      final routes = await _supabaseService.getRoutes();
      setState(() {
        _testResults += 'Routes API: SUCCESS\n';
        _testResults += 'Found ${routes.length} routes:\n';
        for (final route in routes) {
          _testResults += '- ${route['name']} (${route['id']})\n';
        }
        _testResults += '\n';
      });
    } catch (e) {
      setState(() {
        _testResults += 'Routes API: FAILED\n';
        _testResults += 'Error: $e\n\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuth() async {
    setState(() {
      _isLoading = true;
      _testResults += 'Testing Authentication...\n';
    });

    try {
      // Test sign up with a test user
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@unitracker.test';
      final response = await _supabaseService.signUp(
        email: testEmail,
        password: 'testpassword123',
        data: {
          'full_name': 'Test User',
          'role': 'student',
        },
      );

      if (response.user != null) {
        setState(() {
          _testResults += 'Sign Up: SUCCESS\n';
          _testResults += 'Test user created: ${response.user!.email}\n';
        });

        // Test sign out
        await _supabaseService.signOut();
        setState(() {
          _testResults += 'Sign Out: SUCCESS\n\n';
        });
      } else {
        setState(() {
          _testResults += 'Sign Up: FAILED - No user returned\n\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResults += 'Authentication: FAILED\n';
        _testResults += 'Error: $e\n\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
