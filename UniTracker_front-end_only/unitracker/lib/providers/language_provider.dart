import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'language_code';
  Locale _currentLocale = const Locale('en');
  bool _isRTL = false;
  bool _isLoading = false;
  String? _error;

  LanguageProvider() {
    _loadLanguage();
  }

  Locale get currentLocale => _currentLocale;
  bool get isRTL => _isRTL;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      _isRTL = languageCode == 'ar';
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;
    _currentLocale = Locale(languageCode);
    _isRTL = languageCode == 'ar';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isAmharic => _currentLocale.languageCode == 'am';

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
