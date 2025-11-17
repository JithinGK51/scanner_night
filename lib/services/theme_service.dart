import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;

  const AppTheme({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
  });

  ColorScheme get colorScheme => ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        brightness: Brightness.light,
      );

  ColorScheme get darkColorScheme => ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        brightness: Brightness.dark,
      );
}

class ThemeService {
  static const String _colorThemeKey = 'color_theme';
  static const String _defaultColorTheme = 'Teal';

  // 10 Account Color Themes
  static final Map<String, AppTheme> _themes = {
    'Teal': const AppTheme(
      name: 'Teal',
      primaryColor: Color(0xFF00897B),
      secondaryColor: Color(0xFF4DB6AC),
      accentColor: Color(0xFF26A69A),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Color(0xFF212121),
      subtitleColor: Color(0xFF757575),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFF9800),
    ),
    'Blue': const AppTheme(
      name: 'Blue',
      primaryColor: Color(0xFF1976D2),
      secondaryColor: Color(0xFF42A5F5),
      accentColor: Color(0xFF2196F3),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Color(0xFF212121),
      subtitleColor: Color(0xFF757575),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFF9800),
    ),
    'Purple': const AppTheme(
      name: 'Purple',
      primaryColor: Color(0xFF7B1FA2),
      secondaryColor: Color(0xFFBA68C8),
      accentColor: Color(0xFF9C27B0),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Color(0xFF212121),
      subtitleColor: Color(0xFF757575),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFF9800),
    ),
    'Green': const AppTheme(
      name: 'Green',
      primaryColor: Color(0xFF388E3C),
      secondaryColor: Color(0xFF66BB6A),
      accentColor: Color(0xFF4CAF50),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Color(0xFF212121),
      subtitleColor: Color(0xFF757575),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFF9800),
    ),
    'Orange': const AppTheme(
      name: 'Orange',
      primaryColor: Color(0xFFF57C00),
      secondaryColor: Color(0xFFFFB74D),
      accentColor: Color(0xFFFF9800),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Color(0xFF212121),
      subtitleColor: Color(0xFF757575),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFF9800),
    ),
    'Red': const AppTheme(
      name: 'Red',
      primaryColor: Color(0xFFD32F2F),
      secondaryColor: Color(0xFFE57373),
      accentColor: Color(0xFFF44336),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Color(0xFF212121),
      subtitleColor: Color(0xFF757575),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFF9800),
    ),
    'Pink': const AppTheme(
      name: 'Pink',
      primaryColor: Color(0xFFC2185B),
      secondaryColor: Color(0xFFF06292),
      accentColor: Color(0xFFE91E63),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Color(0xFF212121),
      subtitleColor: Color(0xFF757575),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFF9800),
    ),
    'Indigo': const AppTheme(
      name: 'Indigo',
      primaryColor: Color(0xFF303F9F),
      secondaryColor: Color(0xFF7986CB),
      accentColor: Color(0xFF3F51B5),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Color(0xFF212121),
      subtitleColor: Color(0xFF757575),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFF9800),
    ),
    'Cyan': const AppTheme(
      name: 'Cyan',
      primaryColor: Color(0xFF0097A7),
      secondaryColor: Color(0xFF4DD0E1),
      accentColor: Color(0xFF00BCD4),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Color(0xFF212121),
      subtitleColor: Color(0xFF757575),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFF9800),
    ),
    'Amber': const AppTheme(
      name: 'Amber',
      primaryColor: Color(0xFFFF6F00),
      secondaryColor: Color(0xFFFFCA28),
      accentColor: Color(0xFFFFC107),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Color(0xFF212121),
      subtitleColor: Color(0xFF757575),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFF9800),
    ),
  };

  static List<String> get availableThemes => _themes.keys.toList();
  static AppTheme getTheme(String name) => _themes[name] ?? _themes[_defaultColorTheme]!;
  static AppTheme get defaultTheme => _themes[_defaultColorTheme]!;

  Future<String> getColorTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_colorThemeKey) ?? _defaultColorTheme;
  }

  Future<void> setColorTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorThemeKey, themeName);
  }

  AppTheme getCurrentTheme(String themeName) {
    return _themes[themeName] ?? _themes[_defaultColorTheme]!;
  }
}

