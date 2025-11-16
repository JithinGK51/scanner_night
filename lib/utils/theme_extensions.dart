import 'package:flutter/material.dart';
import '../services/theme_service.dart';

extension ThemeExtension on BuildContext {
  AppTheme get appTheme {
    final themeService = ThemeService();
    // This is a simplified approach - in production, you might want to use
    // an InheritedWidget or Provider to access the current theme
    // For now, we'll get it from the theme service
    return themeService.getCurrentTheme('Teal'); // Will be updated via Theme.of(context)
  }
  
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get tertiaryColor => Theme.of(this).colorScheme.tertiary;
  Color get errorColor => Theme.of(this).colorScheme.error;
  Color get successColor => const Color(0xFF4CAF50);
  Color get warningColor => const Color(0xFFFF9800);
}

