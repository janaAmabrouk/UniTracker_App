import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart'
    show RealtimeListenTypes, PostgresChangeFilter;

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  // Auth methods
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> changePassword(String newPassword) async {
    await client.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }

  Future<bool> verifyCurrentPassword(String password) async {
    try {
      final response = await client.functions.invoke(
        'verify-user-password',
        body: {'password': password},
      );

      if (response.status != 200) {
        // The edge function returned an error (e.g., 400 for invalid password)
        return false;
      }

      final data = response.data;
      if (data != null && data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('🔥 SupabaseService: verifyCurrentPassword error: $e');
      return false;
    }
  }

  // User profile methods
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response =
        await client.from('users').select().eq('id', userId).maybeSingle();
    return response;
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await client.from('users').update(data).eq('id', userId);
  }

  Future<void> createUserProfile(Map<String, dynamic> data) async {
    try {
      debugPrint('🔥 SupabaseService: Creating user profile with data: $data');

      final response = await client.from('users').insert(data).select();

      debugPrint(
          '✅ SupabaseService: User profile created successfully: $response');
    } catch (e) {
      debugPrint('❌ SupabaseService: Error creating user profile: $e');
      debugPrint('❌ SupabaseService: Data that failed to insert: $data');
      rethrow;
    }
  }

  Future<void> createDriverRecord(Map<String, dynamic> data) async {
    try {
      debugPrint('🔥 SupabaseService: Creating driver record with data: $data');

      final response = await client.from('drivers').insert(data).select();

      debugPrint(
          '✅ SupabaseService: Driver record created successfully: $response');
    } catch (e) {
      debugPrint('❌ SupabaseService: Error creating driver record: $e');
      debugPrint('❌ SupabaseService: Data that failed to insert: $data');
      rethrow;
    }
  }

  // Routes methods
  Future<List<Map<String, dynamic>>> getRoutes() async {
    final response = await client
        .from('routes')
        .select('*, bus_stops(*)')
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getRoute(String routeId) async {
    final response = await client
        .from('routes')
        .select('*, bus_stops(*)')
        .eq('id', routeId)
        .maybeSingle();
    return response;
  }

  // Reservations methods
  Future<List<Map<String, dynamic>>> getUserReservations(String userId) async {
    final response = await client.from('reservations').select('''
      *,
      routes(*),
      buses(*),
      pickup_stop:bus_stops!pickup_stop_id(*),
      drop_stop:bus_stops!drop_stop_id(*),
      reservation_slots:reservation_slots!slot_id(
        id,
        slot_date,
        slot_time,
        direction,
        capacity
      )
    ''').eq('user_id', userId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createReservation(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client.from('reservations').insert(data).select('''
            *,
            routes(*),
            pickup_stop:bus_stops!pickup_stop_id(*),
            drop_stop:bus_stops!drop_stop_id(*)
          ''').single();

      if (response == null) {
        throw Exception('Failed to create reservation: No data returned');
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('🔥 SupabaseService: createReservation error: $e');
      throw Exception('Failed to create reservation: $e');
    }
  }

  Future<void> updateReservation(
    String reservationId,
    Map<String, dynamic> data,
  ) async {
    await client.from('reservations').update(data).eq('id', reservationId);
  }

  Future<void> cancelReservation(String reservationId) async {
    await client
        .from('reservations')
        .update({'status': 'cancelled'}).eq('id', reservationId);
  }

  // Notifications methods
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    final response = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createNotification(Map<String, dynamic> data) async {
    await client.from('notifications').insert(data);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> deleteAllUserNotifications(String userId) async {
    await client.from('notifications').delete().eq('user_id', userId);
  }

  // Bus tracking methods
  Future<List<Map<String, dynamic>>> getBusLocations(String routeId) async {
    final response = await client
        .from('bus_locations')
        .select('*, buses(*)')
        .eq('buses.route_id', routeId)
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateBusLocation(
    String busId,
    Map<String, dynamic> locationData,
  ) async {
    await client.from('bus_locations').upsert({
      'bus_id': busId,
      ...locationData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Schedules methods
  Future<List<Map<String, dynamic>>> getSchedules(String routeId) async {
    final response = await client
        .from('schedules')
        .select('*, routes(*), buses(*)')
        .eq('route_id', routeId)
        .eq('is_active', true)
        .order('departure_time');
    return List<Map<String, dynamic>>.from(response);
  }

  // Real-time subscriptions (using .stream for table changes)
  Stream<List<Map<String, dynamic>>> subscribeToUserNotifications(
      String userId) {
    return client
        .from('notifications')
        .stream(primaryKey: ['id']).eq('user_id', userId);
  }

  Stream<List<Map<String, dynamic>>> subscribeToBusLocations(String routeId) {
    return client
        .from('bus_locations')
        .stream(primaryKey: ['id']).eq('route_id', routeId);
  }

  Stream<List<Map<String, dynamic>>> subscribeToReservations(String userId) {
    return client
        .from('reservations')
        .stream(primaryKey: ['id']).eq('user_id', userId);
  }

  // Driver-specific methods
  Future<Map<String, dynamic>?> getDriverAssignment(String driverId) async {
    debugPrint('🔍 SupabaseService: Querying driver assignment for: $driverId');
    try {
      final today = DateTime.now();
      final dayOfWeek = today.weekday; // 1=Monday, 7=Sunday

      final response = await client
          .from('schedules')
          .select('''
            id,
            driver_id,
            route_id,
            bus_id,
            departure_time,
            arrival_time,
            days_of_week,
            is_active,
            created_at,
            routes!inner(
              id,
              name,
              pickup_location,
              drop_location,
              start_time,
              end_time,
              color_code
            ),
            buses!inner(
              id,
              bus_number,
              capacity,
              status
            )
          ''')
          .eq('driver_id', driverId)
          .eq('is_active', true)
          .contains('days_of_week', [
            dayOfWeek,
          ]) // Filter by current day of week
          .order('created_at', ascending: false)
          .limit(1);

      debugPrint(
        '🔍 SupabaseService: Query response length: ${response.length}',
      );

      if (response.isEmpty) {
        debugPrint('🔍 SupabaseService: No driver assignment found for today.');
        return null;
      }

      final result = response.first as Map<String, dynamic>;
      debugPrint('🔍 SupabaseService: Returning assignment: ${result['id']}');
      return result;
    } catch (e) {
      debugPrint('❌ SupabaseService: Error querying driver assignment: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDriverTripHistory(
    String driverId, {
    int limit = 50,
  }) async {
    final response = await client
        .from('trip_history')
        .select('''
          *,
          routes(name),
          buses(bus_number)
        ''')
        .eq('driver_id', driverId)
        .order('trip_date', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> completeTrip({
    required String driverId,
    required String routeId,
    required String busId,
    required DateTime startTime,
    required DateTime endTime,
    required int passengerCount,
    required double distanceKm,
    required bool onTime,
    String? notes,
  }) async {
    final response = await client
        .from('trip_history')
        .insert({
          'driver_id': driverId,
          'route_id': routeId,
          'bus_id': busId,
          'trip_date': DateTime.now().toIso8601String().split('T')[0],
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'passenger_count': passengerCount,
          'distance_km': distanceKm,
          'on_time': onTime,
          'notes': notes,
          'status': 'completed',
        })
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>> getDriverStats(String driverId) async {
    // Get trip statistics
    final statsResponse =
        await client.from('trip_history').select('*').eq('driver_id', driverId);

    final trips = List<Map<String, dynamic>>.from(statsResponse);
    print('DEBUG: getDriverStats trips = ' + trips.toString());

    final totalTrips = trips.length;
    final completedTrips =
        trips.where((trip) => trip['status'] == 'completed').length;
    final onTimeTrips = trips
        .where(
            (trip) => trip['status'] == 'completed' && trip['on_time'] == true)
        .length;
    final onTimePerformance =
        completedTrips > 0 ? (onTimeTrips / completedTrips) * 100 : 0.0;

    // Calculate average passenger count
    final totalPassengers = trips.fold<int>(
      0,
      (sum, trip) => sum + (trip['passenger_count'] as int? ?? 0),
    );
    final avgPassengers = totalTrips > 0 ? totalPassengers / totalTrips : 0.0;

    return {
      'total_trips': totalTrips,
      'completed_trips': completedTrips,
      'on_time_performance': onTimePerformance,
      'average_passengers': avgPassengers,
      'total_distance': trips.fold<double>(
        0,
        (sum, trip) => sum + (trip['distance_km'] as double? ?? 0),
      ),
      'rating': 4.5, // Mock rating for now
      'safety_score': 95.0, // Mock safety score
      'customer_satisfaction': 4.3, // Mock satisfaction
    };
  }

  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    required double speed,
    required bool isMoving,
  }) async {
    // Get driver's current bus assignment
    final assignment = await getDriverAssignment(driverId);
    if (assignment != null && assignment['bus_id'] != null) {
      await updateBusLocation(assignment['bus_id'], {
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'is_moving': isMoving,
        'heading': 0, // Can be calculated from GPS
      });
    }
  }

  Future<String?> uploadDriverLicenseImage({
    required String driverId,
    required String filePath,
    Uint8List? fileBytes, // For web
  }) async {
    final fileExt = path.extension(filePath);
    final fileName =
        'license_${driverId}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
    final storagePath = 'licenses/$fileName';

    final storage = client.storage.from('driver-license-images');
    try {
      if (kIsWeb && fileBytes != null) {
        await storage.uploadBinary(storagePath, fileBytes);
      } else {
        await storage.upload(storagePath, File(filePath));
      }
      // If no exception, upload succeeded
      return storage.getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<String?> uploadDriverProfileImage({
    required String driverId,
    required String filePath,
    Uint8List? fileBytes, // For web
  }) async {
    final fileExt = path.extension(filePath);
    final fileName =
        'profile_${driverId}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
    final storagePath = 'profiles/$fileName';

    final storage = client.storage.from('profile-images');
    try {
      if (kIsWeb && fileBytes != null) {
        await storage.uploadBinary(storagePath, fileBytes);
      } else {
        await storage.upload(storagePath, File(filePath));
      }
      // If no exception, upload succeeded
      return storage.getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> updateDriverProfileImage(
      String driverId, String imageUrl) async {
    await client.from('drivers').update({
      'profile_image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', driverId);
  }
}
