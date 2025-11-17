import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// InheritedWidget to provide theme to all screens
class ThemeProvider extends InheritedWidget {
  final AppTheme currentTheme;
  final String themeMode;
  final String colorTheme;
  final Function(String) updateThemeMode;
  final Function(String) updateColorTheme;

  const ThemeProvider({
    super.key,
    required this.currentTheme,
    required this.themeMode,
    required this.colorTheme,
    required this.updateThemeMode,
    required this.updateColorTheme,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return oldWidget.currentTheme != currentTheme ||
        oldWidget.themeMode != themeMode ||
        oldWidget.colorTheme != colorTheme;
  }
}

