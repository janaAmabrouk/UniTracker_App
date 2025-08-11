import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/bus_schedule.dart';

class ScheduleProvider with ChangeNotifier {
  List<BusSchedule> _schedules = [];
  bool _isLoading = false;
  String? _error;

  List<BusSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<BusSchedule> get favoriteSchedules =>
      _schedules.where((s) => s.isFavorite).toList();

  Future<void> loadSchedules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data - in a real app, this would be fetched from an API
      _schedules = [];

      // Load saved favorites
      await _loadFavorites();
    } catch (e) {
      _error = 'Failed to load schedules: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleFavorite(String id) {
    final scheduleIndex = _schedules.indexWhere((s) => s.id == id);
    if (scheduleIndex != -1) {
      _schedules[scheduleIndex].isFavorite =
          !_schedules[scheduleIndex].isFavorite;
      _saveFavorites(); // Save to persistent storage
      notifyListeners();
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('schedule_favorites');
      if (favoritesJson != null) {
        final List<dynamic> favoriteIds = json.decode(favoritesJson);
        for (final schedule in _schedules) {
          schedule.isFavorite = favoriteIds.contains(schedule.id);
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = _schedules
          .where((schedule) => schedule.isFavorite)
          .map((schedule) => schedule.id)
          .toList();
      await prefs.setString('schedule_favorites', json.encode(favoriteIds));
      debugPrint('✅ Favorites saved: $favoriteIds');
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  List<BusSchedule> filterSchedules({
    required String searchQuery,
    required String timeFilter,
    required bool showFavorites,
  }) {
    return _schedules.where((schedule) {
      // Apply search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!schedule.name.toLowerCase().contains(query) &&
            !schedule.pickup.toLowerCase().contains(query) &&
            !schedule.drop.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Apply favorites filter
      if (showFavorites && !schedule.isFavorite) {
        return false;
      }

      // Apply time filter
      switch (timeFilter) {
        case 'Morning':
          return schedule.morningPickupTime.isNotEmpty;
        case 'Afternoon':
          return schedule.afternoonRoute;
        case 'Evening':
          return schedule.eveningPickupTime.isNotEmpty;
        default:
          return true;
      }
    }).toList();
  }
}
