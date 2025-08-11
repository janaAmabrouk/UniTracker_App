import 'package:supabase_flutter/supabase_flutter.dart';
import 'email_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AdminDataService {
  static final AdminDataService _instance = AdminDataService._internal();
  factory AdminDataService() => _instance;
  AdminDataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Helper map to convert day names to integers for Supabase
  final Map<String, int> _weekDayNamesToNumbers = {
    'Monday': 1,
    'Tuesday': 2,
    'Wednesday': 3,
    'Thursday': 4,
    'Friday': 5,
    'Saturday': 6,
    'Sunday': 7,
  };

  // Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get all buses count
      final allBusesResponse =
          await _supabase.from('buses').select('id, status');

      // Get active buses count
      final activeBuses =
          allBusesResponse.where((bus) => bus['status'] == 'active').length;

      // Get total routes count
      final routesResponse = await _supabase
          .from('routes')
          .select('id, is_active')
          .eq('is_active', true);

      // Get total drivers count
      final driversResponse =
          await _supabase.from('drivers').select('id, is_active');

      return {
        'activeBuses': activeBuses,
        'totalBuses': allBusesResponse.length,
        'totalRoutes': routesResponse.length,
        'totalDrivers': driversResponse.length,
        'onTimeRate': 94,
        'issues': 2,
      };
    } catch (e) {
      // Return fallback data if Supabase fails
      return {
        'activeBuses': 12,
        'totalBuses': 15,
        'totalRoutes': 8,
        'totalDrivers': 6,
        'onTimeRate': 94,
        'issues': 2,
      };
    }
  }

  // Bus Management
  Future<List<Map<String, dynamic>>> getAllBuses() async {
    try {
      final response = await _supabase.from('buses').select('''
            id,
            bus_number,
            plate_number,
            capacity,
            status,
            driver_id,
            route_id,
            created_at,
            updated_at,
            routes(
              id,
              name,
              pickup_location,
              drop_location
            )
          ''');

      return response.map<Map<String, dynamic>>((bus) {
        final route = bus['routes'];
        return {
          'id': bus['id'],
          'busNumber': bus['bus_number'],
          'plateNumber': bus['plate_number'],
          'capacity': bus['capacity'],
          'status': bus['status'],
          'driverId': bus['driver_id'],
          'routeId': bus['route_id'],
          'routeName': route != null ? route['name'] : 'No Route Assigned',
          'createdAt': bus['created_at'],
          'updatedAt': bus['updated_at'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load buses: $e');
    }
  }

  // Route Management
  Future<List<Map<String, dynamic>>> getAllRoutes() async {
    try {
      final response = await _supabase.from('routes').select('''
            id,
            name,
            pickup_location,
            drop_location,
            start_time,
            end_time,
            is_active,
            color_code,
            created_at,
            updated_at,
            bus_stops(
              id,
              name,
              latitude,
              longitude,
              stop_order,
              estimated_arrival_time
            )
          ''').order('created_at', ascending: false);

      return response.map<Map<String, dynamic>>((route) {
        final stops = route['bus_stops'] as List<dynamic>? ?? [];
        return {
          'id': route['id'],
          'name': route['name'],
          'pickupLocation': route['pickup_location'],
          'dropLocation': route['drop_location'],
          'startTime': route['start_time'],
          'endTime': route['end_time'],
          'status': route['is_active'] == true ? 'active' : 'inactive',
          'is_active': route['is_active'],
          'colorCode': route['color_code'],
          'stops': stops,
          'createdAt': route['created_at'],
          'updatedAt': route['updated_at'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching routes: $e');
      throw Exception('Failed to load routes: $e');
    }
  }

  // Driver Management
  Future<List<Map<String, dynamic>>> getAllDrivers() async {
    try {
      final driversResponse = await _supabase.from('drivers').select('''
            id,
            full_name,
            driver_id,
            driver_license,
            license_expiry,
            license_image_path,
            phone,
            is_active,
            created_at,
            updated_at
          ''').order('created_at', ascending: false);

      // Fetch all buses to map assignments
      final busesResponse = await _supabase.from('buses').select('''
            id,
            bus_number,
            driver_id
          ''');

      // Fetch all schedules to map assignments, including route name
      final schedulesResponse = await _supabase.from('schedules').select('''
            id,
            route_id,
            driver_id,
            routes(
              id,
              name
            )
          ''');

      // Fetch trip statistics for all drivers (using UUID)
      final tripStatsResponse = await _supabase.from('trip_history').select('''
            driver_id,
            status,
            on_time
          ''');
      print('DEBUG: tripStatsResponse = ' + tripStatsResponse.toString());

      return driversResponse.map<Map<String, dynamic>>((driver) {
        // Find all buses assigned to this driver
        final assignedBuses = busesResponse
            .where((bus) => bus['driver_id'] == driver['id'])
            .toList();
        // Find all schedules assigned to this driver
        final assignedSchedules = schedulesResponse
            .where((schedule) => schedule['driver_id'] == driver['id'])
            .toList();

        // Calculate trip statistics for this driver (using UUID)
        final driverTrips = tripStatsResponse
            .where((trip) => trip['driver_id'] == driver['id'])
            .toList();

        final totalTrips = driverTrips.length;
        final completedTrips =
            driverTrips.where((trip) => trip['status'] == 'completed').length;
        final onTimeTrips = driverTrips
            .where((trip) =>
                trip['status'] == 'completed' && trip['on_time'] == true)
            .length;
        final onTimeRate = completedTrips > 0
            ? (onTimeTrips / completedTrips * 100).round()
            : 0;

        return {
          'id': driver['id'],
          'fullName': driver['full_name'],
          'phone': driver['phone'],
          'driverId': driver['driver_id'],
          'licenseNumber': driver['driver_license'],
          'licenseExpiration': driver['license_expiry'],
          'licenseImagePath': driver['license_image_path'],
          'isActive': driver['is_active'],
          'assignedBuses': assignedBuses,
          'assignedSchedules': assignedSchedules,
          'tripStats': {
            'totalTrips': totalTrips,
            'completedTrips': completedTrips,
            'onTimeTrips': onTimeTrips,
            'onTimeRate': onTimeRate,
          },
          'createdAt': driver['created_at'],
          'updatedAt': driver['updated_at'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching drivers: $e');
      throw Exception('Failed to load drivers: $e');
    }
  }

  // Get driver trip statistics
  Future<Map<String, dynamic>> getDriverTripStats(String driverId) async {
    try {
      // Step 1: Get the driver's UUID from the drivers table
      final driver = await _supabase
          .from('drivers')
          .select('id')
          .eq('driver_id', driverId)
          .maybeSingle();
      if (driver == null) {
        throw Exception('Driver not found');
      }
      final driverUuid = driver['id'];

      // Step 2: Query trip_history with UUID
      final response = await _supabase
          .from('trip_history')
          .select('''
            id,
            driver_id,
            route_id,
            status,
            on_time,
            trip_date,
            created_at,
            routes(
              id,
              name
            )
          ''')
          .eq('driver_id', driverUuid)
          .order('created_at', ascending: false);

      final trips = response as List<dynamic>;
      final totalTrips = trips.length;
      final completedTrips =
          trips.where((trip) => trip['status'] == 'completed').length;
      final onTimeTrips = trips
          .where((trip) =>
              trip['status'] == 'completed' && trip['on_time'] == true)
          .length;
      final onTimeRate =
          completedTrips > 0 ? (onTimeTrips / completedTrips * 100).round() : 0;

      // Get recent trips (last 10)
      final recentTrips = trips
          .take(10)
          .map((trip) => {
                'id': trip['id'],
                'routeName': trip['routes']?['name'] ?? 'Unknown Route',
                'status': trip['status'],
                'onTime': trip['on_time'],
                'tripDate': trip['trip_date'],
                'createdAt': trip['created_at'],
              })
          .toList();

      return {
        'totalTrips': totalTrips,
        'completedTrips': completedTrips,
        'onTimeTrips': onTimeTrips,
        'onTimeRate': onTimeRate,
        'recentTrips': recentTrips,
      };
    } catch (e) {
      throw Exception('Failed to load driver trip stats: $e');
    }
  }

  // Schedule Management
  Future<List<Map<String, dynamic>>> getAllSchedules() async {
    try {
      final response = await _supabase.from('schedules').select('''
            id,
            route_id,
            bus_id,
            driver_id,
            departure_time,
            arrival_time,
            days_of_week,
            is_active,
            created_at,
            routes(
              id,
              name,
              pickup_location,
              drop_location
            ),
            buses(
              id,
              bus_number
            ),
            drivers(
              id,
              full_name
            )
          ''').order('created_at', ascending: false);

      return response.map<Map<String, dynamic>>((schedule) {
        final route = schedule['routes'];
        final bus = schedule['buses'];
        final driver = schedule['drivers'];
        final daysOfWeek = schedule['days_of_week'] as List<dynamic>? ?? [];

        // Convert day integers back to day names
        final dayMap = {
          1: 'Monday',
          2: 'Tuesday',
          3: 'Wednesday',
          4: 'Thursday',
          5: 'Friday',
          6: 'Saturday',
          7: 'Sunday',
        };
        final dayNames =
            daysOfWeek.map((day) => dayMap[day] ?? 'Unknown').toList();

        return {
          'id': schedule['id'],
          'routeId': schedule['route_id'],
          'busId': schedule['bus_id'],
          'driverId': schedule['driver_id'],
          'routeName': route?['name'] ?? 'Unknown Route',
          'busNumber': bus?['bus_number'] ?? 'Unknown Bus',
          'driverName': driver?['full_name'] ?? 'Unassigned',
          'departureTime': schedule['departure_time'],
          'arrivalTime': schedule['arrival_time'],
          'days': dayNames,
          'isActive': schedule['is_active'],
          'createdAt': schedule['created_at'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching schedules: $e');
      throw Exception('Failed to load schedules: $e');
    }
  }

  // Create schedule with driver assignment
  Future<Map<String, dynamic>> createSchedule({
    required String routeId,
    required String busId,
    required String driverId,
    required String departureTime,
    required String arrivalTime,
    required List<String> days,
  }) async {
    try {
      final response = await _supabase
          .from('schedules')
          .insert({
            'route_id': routeId,
            'bus_id': busId,
            'driver_id': driverId, // Assign driver ID
            'departure_time': departureTime,
            'arrival_time': arrivalTime,
            'days_of_week': days
                .map((day) => _weekDayNamesToNumbers[day])
                .toList(), // Convert to numbers
            'is_active': true,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to create schedule: $e');
    }
  }

  // Update Schedule
  Future<Map<String, dynamic>> updateSchedule({
    required String scheduleId,
    String? routeId,
    String? busId,
    String? driverId,
    String? departureTime,
    String? arrivalTime,
    List<String>? days,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (routeId != null) updates['route_id'] = routeId;
      if (busId != null) updates['bus_id'] = busId;
      if (driverId != null) updates['driver_id'] = driverId;
      if (departureTime != null) updates['departure_time'] = departureTime;
      if (arrivalTime != null) updates['arrival_time'] = arrivalTime;
      if (days != null) {
        updates['days_of_week'] =
            days.map((day) => _weekDayNamesToNumbers[day]).toList();
      }

      final response = await _supabase
          .from('schedules')
          .update(updates)
          .eq('id', scheduleId)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  // Delete schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _supabase.from('schedules').delete().eq('id', scheduleId);
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  // Bus CRUD operations
  Future<Map<String, dynamic>> createBus({
    required String busNumber,
    required String plateNumber,
    required int capacity,
    String status = 'active',
    String? driverId,
    String? routeId,
  }) async {
    try {
      final response = await _supabase
          .from('buses')
          .insert({
            'bus_number': busNumber,
            'plate_number': plateNumber,
            'capacity': capacity,
            'status': status,
            'driver_id': driverId,
            'route_id': routeId,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create bus: $e');
    }
  }

  Future<Map<String, dynamic>> updateBus({
    required String busId,
    String? busNumber,
    String? plateNumber,
    int? capacity,
    String? status,
    String? driverId,
    String? routeId,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (busNumber != null) updateData['bus_number'] = busNumber;
      if (plateNumber != null) updateData['plate_number'] = plateNumber;
      if (capacity != null) updateData['capacity'] = capacity;
      if (status != null) updateData['status'] = status;
      if (driverId != null) {
        updateData['driver_id'] = driverId;
      } else {
        updateData['driver_id'] = null;
      }
      if (routeId != null) updateData['route_id'] = routeId;

      final response = await _supabase
          .from('buses')
          .update(updateData)
          .eq('id', busId)
          .select()
          .single();

      // Update reservation_slots capacity for this bus
      if (capacity != null) {
        await _supabase
            .from('reservation_slots')
            .update({'capacity': capacity}).eq('bus_id', busId);
      }

      return response;
    } catch (e) {
      throw Exception('Failed to update bus: $e');
    }
  }

  Future<void> deleteBus(String busId) async {
    try {
      await _supabase.from('buses').delete().eq('id', busId);
    } catch (e) {
      throw Exception('Failed to delete bus: $e');
    }
  }

  // Route CRUD operations
  Future<Map<String, dynamic>> createRoute({
    required String name,
    required String pickupLocation,
    required String dropLocation,
    required String startTime,
    required String endTime,
    String status = 'active',
    String? colorCode,
  }) async {
    try {
      final response = await _supabase
          .from('routes')
          .insert({
            'name': name,
            'pickup_location': pickupLocation,
            'drop_location': dropLocation,
            'start_time': startTime,
            'end_time': endTime,
            'is_active': status == 'active',
            'color_code': colorCode ?? '2196F3',
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create route: $e');
    }
  }

  Future<Map<String, dynamic>> createRouteWithStops({
    required String name,
    required String pickupLocation,
    required String dropLocation,
    required String startTime,
    required String endTime,
    String status = 'active',
    String? colorCode,
    List<Map<String, dynamic>>? busStops,
  }) async {
    try {
      // First create the route
      final routeResponse = await _supabase
          .from('routes')
          .insert({
            'name': name,
            'pickup_location': pickupLocation,
            'drop_location': dropLocation,
            'start_time': startTime,
            'end_time': endTime,
            'is_active': status == 'active',
            'color_code': colorCode ?? '2196F3',
          })
          .select()
          .single();

      final routeId = routeResponse['id'];

      // Then create bus stops if provided
      if (busStops != null && busStops.isNotEmpty) {
        final stopsToInsert = busStops
            .map(
              (stop) => {
                'route_id': routeId,
                'name': stop['name'],
                'stop_order': stop['order'],
                'estimated_arrival_time': stop['time'],
                'is_pickup_point': stop['order'] == 1, // First stop is pickup
                'is_drop_point':
                    stop['order'] == busStops.length, // Last stop is drop
              },
            )
            .toList();

        await _supabase.from('bus_stops').insert(stopsToInsert);
      }

      return routeResponse;
    } catch (e) {
      throw Exception('Failed to create route with stops: $e');
    }
  }

  Future<Map<String, dynamic>> updateRouteWithStops({
    required String routeId,
    String? name,
    String? pickupLocation,
    String? dropLocation,
    String? startTime,
    String? endTime,
    String? status,
    String? colorCode,
    List<Map<String, dynamic>>? busStops,
  }) async {
    try {
      // First update the route
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (pickupLocation != null)
        updateData['pickup_location'] = pickupLocation;
      if (dropLocation != null) updateData['drop_location'] = dropLocation;
      if (startTime != null) updateData['start_time'] = startTime;
      if (endTime != null) updateData['end_time'] = endTime;
      if (status != null) updateData['is_active'] = status == 'active';
      if (colorCode != null) updateData['color_code'] = colorCode;

      final routeResponse = await _supabase
          .from('routes')
          .update(updateData)
          .eq('id', routeId)
          .select()
          .single();

      // Update bus stops if provided
      if (busStops != null) {
        final existingStopsResponse = await _supabase
            .from('bus_stops')
            .select(
                'id, name, stop_order, estimated_arrival_time, is_pickup_point, is_drop_point')
            .eq('route_id', routeId);

        final List<Map<String, dynamic>> existingStops =
            (existingStopsResponse as List).cast<Map<String, dynamic>>();

        final List<String> incomingStopIds = busStops
            .where((stop) => stop['id'] != null)
            .map((stop) => stop['id'] as String)
            .toList();
        final List<String> existingStopIds =
            existingStops.map((stop) => stop['id'] as String).toList();

        // Identify stops to remove
        final stopsToRemoveIds = existingStopIds
            .where((id) => !incomingStopIds.contains(id))
            .toList();

        if (stopsToRemoveIds.isNotEmpty) {
          // Nullify drop_stop_id in reservations for removed stops
          await _supabase
              .from('reservations')
              .update({'drop_stop_id': null}).inFilter(
                  'drop_stop_id', stopsToRemoveIds);

          // Nullify pickup_stop_id in reservations for removed stops
          await _supabase
              .from('reservations')
              .update({'pickup_stop_id': null}).inFilter(
                  'pickup_stop_id', stopsToRemoveIds);

          // Delete removed stops
          await _supabase
              .from('bus_stops')
              .delete()
              .inFilter('id', stopsToRemoveIds);
        }

        // Process incoming stops: update existing or insert new ones
        for (final stopData in busStops) {
          final stopId = stopData['id'];
          final Map<String, dynamic> stopToSave = {
            'route_id': routeId,
            'name': stopData['name'],
            'stop_order': stopData['order'],
            'estimated_arrival_time': stopData['time'],
            'is_pickup_point': stopData['order'] == 1,
            'is_drop_point': stopData['order'] == busStops.length,
          };

          if (stopId != null && existingStopIds.contains(stopId)) {
            // Update existing stop
            await _supabase
                .from('bus_stops')
                .update(stopToSave)
                .eq('id', stopId);
          } else {
            // Insert new stop
            await _supabase.from('bus_stops').insert(stopToSave);
          }
        }
      }

      return routeResponse;
    } catch (e) {
      throw Exception('Failed to update route with stops: $e');
    }
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      // 1. Get all bus stop IDs associated with this route
      final busStopsResponse = await _supabase
          .from('bus_stops')
          .select('id')
          .eq('route_id', routeId);

      final List<String> busStopIds = (busStopsResponse as List)
          .map((stop) => stop['id'] as String)
          .toList();

      // 2. Find reservations linked to these bus stops (either as pickup or drop-off)
      if (busStopIds.isNotEmpty) {
        // Get reservations where drop_stop_id is in busStopIds
        final dropAffectedReservationsResponse = await _supabase
            .from('reservations')
            .select('id')
            .inFilter('drop_stop_id', busStopIds);

        // Get reservations where pickup_stop_id is in busStopIds
        final pickupAffectedReservationsResponse = await _supabase
            .from('reservations')
            .select('id')
            .inFilter('pickup_stop_id', busStopIds);

        // Combine and get unique reservation IDs
        final Set<String> affectedReservationIdsSet = {};
        affectedReservationIdsSet.addAll(
            (dropAffectedReservationsResponse as List)
                .map((res) => res['id'] as String));
        affectedReservationIdsSet.addAll(
            (pickupAffectedReservationsResponse as List)
                .map((res) => res['id'] as String));

        final List<String> affectedReservationIds =
            affectedReservationIdsSet.toList();

        // 3. Nullify drop_stop_id and pickup_stop_id in those affected reservations
        if (affectedReservationIds.isNotEmpty) {
          await _supabase
              .from('reservations')
              .update({'drop_stop_id': null, 'pickup_stop_id': null}).inFilter(
                  'id', affectedReservationIds);
        }
      }

      // 4. Delete bus stops associated with the route
      await _supabase.from('bus_stops').delete().eq('route_id', routeId);

      // 5. Delete the route
      await _supabase.from('routes').delete().eq('id', routeId);
    } catch (e) {
      throw Exception('Failed to delete route: $e');
    }
  }

  // Driver CRUD operations
  Future<void> createDriver({
    required String fullName,
    required String phoneNumber,
    required String licenseNumber,
    String? licenseExpiration,
    required String status,
    String? licenseImagePath,
    String? driverId,
  }) async {
    try {
      // Convert licenseExpiration to DD-MM-YYYY if not null and not already in that format
      String? formattedLicenseExpiration;
      if (licenseExpiration != null && licenseExpiration.isNotEmpty) {
        try {
          // Try parsing as yyyy-MM-dd first
          DateTime parsed =
              DateFormat('yyyy-MM-dd').parseStrict(licenseExpiration);
          formattedLicenseExpiration = DateFormat('dd-MM-yyyy').format(parsed);
        } catch (_) {
          try {
            // Try parsing as dd-MM-yyyy
            DateTime parsed =
                DateFormat('dd-MM-yyyy').parseStrict(licenseExpiration);
            formattedLicenseExpiration =
                DateFormat('dd-MM-yyyy').format(parsed);
          } catch (_) {
            // Fallback: just use the string as-is
            formattedLicenseExpiration = licenseExpiration;
          }
        }
      }

      // Use provided driverId if given, otherwise generate one
      final driverIdToUse = driverId ?? _generateDriverId(fullName);

      // Create driver record in the drivers table first
      final driverResponse = await _supabase
          .from('drivers')
          .insert({
            'full_name': fullName,
            'phone': phoneNumber,
            'driver_license': licenseNumber,
            'license_expiry': formattedLicenseExpiration,
            'is_active': status == 'active',
            'driver_id': driverIdToUse,
            if (licenseImagePath != null && licenseImagePath.isNotEmpty)
              'license_image_path': licenseImagePath,
          })
          .select()
          .single();

      final driverRecordId = driverResponse['id'];

      // Create user profile in the users table (no email for drivers)
      await _supabase.from('users').insert({
        'id': driverRecordId,
        'full_name': fullName,
        'role': 'driver',
        'driver_license': licenseNumber,
        'license_expiry': formattedLicenseExpiration,
        'is_active': status == 'active',
        'phone_number': phoneNumber,
        'driver_id': driverIdToUse,
        // No email field for drivers
      });

      // Send welcome email with setup instructions
      await _sendWelcomeEmail(fullName, driverIdToUse);

      print(
          '✅ Driver created successfully. Welcome email sent with setup instructions.');
      print('📧 Driver ID: $driverIdToUse');
      print('📧 Driver should use this ID to sign up in the mobile app');
    } catch (e) {
      print('❌ Error creating driver: $e');
      throw Exception('Failed to create driver: $e');
    }
  }

  // Generate a unique driver ID
  String _generateDriverId(String fullName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nameInitials = fullName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join('')
        .toUpperCase();
    return 'DR${nameInitials}${timestamp.toString().substring(timestamp.toString().length - 4)}';
  }

  // Send welcome email to new driver
  Future<void> _sendWelcomeEmail(String fullName, String driverId) async {
    try {
      await EmailService().sendWelcomeEmail(
        fullName: fullName,
        driverId: driverId,
      );
    } catch (e) {
      print('❌ Error sending welcome email: $e');
      // Don't throw here as the driver creation was successful
    }
  }

  Future<void> updateDriver({
    required String driverId,
    String? fullName,
    String? phoneNumber,
    String? licenseNumber,
    String? licenseExpiration,
    bool? isActive,
    String? licenseImagePath,
    String? newDriverId,
  }) async {
    try {
      final updates = <String, dynamic>{};
      final userUpdates = <String, dynamic>{};
      if (fullName != null) {
        updates['full_name'] = fullName;
        userUpdates['full_name'] = fullName;
      }
      if (phoneNumber != null) {
        updates['phone'] = phoneNumber;
        userUpdates['phone_number'] = phoneNumber;
      }
      if (licenseNumber != null) {
        updates['driver_license'] = licenseNumber;
        userUpdates['driver_license'] = licenseNumber;
      }
      if (licenseExpiration != null) {
        String formattedLicenseExpiration;
        try {
          DateTime parsed =
              DateFormat('yyyy-MM-dd').parseStrict(licenseExpiration);
          formattedLicenseExpiration = DateFormat('dd-MM-yyyy').format(parsed);
        } catch (_) {
          try {
            DateTime parsed =
                DateFormat('dd-MM-yyyy').parseStrict(licenseExpiration);
            formattedLicenseExpiration =
                DateFormat('dd-MM-yyyy').format(parsed);
          } catch (_) {
            formattedLicenseExpiration = licenseExpiration;
          }
        }
        updates['license_expiry'] = formattedLicenseExpiration;
        userUpdates['license_expiry'] = formattedLicenseExpiration;
      }
      if (isActive != null) {
        updates['is_active'] = isActive;
        userUpdates['is_active'] = isActive;
      }
      if (licenseImagePath != null && licenseImagePath.isNotEmpty) {
        updates['license_image_path'] = licenseImagePath;
      }
      if (newDriverId != null && newDriverId.isNotEmpty) {
        updates['driver_id'] = newDriverId;
        userUpdates['driver_id'] = newDriverId;
      }
      if (updates.isNotEmpty) {
        await _supabase.from('drivers').update(updates).eq('id', driverId);
      }
      if (userUpdates.isNotEmpty) {
        await _supabase.from('users').update(userUpdates).eq('id', driverId);
      }
    } catch (e) {
      throw Exception('Failed to update driver: $e');
    }
  }

  Future<void> deleteDriver(String driverId) async {
    try {
      // Unassign driver from schedules and buses
      await _supabase
          .from('schedules')
          .update({'driver_id': null}).eq('driver_id', driverId);
      await _supabase
          .from('buses')
          .update({'driver_id': null}).eq('driver_id', driverId);
      // Delete from drivers table
      final driverDelete =
          await _supabase.from('drivers').delete().eq('id', driverId);
      print('Driver delete result: ' + driverDelete.toString());
      // Always attempt to delete from users table as well
      final userDelete =
          await _supabase.from('users').delete().eq('id', driverId);
      print('User delete result: ' + userDelete.toString());
    } catch (e) {
      print('Error deleting driver or user: ' + e.toString());
      throw Exception('Failed to delete driver and user: $e');
    }
  }

  // Reservation Management
  Future<List<Map<String, dynamic>>> getAllReservations() async {
    try {
      final response = await _supabase.from('reservations').select('''
            id,
            reservation_date,
            seat_number,
            status,
            created_at,
            slot_id,
            reservation_slots!inner(
              id,
              slot_date,
              slot_time,
              direction,
              capacity,
              route_id,
              routes!inner(name)
            ),
            users!inner(
              id,
              full_name,
              email,
              student_id
            )
          ''').order('created_at', ascending: false);

      return response.map<Map<String, dynamic>>((reservation) {
        final user = reservation['users'];
        final slot = reservation['reservation_slots'];
        final routeName = slot != null && slot['routes'] != null
            ? slot['routes']['name']
            : null;
        return {
          'id': reservation['id'],
          'reservationDate': reservation['reservation_date'],
          'seatNumber': reservation['seat_number'],
          'status': reservation['status'],
          'userName': user?['full_name'] ?? 'Unknown User',
          'userEmail': user?['email'] ?? '',
          'studentId': user?['student_id'] ?? '',
          'slotId': slot?['id'],
          'slotDate': slot?['slot_date'],
          'slotTime': slot?['slot_time'],
          'slotDirection': slot?['direction'],
          'slotCapacity': slot?['capacity'],
          'routeName': routeName ?? 'Unknown Route',
          'createdAt': reservation['created_at'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching reservations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateReservationStatus({
    required String reservationId,
    required String status,
  }) async {
    try {
      print(
          'DEBUG: Updating reservation status - ID: $reservationId, Status: $status');

      // Update reservation status
      final response = await _supabase
          .from('reservations')
          .update({'status': status})
          .eq('id', reservationId)
          .select()
          .single();

      print('DEBUG: Reservation status updated successfully');

      // Fetch user_id and other info from the updated reservation
      final reservation = await _supabase
          .from('reservations')
          .select('user_id')
          .eq('id', reservationId)
          .maybeSingle();
      final userId = reservation != null ? reservation['user_id'] : null;

      print('DEBUG: Fetched user_id: $userId');

      if (userId != null) {
        String title = '';
        String message = '';
        String type = 'info';
        if (status == 'confirmed') {
          title = 'Reservation Confirmed';
          message = 'Your reservation has been confirmed by the admin.';
          type = 'success';
        } else if (status == 'cancelled') {
          title = 'Reservation Cancelled';
          message = 'Your reservation has been cancelled by the admin.';
          type = 'alert';
        }
        if (title.isNotEmpty && message.isNotEmpty) {
          print(
              'DEBUG: Creating notification - Title: $title, Message: $message, Type: $type');
          await _supabase.from('notifications').insert({
            'user_id': userId,
            'title': title,
            'message': message,
            'type': type,
          });
          print('DEBUG: Notification created successfully');
        }
      } else {
        print('DEBUG: No user_id found for reservation');
      }
      return response;
    } catch (e) {
      print('DEBUG: Error in updateReservationStatus: $e');
      throw Exception('Failed to update reservation status: $e');
    }
  }

  Future<Map<String, dynamic>> updateReservation(
    Map<String, dynamic> reservation,
  ) async {
    try {
      final reservationId = reservation['id'];
      if (reservationId == null) {
        throw Exception('Reservation ID is required for update');
      }

      // Store the old status to check if it changed
      final oldReservation = await _supabase
          .from('reservations')
          .select('status, user_id')
          .eq('id', reservationId)
          .maybeSingle();
      final oldStatus = oldReservation?['status'];
      final userId = oldReservation?['user_id'];

      // Prepare update data
      final updateData = <String, dynamic>{};

      if (reservation['reservationDate'] != null) {
        updateData['reservation_date'] = reservation['reservationDate'];
      }
      if (reservation['seatNumber'] != null) {
        updateData['seat_number'] = reservation['seatNumber'];
      }
      if (reservation['status'] != null) {
        updateData['status'] = reservation['status'];
      }
      if (reservation['routeId'] != null) {
        updateData['route_id'] = reservation['routeId'];
      }
      if (reservation['userId'] != null) {
        updateData['user_id'] = reservation['userId'];
      }

      final response = await _supabase
          .from('reservations')
          .update(updateData)
          .eq('id', reservationId)
          .select('''
            id,
            reservation_date,
            seat_number,
            status,
            created_at,
            users!inner(
              id,
              full_name,
              email,
              student_id
            ),
            routes!inner(
              id,
              name,
              pickup_location,
              drop_location
            )
          ''').single();

      // Check if status changed and send notification
      final newStatus = reservation['status'];
      if (userId != null &&
          oldStatus != null &&
          newStatus != null &&
          oldStatus != newStatus) {
        print(
            'DEBUG: Status changed from $oldStatus to $newStatus for user $userId');
        String title = '';
        String message = '';
        String type = 'info';
        if (newStatus == 'confirmed') {
          title = 'Reservation Confirmed';
          message = 'Your reservation has been confirmed by the admin.';
          type = 'success';
        } else if (newStatus == 'cancelled') {
          title = 'Reservation Cancelled';
          message = 'Your reservation has been cancelled by the admin.';
          type = 'alert';
        }
        if (title.isNotEmpty && message.isNotEmpty) {
          print(
              'DEBUG: Creating notification - Title: $title, Message: $message, Type: $type');
          await _supabase.from('notifications').insert({
            'user_id': userId,
            'title': title,
            'message': message,
            'type': type,
          });
          print('DEBUG: Notification created successfully');
        }
      }

      // Transform response to match expected format
      final user = response['users'];
      final route = response['routes'];

      return {
        'id': response['id'],
        'reservationDate': response['reservation_date'],
        'seatNumber': response['seat_number'],
        'status': response['status'],
        'userName': user?['full_name'] ?? 'Unknown User',
        'userEmail': user?['email'] ?? '',
        'studentId': user?['student_id'] ?? '',
        'routeId': route?['id'] ?? '',
        'routeName': route?['name'] ?? 'Unknown Route',
        'routePickup': route?['pickup_location'] ?? '',
        'routeDrop': route?['drop_location'] ?? '',
        'createdAt': response['created_at'],
      };
    } catch (e) {
      print('DEBUG: Error in updateReservation: $e');
      throw Exception('Failed to update reservation: $e');
    }
  }

  Future<void> deleteReservation(String reservationId) async {
    try {
      await _supabase.from('reservations').delete().eq('id', reservationId);
    } catch (e) {
      throw Exception('Failed to delete reservation: $e');
    }
  }

  // Settings Management
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _supabase.from('settings').select('key, value');
      final Map<String, dynamic> settings = {};
      for (var item in response) {
        settings[item['key'].toString().trim().toLowerCase()] = item['value'];
      }
      return settings;
    } catch (e) {
      throw Exception('Failed to get settings: $e');
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      // Fetch existing settings to determine whether to update or insert
      final existingSettingsResponse =
          await _supabase.from('settings').select('key, id');
      final Map<String, String> existingKeys = {
        for (var item in existingSettingsResponse)
          (item['key'] as String).trim().toLowerCase(): item['id'] as String,
      };

      final List<Map<String, dynamic>> updates = [];
      final List<Map<String, dynamic>> inserts = [];

      settings.forEach((key, value) {
        final trimmedKey = key.trim().toLowerCase();
        final trimmedValue = value.toString().trim();

        if (existingKeys.containsKey(trimmedKey)) {
          // If key exists, add to updates with its id
          updates.add({
            'id': existingKeys[trimmedKey]!,
            'key': trimmedKey,
            'value': trimmedValue,
          });
        } else {
          // If key does not exist, add to inserts
          inserts.add({
            'key': trimmedKey,
            'value': trimmedValue,
          });
        }
      });

      // Perform updates
      if (updates.isNotEmpty) {
        for (var updateItem in updates) {
          await _supabase.from('settings').update(
              {'value': updateItem['value']}).eq('id', updateItem['id']);
        }
      }

      // Perform inserts
      if (inserts.isNotEmpty) {
        await _supabase.from('settings').insert(inserts);
      }
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  // Dashboard Analytics
  Future<Map<String, dynamic>> getOnTimeRate() async {
    try {
      return {'rate': 95, 'totalTrips': 0, 'completedTrips': 0};
    } catch (e) {
      return {'rate': 95, 'totalTrips': 0, 'completedTrips': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getRecentAlerts() async {
    try {
      return [
        {
          'type': 'info',
          'title': 'System Status',
          'message': 'All systems operational',
          'severity': 'info',
          'time': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        },
      ];
    } catch (e) {
      return [];
    }
  }

  // Notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      return [
        {
          'id': '1',
          'title': 'System Update',
          'message': 'System maintenance scheduled for tonight',
          'type': 'info',
          'isRead': false,
          'createdAt': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
        },
      ];
    } catch (e) {
      return [];
    }
  }

  // Reservation Slot Management
  Future<List<Map<String, dynamic>>> getAllReservationSlots() async {
    try {
      final response = await _supabase
          .from('reservation_slots')
          .select('''
        id,
        route_id,
        direction,
        slot_date,
        slot_time,
        capacity
      ''')
          .order('slot_date', ascending: true)
          .order('slot_time', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reservation slots: $e');
      return [];
    }
  }

  /// Adds reservation slots for each (date, time) pair in the range, using the selected bus's capacity.
  Future<void> addReservationSlots({
    required String routeId,
    required String direction,
    required DateTime startDate,
    required DateTime endDate,
    required List<TimeOfDay> times,
    required String busId,
    required int capacity,
  }) async {
    try {
      final List<Map<String, dynamic>> slotsToInsert = [];
      for (DateTime date = startDate;
          !date.isAfter(endDate);
          date = date.add(const Duration(days: 1))) {
        for (final time in times) {
          slotsToInsert.add({
            'route_id': routeId,
            'direction': direction,
            'slot_date': date.toIso8601String().split('T')[0],
            'slot_time': _formatTimeOfDay(time),
            'capacity': capacity,
            'bus_id': busId,
          });
        }
      }
      // Remove duplicates by checking if slot already exists
      for (final slot in slotsToInsert) {
        final existing = await _supabase
            .from('reservation_slots')
            .select('id')
            .eq('route_id', slot['route_id'])
            .eq('direction', slot['direction'])
            .eq('slot_date', slot['slot_date'])
            .eq('slot_time', slot['slot_time'])
            .maybeSingle();
        if (existing == null) {
          await _supabase.from('reservation_slots').insert(slot);
        }
      }
    } catch (e) {
      print('Error adding reservation slots: $e');
      rethrow;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  /// Deletes reservation slots by id or by slot info (route, direction, date range, times)
  Future<void> deleteReservationSlots({
    String? slotId,
    String? routeId,
    String? direction,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? times,
  }) async {
    try {
      final query = _supabase.from('reservation_slots').delete();
      if (slotId != null) {
        await query.eq('id', slotId);
      } else if (routeId != null &&
          direction != null &&
          startDate != null &&
          endDate != null &&
          times != null) {
        for (DateTime date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          for (final time in times) {
            await _supabase
                .from('reservation_slots')
                .delete()
                .eq('route_id', routeId)
                .eq('direction', direction)
                .eq('slot_date', date.toIso8601String().split('T')[0])
                .eq('slot_time', time);
          }
        }
      }
    } catch (e) {
      print('Error deleting reservation slots: $e');
      rethrow;
    }
  }
}
