import 'package:flutter/material.dart';
import 'package:slotted/common/colors.dart';

// Common constants used throughout the app

// URLs
const String placeholderImage = 'https://upload.wikimedia.org/wikipedia/commons/c/cd/Portrait_Placeholder_Square.png';

// Animation Constants
const Duration kAnimationDurationShort = Duration(milliseconds: 200);
const Duration kAnimationDurationMedium = Duration(milliseconds: 500);
const Duration kAnimationDurationLong = Duration(milliseconds: 800);

const Curve kAnimationCurveStandard = Curves.easeInOut;
const Curve kAnimationCurveEnergetic = Curves.easeInOutCubic;
const Curve kAnimationCurveBouncy = Curves.elasticOut;

// Theme Colors - Using AppColors for consistency
const Color kPrimary = AppColors.primary;          // Vibrant Orange - Stage Lights
const Color kPrimaryColor = AppColors.primary;     // Vibrant Orange - Stage Lights
const Color kSecondary = AppColors.secondary;      // Soft Orange - Energy
const Color kSecondaryColor = AppColors.secondary; // Soft Orange - Energy
const Color kAccent = AppColors.accent;            // Electric Orange - Microphone Glow
const Color kAccentColor = AppColors.accent;       // Electric Orange - Microphone Glow
const Color kHighlight = AppColors.highlight;      // Warm Yellow - Spotlight
const Color kHighlightColor = AppColors.highlight; // Warm Yellow - Spotlight
const Color kBackgroundDark = AppColors.backgroundDark;   // Richer black
const Color kBackgroundLight = AppColors.backgroundLight; // Softer light

// Shadow System
const List<BoxShadow> kShadowSmall = [
  BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 6,
    offset: Offset(0, 3),
    spreadRadius: 0,
  ),
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 2,
    offset: Offset(0, 1),
    spreadRadius: 0,
  ),
];

const List<BoxShadow> kShadowMedium = [
  BoxShadow(
    color: Color(0x24000000),
    blurRadius: 12,
    offset: Offset(0, 6),
    spreadRadius: -2,
  ),
  BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
    spreadRadius: 0,
  ),
];

const List<BoxShadow> kShadowLarge = [
  BoxShadow(
    color: Color(0x29000000),
    blurRadius: 20,
    offset: Offset(0, 10),
    spreadRadius: -4,
  ),
  BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 6,
    offset: Offset(0, 4),
    spreadRadius: 0,
  ),
];

const List<BoxShadow> kShadowFloating = [
  BoxShadow(
    color: Color(0x33000000),
    blurRadius: 24,
    offset: Offset(0, 12),
    spreadRadius: -6,
  ),
  BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 8,
    offset: Offset(0, 4),
    spreadRadius: 0,
  ),
];

// Modern Gradients - Using AppColors for consistency
const List<Color> kPrimaryGradient = [AppColors.primary, AppColors.primaryDark];
const List<Color> kSecondaryGradient = [AppColors.secondary, AppColors.secondaryDark];
const List<Color> kAccentGradient = [
  AppColors.highlight,  // Sunny Yellow
  AppColors.accent,     // Light Yellow
];

LinearGradient get kGradientPrimary => AppColors.getPrimaryGradient();

LinearGradient get kGradientSecondary => AppColors.getPrimaryGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0],
);

// Glass Morphism
const BoxDecoration kGlassLight = BoxDecoration(
  color: Color(0x1AFFFFFF),
  borderRadius: BorderRadius.all(Radius.circular(24)),
  border: Border.fromBorderSide(
    BorderSide(color: Color(0x2AFFFFFF), width: 2.0),
  ),
);

const BoxDecoration kGlassDark = BoxDecoration(
  color: Color(0x2A000000),
  borderRadius: BorderRadius.all(Radius.circular(24)),
  border: Border.fromBorderSide(
    BorderSide(color: Color(0x2AFFFFFF), width: 2.0),
  ),
);

// Border Radius
const double kBorderRadiusXSmall = 8.0;
const double kBorderRadiusSmall = 8.0;
const double kBorderRadiusMedium = 12.0;
const double kBorderRadiusLarge = 16.0;
const double kBorderRadiusXLarge = 24.0;
const double kBorderRadiusRound = 999.0;  // For fully rounded elements

// Base Spacing Unit
const double kSpacingBase = 4.0;  // Base unit for consistent spacing

// Spacing Scale
const double kSpacingXXSmall = kSpacingBase * 1;    // 4.0
const double kSpacingXSmall = kSpacingBase * 2;     // 8.0
const double kSpacingSmall = 8.0;
const double kSpacingMedium = 16.0;
const double kSpacingLarge = 24.0;
const double kSpacingXLarge = 32.0;
const double kSpacingXXLarge = kSpacingBase * 12;   // 48.0

// Layout Spacing
const double kSpacingSection = kSpacingBase * 10;   // 40.0
const double kSpacingLayout = kSpacingBase * 16;    // 64.0

// Container Padding
const EdgeInsets kPaddingXSmall = EdgeInsets.all(kSpacingXSmall);
const EdgeInsets kPaddingSmall = EdgeInsets.all(kSpacingSmall);
const EdgeInsets kPaddingMedium = EdgeInsets.all(kSpacingMedium);
const EdgeInsets kPaddingLarge = EdgeInsets.all(kSpacingLarge);

// Asymmetric Padding
const EdgeInsets kPaddingHorizontal = EdgeInsets.symmetric(
  horizontal: kSpacingMedium,
  vertical: kSpacingSmall,
);

const EdgeInsets kPaddingVertical = EdgeInsets.symmetric(
  horizontal: kSpacingSmall,
  vertical: kSpacingMedium,
);

// Content Padding
const EdgeInsets kPaddingContent = EdgeInsets.symmetric(
  horizontal: kSpacingLarge,
  vertical: kSpacingMedium,
);

// Card Padding
const EdgeInsets kPaddingCard = EdgeInsets.all(kSpacingLarge);

// Button Padding
const EdgeInsets kPaddingButton = EdgeInsets.symmetric(
  horizontal: kSpacingLarge,
  vertical: kSpacingMedium,
);

// Form Field Padding
const EdgeInsets kPaddingField = EdgeInsets.symmetric(
  horizontal: kSpacingMedium,
  vertical: kSpacingSmall,
);

// Animation Durations
const Duration kAnimationDurationXShort = Duration(milliseconds: 200);  // Quicker feedback
const Duration kAnimationDurationXLong = Duration(milliseconds: 1000);  // Special moments

// Text Styles
const TextStyle kHeadlineLarge = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.5,
);

const TextStyle kHeadlineMedium = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.3,
);

const TextStyle kBodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.1,
);

const TextStyle kBodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.1,
);

// Enhanced Card Decoration - Using AppColors for consistency
BoxDecoration kCardDecoration = BoxDecoration(
  color: kBackgroundLight,
  borderRadius: BorderRadius.circular(kBorderRadiusXLarge),
  boxShadow: [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.1), // Primary color with opacity
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.secondary.withValues(alpha: 0.1), // Secondary color with opacity
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ],
  border: Border.all(
    color: AppColors.primary.withValues(alpha: 0.15), // Primary color with opacity
    width: 2,
  ),
);

// Event Category Colors - Using AppColors for consistency
const Map<String, Color> eventCategoryColors = AppColors.eventCategory;

// Event Category Gradients - Using AppColors for consistency
const Map<String, List<Color>> eventCategoryGradients = AppColors.eventCategoryGradient;

// Button Decorations - Using AppColors for consistency
BoxDecoration kButtonPrimaryDecoration = BoxDecoration(
  gradient: kGradientPrimary,
  borderRadius: BorderRadius.circular(kBorderRadiusXLarge),
  boxShadow: [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.accent.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -5,
    ),
  ],
);

BoxDecoration kButtonSecondaryDecoration = BoxDecoration(
  gradient: kGradientSecondary,
  borderRadius: BorderRadius.circular(kBorderRadiusXLarge),
  boxShadow: [
    BoxShadow(
      color: AppColors.secondary.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.highlight.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -5,
    ),
  ],
);

// Input Field Decoration - Using AppColors for consistency
BoxDecoration kInputFieldDecoration = BoxDecoration(
  color: kBackgroundLight,
  borderRadius: BorderRadius.circular(kBorderRadiusMedium),
  boxShadow: kShadowSmall,
  border: Border.all(
    color: AppColors.primary.withValues(alpha: 0.1),
    width: 1.5,
  ),
);

// Depth Effects
const List<BoxShadow> kDepthTop = [
  BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 6,
    offset: Offset(0, -3),
  ),
];

const List<BoxShadow> kDepthBottom = [
  BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 6,
    offset: Offset(0, 3),
  ),
];

// Additional spacing and border radius constants

// Spacing constants
const double kSpacingSmallLegacy = 8.0;
const double kSpacingMediumLegacy = 16.0;
const double kSpacingLargeLegacy = 24.0;
const double kSpacingXLargeLegacy = 32.0;

// Border radius constants
const double kBorderRadiusSmallLegacy = 8.0;
const double kBorderRadiusMediumLegacy = 12.0;
const double kBorderRadiusLargeLegacy = 16.0;
const double kBorderRadiusXLargeLegacy = 24.0; 