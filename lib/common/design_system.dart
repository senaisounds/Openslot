import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// OpenSlot Design System
/// Centralized design tokens for consistent UI across the app
class DesignSystem {
  
  // SPACING TOKENS
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // BORDER RADIUS TOKENS
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 50.0;
  
  // COLOR PALETTE - BLACK & ORANGE FOUNDATION
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color primaryOrangeDark = Color(0xFFE67E22);
  static const Color backgroundDark = CupertinoColors.black;
  static const Color cardDark = Color(0xFF1C1C1E);
  static const Color borderLight = Color(0xFF38383A);
  
  // COMPLEMENTARY ACCENTS for accessibility & visual hierarchy
  static const Color accentBlue = Color(0xFF4A90E2);    // Cool complement to orange
  static const Color accentTeal = Color(0xFF2DD4BF);    // Modern tech accent
  static const Color accentPurple = Color(0xFF8B5CF6);  // Creative accent
  static const Color accentGreen = Color(0xFF10B981);   // Success states
  static const Color accentRed = Color(0xFFEF4444);     // Error/live states
  static const Color accentYellow = Color(0xFFFBBF24);  // Warning/highlight
  
  // NEUTRAL GRAYS for better text hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFD1D5DB);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color surfaceLight = Color(0xFF374151);
  static const Color surfaceDark = Color(0xFF111827);
  
  // GRADIENTS
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [primaryOrange, Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // SHADOWS
  static List<BoxShadow> softShadow(Color color) => [
    BoxShadow(
      color: color.withAlpha(76),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withAlpha(102),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
  
  // TYPOGRAPHY
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
}

/// Pre-built Component Styles
class ComponentStyles {
  
  // PRIMARY BUTTON
  static BoxDecoration primaryButton = BoxDecoration(
    gradient: DesignSystem.primaryGradient,
    borderRadius: BorderRadius.circular(DesignSystem.radiusL),
    boxShadow: DesignSystem.softShadow(DesignSystem.primaryOrange),
  );
  
  // SECONDARY BUTTON
  static BoxDecoration secondaryButton = BoxDecoration(
    color: DesignSystem.cardDark,
    borderRadius: BorderRadius.circular(DesignSystem.radiusL),
    border: Border.all(
      color: DesignSystem.borderLight,
      width: 1,
    ),
  );
  
  // CARD STYLE
  static BoxDecoration card = BoxDecoration(
    color: DesignSystem.cardDark,
    borderRadius: BorderRadius.circular(DesignSystem.radiusL),
    border: Border.all(
      color: DesignSystem.borderLight.withValues(alpha: 0.3),
      width: 0.5,
    ),
  );
  
  // ELEVATED CARD
  static BoxDecoration elevatedCard = BoxDecoration(
    color: DesignSystem.cardDark,
    borderRadius: BorderRadius.circular(DesignSystem.radiusL),
    boxShadow: DesignSystem.softShadow(Colors.black),
  );
  
  // TAB BAR
  static BoxDecoration tabBar = BoxDecoration(
    color: DesignSystem.backgroundDark,
    borderRadius: BorderRadius.circular(DesignSystem.radiusL),
    boxShadow: DesignSystem.glowShadow(DesignSystem.primaryOrange),
  );
  
  // SECTION HEADER
  static BoxDecoration sectionHeader = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        DesignSystem.primaryOrange.withAlpha(25),
        DesignSystem.primaryOrange.withAlpha(13),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    borderRadius: BorderRadius.circular(DesignSystem.radiusS),
    border: const Border(
      left: BorderSide(
        color: DesignSystem.primaryOrange,
        width: 3,
      ),
    ),
  );
}

/// Layout Helpers
class LayoutHelpers {
  
  // STANDARD PAGE PADDING
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 24, 16, 0);
  
  // SECTION SPACING
  static const Widget sectionSpacing = SizedBox(height: DesignSystem.spacingL);
  static const Widget smallSpacing = SizedBox(height: DesignSystem.spacingS);
  static const Widget mediumSpacing = SizedBox(height: DesignSystem.spacingM);
  static const Widget largeSpacing = SizedBox(height: DesignSystem.spacingXL);
  
  // HORIZONTAL SPACING
  static const Widget horizontalSpacingS = SizedBox(width: DesignSystem.spacingS);
  static const Widget horizontalSpacingM = SizedBox(width: DesignSystem.spacingM);
  
  // CONTENT PADDING
  static const EdgeInsets cardPadding = EdgeInsets.all(DesignSystem.spacingM);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: DesignSystem.spacingM,
    vertical: DesignSystem.spacingS,
  );
}

/// Animation Constants
class AnimationConstants {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve bounce = Curves.elasticOut;
} 