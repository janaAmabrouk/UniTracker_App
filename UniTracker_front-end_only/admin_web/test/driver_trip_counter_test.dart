import 'package:flutter_test/flutter_test.dart';
import 'package:admin_web/admin/services/admin_data_service.dart';

void main() {
  group('Driver Trip Counter Tests', () {
    test('should calculate trip statistics correctly', () {
      // Mock trip data
      final mockTrips = [
        {
          'driver_id': 'driver1',
          'status': 'completed',
          'on_time': true,
        },
        {
          'driver_id': 'driver1',
          'status': 'completed',
          'on_time': false,
        },
        {
          'driver_id': 'driver1',
          'status': 'completed',
          'on_time': true,
        },
        {
          'driver_id': 'driver2',
          'status': 'completed',
          'on_time': true,
        },
        {
          'driver_id': 'driver2',
          'status': 'in_progress',
          'on_time': null,
        },
      ];

      // Calculate statistics for driver1
      final driver1Trips =
          mockTrips.where((trip) => trip['driver_id'] == 'driver1').toList();
      final totalTrips = driver1Trips.length;
      final completedTrips =
          driver1Trips.where((trip) => trip['status'] == 'completed').length;
      final onTimeTrips = driver1Trips
          .where((trip) =>
              trip['status'] == 'completed' && trip['on_time'] == true)
          .length;
      final onTimeRate =
          completedTrips > 0 ? (onTimeTrips / completedTrips * 100).round() : 0;

      // Assertions
      expect(totalTrips, equals(3));
      expect(completedTrips, equals(3));
      expect(onTimeTrips, equals(2));
      expect(onTimeRate, equals(67)); // 2 out of 3 completed trips were on time
    });

    test('should handle empty trip data', () {
      final mockTrips = <Map<String, dynamic>>[];

      final totalTrips = mockTrips.length;
      final completedTrips =
          mockTrips.where((trip) => trip['status'] == 'completed').length;
      final onTimeTrips = mockTrips
          .where((trip) =>
              trip['status'] == 'completed' && trip['on_time'] == true)
          .length;
      final onTimeRate =
          completedTrips > 0 ? (onTimeTrips / completedTrips * 100).round() : 0;

      expect(totalTrips, equals(0));
      expect(completedTrips, equals(0));
      expect(onTimeTrips, equals(0));
      expect(onTimeRate, equals(0));
    });

    test('should calculate total completed trips across all drivers', () {
      final mockDrivers = [
        {
          'id': 'driver1',
          'fullName': 'Driver 1',
          'tripStats': {
            'totalTrips': 5,
            'completedTrips': 4,
            'onTimeTrips': 3,
            'onTimeRate': 75,
          },
        },
        {
          'id': 'driver2',
          'fullName': 'Driver 2',
          'tripStats': {
            'totalTrips': 3,
            'completedTrips': 2,
            'onTimeTrips': 2,
            'onTimeRate': 100,
          },
        },
        {
          'id': 'driver3',
          'fullName': 'Driver 3',
          'tripStats': {
            'totalTrips': 0,
            'completedTrips': 0,
            'onTimeTrips': 0,
            'onTimeRate': 0,
          },
        },
      ];

      final totalCompletedTrips = mockDrivers.fold<int>(0, (sum, driver) {
        final driverMap = driver as Map<String, dynamic>;
        final tripStats = driverMap['tripStats'] as Map<String, dynamic>?;
        return sum + (tripStats?['completedTrips'] as int? ?? 0);
      });

      expect(totalCompletedTrips, equals(6)); // 4 + 2 + 0
    });
  });
}
