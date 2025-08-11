import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color _primaryColor = Color(0xFF1D1691);
  static const Color _secondaryColor = Color(0xFFE9EFFC);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _backgroundColor = Color(0xFFF9FAFB);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF1F2937);
  static const Color _secondaryTextColor = Color(0xFF6B7280);
  static const Color _starColor = Color(0xFFFFC107);

  // Status Colors
  static const Color _successColor = Color(0xFF22C55E);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _infoColor = Color(0xFF3B82F6);

  // New route screen specific colors
  static const Color _routeCardBg = Color(0xFFF8F9FF);
  static const Color _activeStatusBg = Color(0xFF4338CA);
  static const Color _dividerColor = Color(0xFFE5E7EB);

  // Modern design colors
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _surfaceVariant = Color(0xFFF8FAFC);
  static const Color _gradientStart = Color(0xFF6366F1);
  static const Color _gradientEnd = Color(0xFF8B5CF6);

  // Color getters
  static Color get primaryColor => _primaryColor;
  static Color get secondaryColor => _secondaryColor;
  static Color get errorColor => _errorColor;
  static Color get secondaryTextColor => _secondaryTextColor;
  static Color get cardColor => _cardColor;
  static Color get backgroundColor => _backgroundColor;
  static Color get textColor => _textColor;
  static Color get successColor => _successColor;
  static Color get warningColor => _warningColor;
  static Color get infoColor => _infoColor;
  static Color get routeCardBg => _routeCardBg;
  static Color get activeStatusBg => _activeStatusBg;
  static Color get dividerColor => _dividerColor;
  static Color get borderColor => _borderColor;
  static Color get surfaceVariant => _surfaceVariant;
  static Color get gradientStart => _gradientStart;

  // Modern gradient
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [_gradientStart, _gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Modern shadows
  static List<BoxShadow> get modernShadow => [
        BoxShadow(
          color: _primaryColor.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF1F2937);
  static const Color darkCardColor = Color(0xFF374151);
  static const Color darkTextColor = Color(0xFFF9FAFB);
  static const Color darkSecondaryTextColor = Color(0xFFD1D5DB);

  // Button Styles
  static ButtonStyle segmentedButton({required bool isSelected}) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all(
        isSelected ? _cardColor : Colors.transparent,
      ),
      foregroundColor: MaterialStateProperty.all(
        isSelected ? _primaryColor : _secondaryTextColor,
      ),
      shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.1)),
      elevation: MaterialStateProperty.all(isSelected ? 2 : 0),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  static BoxDecoration segmentedButtonContainer() {
    return BoxDecoration(
      color: _secondaryColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _secondaryColor),
    );
  }

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _backgroundColor,
    cardColor: _cardColor,
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: _textColor, fontWeight: FontWeight.bold, fontSize: 24),
      displayMedium: TextStyle(
          color: _textColor, fontWeight: FontWeight.bold, fontSize: 20),
      displaySmall: TextStyle(
          color: _textColor, fontWeight: FontWeight.bold, fontSize: 18),
      headlineMedium: TextStyle(
          color: _textColor, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(color: _textColor, fontSize: 16),
      bodyMedium: TextStyle(color: _textColor, fontSize: 14),
      bodySmall: TextStyle(color: _secondaryTextColor, fontSize: 12),
    ),
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _starColor,
      error: _errorColor,
      background: _backgroundColor,
      surface: _cardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: _textColor,
      onSurface: _textColor,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: _textColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: _cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E7EB),
      thickness: 1,
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    cardColor: darkCardColor,
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 24),
      displayMedium: TextStyle(
          color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 20),
      displaySmall: TextStyle(
          color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 18),
      headlineMedium: TextStyle(
          color: darkTextColor, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(color: darkTextColor, fontSize: 16),
      bodyMedium: TextStyle(color: darkTextColor, fontSize: 14),
      bodySmall: TextStyle(color: darkSecondaryTextColor, fontSize: 12),
    ),
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      error: _errorColor,
      background: darkBackgroundColor,
      surface: darkCardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: darkTextColor,
      onSurface: darkTextColor,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkCardColor,
      foregroundColor: darkTextColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4B5563)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4B5563)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: darkCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF4B5563),
      thickness: 1,
    ),
  );
}
