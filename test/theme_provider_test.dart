import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:slotted/common/colors.dart';

void main() {
  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;

    setUp(() async {
      // Initialize SharedPreferences with default values
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark', // Default to dark mode
      });
      themeProvider = ThemeProvider();
      // Wait for the initial theme to load
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('theme should always be dark mode', () async {
      expect(themeProvider.isDarkMode, true);
    });

    test('toggleTheme should have no effect', () async {
      // Initially in dark mode
      expect(themeProvider.isDarkMode, true);

      // Attempt to toggle theme - should remain in dark mode
      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, true);

      // Attempt to toggle again - should still remain in dark mode
      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, true);
    });

    test('theme preference should always be dark mode after app restart', () async {
      // Initially in dark mode
      expect(themeProvider.isDarkMode, true);

      // Create a new instance to simulate app restart
      final newThemeProvider = ThemeProvider();
      // Wait for the theme to load from SharedPreferences
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Theme should still be dark mode
      expect(newThemeProvider.isDarkMode, true);
    });

    test('ThemeProvider colors are set for dark mode', () async {
      expect(themeProvider.backgroundColor, equals(AppColors.backgroundDark));
      expect(themeProvider.textColor, equals(AppColors.backgroundLight));
      expect(themeProvider.primaryColor, equals(AppColors.primary));
      expect(themeProvider.accentColor, equals(AppColors.accent));
    });

    test('ThemeProvider notifies listeners when calling toggleTheme', () async {
      var notificationCount = 0;
      
      // Add listener to count notifications
      themeProvider.addListener(() {
        notificationCount++;
      });

      // Toggle theme - should notify despite no change
      await themeProvider.toggleTheme();
      expect(notificationCount, 1);
      
      // Theme should still be dark mode
      expect(themeProvider.isDarkMode, true);
    });
  });
} 