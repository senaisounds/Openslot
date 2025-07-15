import 'package:flutter/material.dart';

import 'package:slotted/common/colors.dart';
import 'package:slotted/utils/logger.dart';
class ThemeProvider extends ChangeNotifier {
  // Always use dark mode, no toggle option
  // No unnecessary methods or state variables
  
  // Always return true for dark mode
  bool get isDarkMode => true;

  // Get current theme colors - always use dark mode values
  Color get primaryColor => AppColors.primary;
  Color get backgroundColor => AppColors.backgroundDark;
  Color get textColor => AppColors.backgroundLight;
  Color get accentColor => AppColors.accent;
  Color get secondaryTextColor => AppColors.backgroundLight.withValues(alpha: 0.7);
  
  // Get opacity levels for dark mode only
  double get primaryOpacity => 1.0;
  double get secondaryOpacity => 0.8;
  double get backgroundOpacity => 0.8;

  // Animation duration for theme transitions
  final Duration themeSwitchDuration = const Duration(milliseconds: 300);
  
  /// Toggle theme method - for compatibility with tests
  /// This method doesn't actually change the theme (always dark mode)
  /// but notifies listeners for compatibility with existing code
  Future<void> toggleTheme() async {
    try {
      // App is always in dark mode, so this method does nothing
      // except notify listeners for compatibility
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.e('Error in async operation', 
              tag: 'ThemeProvider', 
              error: e, 
              stackTrace: stackTrace);
      // Handle error gracefully
    }
  }
} 