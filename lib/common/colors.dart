import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

// Comprehensive color management through a single class
class AppColors {
  // Enhanced Main Theme Colors - More sophisticated palette
  static const Color primary = Color(0xFFFF6B35);          // Vibrant Orange - Stage Lights
  static const Color primaryDark = Color(0xFFE85A2E);      // Darker orange for depth
  static const Color primaryLight = Color(0xFFFF8F66);     // Lighter orange for highlights
  
  static const Color secondary = Color(0xFFFF8C42);        // Soft Orange - Energy
  static const Color secondaryDark = Color(0xFFE67A35);    // Darker secondary
  static const Color secondaryLight = Color(0xFFFFA366);   // Lighter secondary
  
  static const Color accent = Color(0xFFFFA500);           // Electric Orange - Microphone Glow
  static const Color highlight = Color(0xFFFFE79B);        // Warm Yellow - Spotlight
  
  // Enhanced Background System
  static const Color backgroundDark = Color(0xFF0A0A0A);       // Richer black
  static const Color backgroundMedium = Color(0xFF1A1A1A);     // Medium dark
  static const Color backgroundLight = Color(0xFFF8F9FA);      // Softer light
  static const Color backgroundCard = Color(0xFF1E1E1E);       // Card background
  static const Color backgroundElevated = Color(0xFF2A2A2A);   // Elevated surfaces
  
  // Neutral Color Palette for Better Hierarchy
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);
  
  // Background colors for home page - refined
  static const Color orangeBackground = Color(0xFFFFA500);
  static const Color yellowBackground = Color(0xFFFFD700);
  
  // Legacy color - kept for backward compatibility
  static const Color openSlotOrange = Color.fromARGB(255, 238, 125, 48);
  static const Color slottedOrange = openSlotOrange; // Alias
  
  // Enhanced Event Category Colors - More sophisticated and accessible
  static const Map<String, Color> eventCategory = {
    'COMEDY': Color(0xFFE74C3C),    // Modern Red - Better contrast
    'DJ': Color(0xFF3498DB),        // Vibrant Blue - Better accessibility 
    'POETRY': Color(0xFFF39C12),    // Warm Amber - Refined yellow
    'MUSIC': Color(0xFF9B59B6),     // Purple - More distinctive
    'OTHER': Color(0xFF34C759),     // Green - iOS system green
  };
  
  // Enhanced Event Category Gradients with better color stops
  static const Map<String, List<Color>> eventCategoryGradient = {
    'COMEDY': [Color(0xFFE74C3C), Color(0xFFC0392B)],    // Red gradient
    'DJ': [Color(0xFF3498DB), Color(0xFF2980B9)],        // Blue gradient
    'POETRY': [Color(0xFFF39C12), Color(0xFFE67E22)],    // Amber gradient
    'MUSIC': [Color(0xFF9B59B6), Color(0xFF8E44AD)],     // Purple gradient
    'OTHER': [Color(0xFF34C759), Color(0xFF28A745)],     // Green gradient
  };
  
  // Event Category Icons - Material style (for Material Design contexts)
  static const Map<String, IconData> eventCategoryIcon = {
    'COMEDY': Icons.sentiment_very_satisfied_rounded,
    'DJ': Icons.headset_rounded,
    'POETRY': Icons.auto_stories_rounded,
    'MUSIC': Icons.music_note_rounded,
    'OTHER': Icons.event_rounded,
  };
  
  // Event Category Icons - Cupertino style (for iOS-style interfaces)
  static const Map<String, IconData> eventCategoryIconCupertino = {
    'COMEDY': CupertinoIcons.smiley_fill,
    'DJ': CupertinoIcons.headphones,
    'POETRY': CupertinoIcons.text_quote, 
    'MUSIC': CupertinoIcons.music_mic,
    'OTHER': CupertinoIcons.star_fill,
  };
  
  // Enhanced text colors with better hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF);      // Pure white for dark mode
  static const Color textSecondary = Color(0xFFB0B0B0);   // Medium gray
  static const Color textTertiary = Color(0xFF808080);    // Light gray
  static const Color textHint = Color(0xFF606060);        // Subtle gray
  static const Color textDisabled = Color(0xFF404040);    // Disabled state
  
  // Light mode text colors
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textTertiaryLight = Color(0xFF999999);
  
  // Enhanced status colors with better accessibility
  static const Color success = Color(0xFF34C759);         // iOS system green
  static const Color successDark = Color(0xFF28A745);
  static const Color warning = Color(0xFFFF9500);         // iOS system orange
  static const Color warningDark = Color(0xFFE85A00);
  static const Color info = Color(0xFF007AFF);            // iOS system blue
  static const Color infoDark = Color(0xFF0056CC);
  static const Color error = Color(0xFFFF3B30);           // iOS system red
  static const Color errorDark = Color(0xFFD70015);
  
  // Enhanced UI colors
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFF2A2A2A);
  static const Color dividerLight = Color(0xFFE5E5E5);
  static const Color disabled = Color(0xFF404040);
  static const Color disabledLight = Color(0xFFBDBDBD);
  
  // Interactive colors for better UX
  static const Color interactive = Color(0xFF007AFF);
  static const Color interactivePressed = Color(0xFF0056CC);
  static const Color interactiveDisabled = Color(0xFF404040);
  
  // Enhanced gradients with multiple variations
  static LinearGradient getPrimaryGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<double>? stops,
    double opacity = 1.0,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      stops: stops ?? [0.0, 0.5, 1.0],
      colors: [
        primaryLight.withValues(alpha: opacity),
        primary.withValues(alpha: opacity),
        primaryDark.withValues(alpha: opacity),
      ],
    );
  }
  
  // Hero gradient for premium feel
  static LinearGradient getHeroGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double opacity = 1.0,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      stops: const [0.0, 0.3, 0.7, 1.0],
      colors: [
        primary.withValues(alpha: opacity),
        accent.withValues(alpha: opacity * 0.8),
        secondary.withValues(alpha: opacity * 0.6),
        primaryDark.withValues(alpha: opacity),
      ],
    );
  }
  
  // Enhanced category gradient with better color science
  static LinearGradient getCategoryGradient(String category, {
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double opacity = 1.0,
  }) {
    final normalizedCategory = category.toUpperCase().split(' ')[0];
    final colors = eventCategoryGradient[normalizedCategory] ?? 
        [primary, primaryDark];
    
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        colors[0].withValues(alpha: opacity),
        colors[1].withValues(alpha: opacity),
      ],
    );
  }
  
  // Get category color for consistent UI
  static Color getCategoryColor(String category) {
    final normalizedCategory = category.toUpperCase().split(' ')[0];
    return eventCategory[normalizedCategory] ?? primary;
  }
  
  // Get category icon (Material) for consistent UI
  static IconData getCategoryIcon(String category) {
    final normalizedCategory = category.toUpperCase().split(' ')[0];
    return eventCategoryIcon[normalizedCategory] ?? Icons.event_rounded;
  }
  
  // Get category icon (Cupertino) for consistent UI
  static IconData getCategoryIconCupertino(String category) {
    final normalizedCategory = category.toUpperCase().split(' ')[0];
    return eventCategoryIconCupertino[normalizedCategory] ?? CupertinoIcons.star_fill;
  }
  
  // Enhanced smoke effect gradient with better physics
  static RadialGradient getSmokeGradient({
    required double progress,
    double opacity = 0.12,
    double intensity = 1.0,
  }) {
    final baseOpacity = opacity * intensity;
    return RadialGradient(
      center: Alignment(
        _sin(progress * 3.14159 * 2) * 0.4,
        _cos(progress * 3.14159 * 2) * 0.4,
      ),
      focal: Alignment(
        _cos(progress * 3.14159) * 0.6,
        _sin(progress * 3.14159) * 0.6,
      ),
      colors: [
        primaryLight.withValues(alpha: baseOpacity),
        primary.withValues(alpha: baseOpacity * 0.8),
        accent.withValues(alpha: baseOpacity * 0.6),
        secondary.withValues(alpha: baseOpacity * 0.4),
        Colors.transparent,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      radius: 2.2,
    );
  }
  
  // Glassmorphism effect for modern cards
  static BoxDecoration getGlassmorphismDecoration({
    double blur = 20,
    double opacity = 0.1,
    Color? borderColor,
    double borderWidth = 1,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: borderColor != null 
          ? Border.all(color: borderColor.withValues(alpha: 0.2), width: borderWidth)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: blur,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
  
  // Helper functions for sin/cos in gradient
  static double _sin(double value) => math.sin(value);
  static double _cos(double value) => math.cos(value);
  
  // Color accessibility helpers
  static Color getAccessibleTextColor(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.light ? textPrimaryLight : textPrimary;
  }
  
  static bool isColorAccessible(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final ratio = (math.max(foregroundLuminance, backgroundLuminance) + 0.05) /
                  (math.min(foregroundLuminance, backgroundLuminance) + 0.05);
    return ratio >= 4.5; // WCAG AA standard
  }
}

// Extension method for Color to modify values - Enhanced
extension ColorExtension on Color {
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromARGB(
      alpha != null ? (alpha * 255).round() : a.toInt(),
      red ?? r.toInt(),
      green ?? g.toInt(),
      blue ?? b.toInt(),
    );
  }
  
  // Color manipulation helpers
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
  
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
  
  Color saturate([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl.withSaturation((hsl.saturation + amount).clamp(0.0, 1.0)).toColor();
  }
}

// Legacy constants to maintain backward compatibility in existing code
// These will be gradually phased out in favor of AppColors
@Deprecated('Use AppColors.primary instead')
const Color kPrimary = AppColors.primary;

@Deprecated('Use AppColors.secondary instead')
const Color kSecondary = AppColors.secondary;

@Deprecated('Use AppColors.accent instead')
const Color kAccent = AppColors.accent;

@Deprecated('Use AppColors.highlight instead')
const Color kHighlight = AppColors.highlight;

@Deprecated('Use AppColors.backgroundDark instead')
const Color kBackgroundDark = AppColors.backgroundDark;

@Deprecated('Use AppColors.backgroundLight instead')
const Color kBackgroundLight = AppColors.backgroundLight;

@Deprecated('Use AppColors.orangeBackground instead')
const Color kOrangeBackground = AppColors.orangeBackground;

@Deprecated('Use AppColors.yellowBackground instead')
const Color kYellowBackground = AppColors.yellowBackground;

@Deprecated('Use AppColors.openSlotOrange instead')
const Color kOpenSlotOrange = AppColors.openSlotOrange;

@Deprecated('Use AppColors.slottedOrange instead')
const Color kSlottedOrange = AppColors.slottedOrange;

@Deprecated('Use AppColors.eventCategory instead')
const eventCategoryColors = AppColors.eventCategory;

@Deprecated('Use AppColors.eventCategoryGradient instead')
const eventCategoryGradients = AppColors.eventCategoryGradient;

@Deprecated('Use AppColors.eventCategoryIcon instead')
const eventCategoryIcons = AppColors.eventCategoryIcon;

@Deprecated('Use AppColors.eventCategoryIconCupertino instead')
const eventCategoryIconsCupertino = AppColors.eventCategoryIconCupertino;

// Main Theme Colors
const Color kPrimaryColor = Color(0xFF6C4AB0);    // Rich Purple - Stage Lights
const Color kSecondaryColor = Color(0xFF8D72E1);  // Soft Purple - Energy
const Color kAccentColor = Color(0xFFB9E0FF);     // Electric Blue - Microphone Glow
const Color kHighlightColor = Color(0xFFFFE79B);  // Warm Yellow - Spotlight
