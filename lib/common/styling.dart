import 'package:flutter/material.dart';
import 'package:slotted/common/colors.dart';

/// A comprehensive styling class that contains all UI styling constants
/// for the application, making it easier to maintain consistent design.
class AppStyling {
  // TYPOGRAPHY SYSTEM - Modern and hierarchical
  // Display styles for large headlines
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.3,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  // Headline styles for section headers
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
  );
  
  // Title styles for cards and components
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );
  
  // Body text styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.3,
  );
  
  // Label and button text styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );
  
  // Special styles for branding and emphasis
  static const TextStyle brandLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle brandMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.25,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
    height: 1.3,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.3,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.6,
  );

  // ANIMATION DURATIONS - Enhanced with micro-interactions
  static const Duration animationInstant = Duration(milliseconds: 100);
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);
  static const Duration animationExtended = Duration(milliseconds: 800);
  
  // Animation curves for different interactions
  static const Curve animationCurveStandard = Curves.easeInOut;
  static const Curve animationCurveAccelerate = Curves.easeIn;
  static const Curve animationCurveDecelerate = Curves.easeOut;
  static const Curve animationCurveEmphasized = Curves.easeInOutCubic;
  static const Curve animationCurveSpring = Curves.elasticOut;
  
  // BORDER RADIUSES - Refined hierarchy
  static const BorderRadius borderRadiusNone = BorderRadius.zero;
  static const BorderRadius borderRadiusXSmall = BorderRadius.all(Radius.circular(2.0));
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius borderRadiusXXLarge = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius borderRadiusCircular = BorderRadius.all(Radius.circular(999.0));
  
  // ELEVATION SYSTEM - Material Design 3 inspired
  static const double elevationLevel0 = 0.0;   // Surface
  static const double elevationLevel1 = 1.0;   // Raised
  static const double elevationLevel2 = 3.0;   // Floating
  static const double elevationLevel3 = 6.0;   // Modal
  static const double elevationLevel4 = 8.0;   // Navigation
  static const double elevationLevel5 = 12.0;  // Dialog
  
  // SHADOWS - Enhanced with multiple levels
  static const List<BoxShadow> shadowNone = [];
  
  static const List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.02),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowXLarge = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.15),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
  
  // Colored shadows for depth
  static List<BoxShadow> getColoredShadow(Color color, {double opacity = 0.3}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  // SPACING SYSTEM - Consistent 4pt grid
  static const double spacingNone = 0.0;
  static const double spacingXXSmall = 2.0;   // 0.5 units
  static const double spacingXSmall = 4.0;    // 1 unit
  static const double spacingSmall = 8.0;     // 2 units
  static const double spacingMedium = 12.0;   // 3 units
  static const double spacingLarge = 16.0;    // 4 units
  static const double spacingXLarge = 24.0;   // 6 units
  static const double spacingXXLarge = 32.0;  // 8 units
  static const double spacingXXXLarge = 48.0; // 12 units
  static const double spacingLayout = 20.0;   // Layout spacing
  
  // Component specific spacing
  static const double spacingComponent = 16.0;
  static const double spacingSection = 24.0;
  static const double spacingPage = 20.0;
  
  // BUTTON STYLES - Comprehensive button system
  static ButtonStyle getPrimaryButtonStyle({bool isLarge = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      textStyle: isLarge ? buttonLarge : buttonMedium,
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? spacingXLarge : spacingLarge,
        vertical: isLarge ? spacingMedium : spacingSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: isLarge ? borderRadiusLarge : borderRadiusMedium,
      ),
      elevation: elevationLevel2,
      shadowColor: AppColors.primary.withValues(alpha: 0.3),
    );
  }
  
  static ButtonStyle getSecondaryButtonStyle({bool isLarge = false}) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: isLarge ? buttonLarge : buttonMedium,
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? spacingXLarge : spacingLarge,
        vertical: isLarge ? spacingMedium : spacingSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: isLarge ? borderRadiusLarge : borderRadiusMedium,
      ),
      side: const BorderSide(color: AppColors.primary, width: 1.5),
    );
  }
  
  static ButtonStyle getGhostButtonStyle({bool isLarge = false}) {
    return TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: isLarge ? buttonLarge : buttonMedium,
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? spacingXLarge : spacingLarge,
        vertical: isLarge ? spacingMedium : spacingSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: isLarge ? borderRadiusLarge : borderRadiusMedium,
      ),
    );
  }
  
  // CARD STYLES - Modern card system
  static BoxDecoration getCardDecoration({
    Color? backgroundColor,
    List<BoxShadow>? customShadow,
    BorderRadius? customRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? const Color(0xFF1E1E1E),
      borderRadius: customRadius ?? borderRadiusLarge,
      boxShadow: customShadow ?? shadowSmall,
      border: border,
    );
  }
  
  static BoxDecoration getElevatedCardDecoration({
    Color? backgroundColor,
    List<BoxShadow>? customShadow,
    BorderRadius? customRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? const Color(0xFF2A2A2A),
      borderRadius: customRadius ?? borderRadiusLarge,
      boxShadow: customShadow ?? shadowMedium,
    );
  }
  
  // INPUT FIELD STYLES
  static InputDecoration getInputDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isDense = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: isDense,
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      hintStyle: bodyMedium.copyWith(color: AppColors.textHint),
      labelStyle: labelMedium.copyWith(color: AppColors.textSecondary),
      border: const OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacingMedium,
        vertical: isDense ? spacingSmall : spacingMedium,
      ),
    );
  }
  
  // DIVIDER STYLES
  static Widget getDivider({
    double thickness = 1.0,
    Color? color,
    double indent = 0.0,
    double endIndent = 0.0,
  }) {
    return Divider(
      thickness: thickness,
      color: color ?? AppColors.divider,
      indent: indent,
      endIndent: endIndent,
    );
  }
  
  // CHIP STYLES
  static BoxDecoration getChipDecoration({
    Color? backgroundColor,
    Color? borderColor,
    bool isSelected = false,
  }) {
    return BoxDecoration(
      color: isSelected 
          ? (backgroundColor ?? AppColors.primary)
          : const Color(0xFF1A1A1A),
      borderRadius: borderRadiusCircular,
      border: borderColor != null 
          ? Border.all(color: borderColor, width: 1)
          : null,
    );
  }
  
  // UTILITY METHODS
  static EdgeInsets getPadding({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? right,
    double? bottom,
    double? left,
  }) {
    if (all != null) return EdgeInsets.all(all);
    
    return EdgeInsets.only(
      top: top ?? vertical ?? 0,
      right: right ?? horizontal ?? 0,
      bottom: bottom ?? vertical ?? 0,
      left: left ?? horizontal ?? 0,
    );
  }
  
  static SizedBox getSpacing({
    double? width,
    double? height,
  }) {
    return SizedBox(width: width, height: height);
  }
  
  // Responsive breakpoints
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
}

// Legacy constants for backward compatibility
// These will be gradually phased out in favor of AppStyling

// Animation
@Deprecated('Use AppStyling.animationShort instead')
const Duration kAnimationDurationShort = AppStyling.animationShort;

@Deprecated('Use AppStyling.animationMedium instead')
const Duration kAnimationDurationMedium = AppStyling.animationMedium;

@Deprecated('Use AppStyling.animationLong instead')
const Duration kAnimationDurationLong = AppStyling.animationLong;

// Border Radius
@Deprecated('Use AppStyling.borderRadiusSmall instead')
const BorderRadius kBorderRadiusSmall = AppStyling.borderRadiusSmall;

@Deprecated('Use AppStyling.borderRadiusMedium instead')
const BorderRadius kBorderRadiusMedium = AppStyling.borderRadiusMedium;

@Deprecated('Use AppStyling.borderRadiusLarge instead')
const BorderRadius kBorderRadiusLarge = AppStyling.borderRadiusLarge;

@Deprecated('Use AppStyling.borderRadiusXLarge instead')
const BorderRadius kBorderRadiusXLarge = AppStyling.borderRadiusXLarge;

// Shadows
@Deprecated('Use AppStyling.shadowSmall instead')
const List<BoxShadow> kShadowSmall = AppStyling.shadowSmall;

@Deprecated('Use AppStyling.shadowMedium instead')
const List<BoxShadow> kShadowMedium = AppStyling.shadowMedium;

@Deprecated('Use AppStyling.shadowLarge instead')
const List<BoxShadow> kShadowLarge = AppStyling.shadowLarge;

// Spacing
@Deprecated('Use AppStyling.spacingXXSmall instead')
const double kSpacingXXSmall = AppStyling.spacingXXSmall;

@Deprecated('Use AppStyling.spacingXSmall instead')
const double kSpacingXSmall = AppStyling.spacingXSmall;

@Deprecated('Use AppStyling.spacingSmall instead')
const double kSpacingSmall = AppStyling.spacingSmall;

@Deprecated('Use AppStyling.spacingMedium instead')
const double kSpacingMedium = AppStyling.spacingMedium;

@Deprecated('Use AppStyling.spacingLarge instead')
const double kSpacingLarge = AppStyling.spacingLarge;

@Deprecated('Use AppStyling.spacingXLarge instead')
const double kSpacingXLarge = AppStyling.spacingXLarge;

@Deprecated('Use AppStyling.spacingXXLarge instead')
const double kSpacingXXLarge = AppStyling.spacingXXLarge;

@Deprecated('Use AppStyling.spacingLayout instead')
const double kSpacingLayout = AppStyling.spacingLayout; 