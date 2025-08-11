import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  bool _isHighContrast = false;
  bool _isLargeText = false;
  final SupabaseService _supabaseService = SupabaseService.instance;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isHighContrast => _isHighContrast;
  bool get isLargeText => _isLargeText;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  Future<void> _loadThemeMode() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        // Try to load from Supabase first
        await _loadFromSupabase(currentUser.id);
      } else {
        // Fallback to SharedPreferences for offline/guest users
        await _loadFromPreferences();
      }
    } catch (e) {
      debugPrint('❌ Error loading theme preferences: $e');
      // Fallback to SharedPreferences
      await _loadFromPreferences();
    }
    notifyListeners();
  }

  Future<void> _loadFromSupabase(String userId) async {
    final response = await _supabaseService.client
        .from('user_preferences')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      final themeModeString = response['theme_mode'] as String? ?? 'system';
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString().split('.').last == themeModeString,
        orElse: () => ThemeMode.system,
      );
      _isHighContrast = response['is_high_contrast'] as bool? ?? false;
      _isLargeText = response['is_large_text'] as bool? ?? false;

      debugPrint('✅ Theme preferences loaded from Supabase');
    } else {
      // Create default preferences in Supabase
      await _createDefaultPreferences(userId);
    }
  }

  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeModeString = prefs.getString(_themeKey);
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }
    _isHighContrast = prefs.getBool('isHighContrast') ?? false;
    _isLargeText = prefs.getBool('isLargeText') ?? false;

    debugPrint('✅ Theme preferences loaded from SharedPreferences');
  }

  Future<void> _createDefaultPreferences(String userId) async {
    try {
      await _supabaseService.client
          .from('user_preferences')
          .insert({
            'user_id': userId,
            'theme_mode': 'system',
            'is_high_contrast': false,
            'is_large_text': false,
          });
      debugPrint('✅ Default theme preferences created in Supabase');
    } catch (e) {
      debugPrint('❌ Error creating default preferences: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  Future<void> setHighContrast(bool value) async {
    if (_isHighContrast == value) return;
    _isHighContrast = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setLargeText(bool value) async {
    if (_isLargeText == value) return;
    _isLargeText = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        // Save to Supabase
        await _supabaseService.client
            .from('user_preferences')
            .upsert({
              'user_id': currentUser.id,
              'theme_mode': _themeMode.toString().split('.').last,
              'is_high_contrast': _isHighContrast,
              'is_large_text': _isLargeText,
              'updated_at': DateTime.now().toIso8601String(),
            });
        debugPrint('✅ Theme preferences saved to Supabase');
      }

      // Also save to SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode.toString());
      await prefs.setBool('isHighContrast', _isHighContrast);
      await prefs.setBool('isLargeText', _isLargeText);

    } catch (e) {
      debugPrint('❌ Error saving theme preferences: $e');
      // Fallback to SharedPreferences only
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode.toString());
      await prefs.setBool('isHighContrast', _isHighContrast);
      await prefs.setBool('isLargeText', _isLargeText);
    }
  }
}
