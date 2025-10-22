import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  bool _isHighContrast = false;
  bool _isLargeText = false;

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
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHighContrast', value);
    notifyListeners();
  }

  Future<void> setLargeText(bool value) async {
    if (_isLargeText == value) return;
    _isLargeText = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLargeText', value);
    notifyListeners();
  }
}
