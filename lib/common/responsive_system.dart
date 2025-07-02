import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

/// Comprehensive Responsive System for OpenSlot
/// Ensures proper layout and spacing across all device sizes
class ResponsiveSystem {
  
  // DEVICE BREAKPOINTS
  static const double phoneBreakpoint = 480;     // iPhone SE, small Android phones
  static const double phoneLargeBreakpoint = 600; // iPhone Pro, large Android phones  
  static const double tabletBreakpoint = 768;     // iPad Mini, small tablets
  static const double tabletLargeBreakpoint = 1024; // iPad, large tablets
  static const double desktopBreakpoint = 1200;   // Desktop screens
  static const double desktopLargeBreakpoint = 1440; // Large desktop screens
  
  // Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      
      if (screenWidth < phoneBreakpoint) return DeviceType.phoneSmall;
      if (screenWidth < phoneLargeBreakpoint) return DeviceType.phone;
      if (screenWidth < tabletBreakpoint) return DeviceType.phoneLarge;
      if (screenWidth < tabletLargeBreakpoint) return DeviceType.tablet;
      if (screenWidth < desktopBreakpoint) return DeviceType.tabletLarge;
      if (screenWidth < desktopLargeBreakpoint) return DeviceType.desktop;
      return DeviceType.desktopLarge;
    } catch (e) {
      // Fallback to phone if context is invalid
      return DeviceType.phone;
    }
  }
  
  // Get responsive spacing based on device type
  static ResponsiveSpacing getSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.phoneSmall:
        return const ResponsiveSpacing(
          xs: 2, s: 4, m: 8, l: 12, xl: 16, xxl: 20,
          horizontal: 8, vertical: 4,
        );
      case DeviceType.phone:
        return const ResponsiveSpacing(
          xs: 4, s: 8, m: 12, l: 16, xl: 20, xxl: 24,
          horizontal: 12, vertical: 8,
        );
      case DeviceType.phoneLarge:
        return const ResponsiveSpacing(
          xs: 4, s: 8, m: 16, l: 20, xl: 24, xxl: 32,
          horizontal: 16, vertical: 12,
        );
      case DeviceType.tablet:
        return const ResponsiveSpacing(
          xs: 6, s: 12, m: 20, l: 28, xl: 36, xxl: 48,
          horizontal: 24, vertical: 16,
        );
      case DeviceType.tabletLarge:
        return const ResponsiveSpacing(
          xs: 8, s: 16, m: 24, l: 32, xl: 48, xxl: 64,
          horizontal: 32, vertical: 20,
        );
      case DeviceType.desktop:
      case DeviceType.desktopLarge:
        return const ResponsiveSpacing(
          xs: 8, s: 16, m: 32, l: 48, xl: 64, xxl: 80,
          horizontal: 48, vertical: 24,
        );
    }
  }
  
  // Get responsive font sizes
  static ResponsiveFonts getFonts(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.phoneSmall:
        return const ResponsiveFonts(
          h1: 20, h2: 18, h3: 16, h4: 14, h5: 12, h6: 10,
          body1: 14, body2: 12, caption: 10, overline: 8,
        );
      case DeviceType.phone:
        return const ResponsiveFonts(
          h1: 24, h2: 20, h3: 18, h4: 16, h5: 14, h6: 12,
          body1: 16, body2: 14, caption: 12, overline: 10,
        );
      case DeviceType.phoneLarge:
        return const ResponsiveFonts(
          h1: 28, h2: 24, h3: 20, h4: 18, h5: 16, h6: 14,
          body1: 16, body2: 14, caption: 12, overline: 10,
        );
      case DeviceType.tablet:
        return const ResponsiveFonts(
          h1: 32, h2: 28, h3: 24, h4: 20, h5: 18, h6: 16,
          body1: 18, body2: 16, caption: 14, overline: 12,
        );
      case DeviceType.tabletLarge:
        return const ResponsiveFonts(
          h1: 36, h2: 32, h3: 28, h4: 24, h5: 20, h6: 18,
          body1: 20, body2: 18, caption: 16, overline: 14,
        );
      case DeviceType.desktop:
        return const ResponsiveFonts(
          h1: 40, h2: 36, h3: 32, h4: 28, h5: 24, h6: 20,
          body1: 18, body2: 16, caption: 14, overline: 12,
        );
      case DeviceType.desktopLarge:
        return const ResponsiveFonts(
          h1: 48, h2: 42, h3: 36, h4: 32, h5: 28, h6: 24,
          body1: 20, body2: 18, caption: 16, overline: 14,
        );
    }
  }
  
  // Get responsive layout dimensions
  static ResponsiveLayout getLayout(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenSize = MediaQuery.of(context).size;
    
    switch (deviceType) {
      case DeviceType.phoneSmall:
        return ResponsiveLayout(
          maxContentWidth: screenSize.width,
          cardHeight: 280,
          buttonHeight: 44,
          iconSize: 20,
          avatarSize: 32,
          borderRadius: 8,
        );
      case DeviceType.phone:
        return ResponsiveLayout(
          maxContentWidth: screenSize.width,
          cardHeight: 320,
          buttonHeight: 48,
          iconSize: 24,
          avatarSize: 40,
          borderRadius: 12,
        );
      case DeviceType.phoneLarge:
        return ResponsiveLayout(
          maxContentWidth: screenSize.width,
          cardHeight: 350,
          buttonHeight: 52,
          iconSize: 28,
          avatarSize: 44,
          borderRadius: 12,
        );
      case DeviceType.tablet:
        return const ResponsiveLayout(
          maxContentWidth: 700,
          cardHeight: 400,
          buttonHeight: 56,
          iconSize: 32,
          avatarSize: 52,
          borderRadius: 16,
        );
      case DeviceType.tabletLarge:
        return const ResponsiveLayout(
          maxContentWidth: 900,
          cardHeight: 450,
          buttonHeight: 60,
          iconSize: 36,
          avatarSize: 60,
          borderRadius: 20,
        );
      case DeviceType.desktop:
        return const ResponsiveLayout(
          maxContentWidth: 1200,
          cardHeight: 420,
          buttonHeight: 52,
          iconSize: 28,
          avatarSize: 48,
          borderRadius: 16,
        );
      case DeviceType.desktopLarge:
        return const ResponsiveLayout(
          maxContentWidth: 1400,
          cardHeight: 480,
          buttonHeight: 56,
          iconSize: 32,
          avatarSize: 56,
          borderRadius: 20,
        );
    }
  }
  
  // Safe area helper that considers device type
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    try {
      final mediaQuery = MediaQuery.of(context);
      final deviceType = getDeviceType(context);
      final spacing = getSpacing(context);
      
      // Base safe area from MediaQuery
      EdgeInsets safePadding = mediaQuery.padding;
      
      // Ensure padding values are never negative
      safePadding = EdgeInsets.only(
        top: math.max(safePadding.top, 0),
        bottom: math.max(safePadding.bottom, 0),
        left: math.max(safePadding.left, 0),
        right: math.max(safePadding.right, 0),
      );
      
      // Adjust for device-specific needs
      switch (deviceType) {
        case DeviceType.phoneSmall:
          // Small phones need extra care for notches and home indicators
          safePadding = safePadding.copyWith(
            top: safePadding.top < 20 ? 20 : safePadding.top,
            bottom: safePadding.bottom < 10 ? 10 : safePadding.bottom,
          );
          break;
        case DeviceType.phone:
        case DeviceType.phoneLarge:
          // Standard phones with modern notches
          safePadding = safePadding.copyWith(
            top: safePadding.top < 44 ? 44 : safePadding.top,
            bottom: safePadding.bottom < 20 ? 20 : safePadding.bottom,
          );
          break;
        case DeviceType.tablet:
        case DeviceType.tabletLarge:
          // Tablets usually have minimal safe areas
          safePadding = safePadding.copyWith(
            top: safePadding.top < 20 ? 20 : safePadding.top,
            bottom: safePadding.bottom < 20 ? 20 : safePadding.bottom,
          );
          break;
        case DeviceType.desktop:
        case DeviceType.desktopLarge:
          // Desktop/web - ensure minimum padding
          safePadding = EdgeInsets.all(spacing.m);
          break;
      }
      
      return safePadding;
    } catch (e) {
      // Fallback to phone if context is invalid
      return const EdgeInsets.all(0);
    }
  }
  
  // Responsive container that constrains content width appropriately
  static Widget constrainedContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    Color? backgroundColor,
  }) {
    final layout = getLayout(context);
    final spacing = getSpacing(context);
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: layout.maxContentWidth,
        ),
        padding: padding ?? EdgeInsets.symmetric(horizontal: spacing.horizontal),
        color: backgroundColor,
        child: child,
      ),
    );
  }
  
  // Responsive grid layout
  static int getGridColumns(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.phoneSmall:
      case DeviceType.phone:
        return 1; // Single column for phones
      case DeviceType.phoneLarge:
        return 1; // Still single column for large phones
      case DeviceType.tablet:
        return 2; // Two columns for tablets
      case DeviceType.tabletLarge:
        return 2; // Two columns for large tablets
      case DeviceType.desktop:
        return 3; // Three columns for desktop
      case DeviceType.desktopLarge:
        return 4; // Four columns for large desktop
    }
  }
  
  // Check if device has sufficient space for certain UI elements
  static bool hasSpaceFor(BuildContext context, UIElement element) {
    final deviceType = getDeviceType(context);
    
    switch (element) {
      case UIElement.sideNavigation:
        return deviceType.index >= DeviceType.tablet.index;
      case UIElement.floatingActionButton:
        return deviceType.index >= DeviceType.phone.index;
      case UIElement.tabBar:
        return true; // All devices support tab bars
      case UIElement.bottomNavigation:
        return true; // All devices support bottom navigation
      case UIElement.searchBar:
        return true; // All devices support search
      case UIElement.filters:
        return deviceType.index >= DeviceType.phone.index;
    }
  }
  
  // Platform-specific adjustments
  static bool isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS;
  }
  
  static bool isAndroid(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.android;
  }
  
  static bool isWeb() {
    return kIsWeb;
  }
}

// Device type enumeration
enum DeviceType {
  phoneSmall,    // < 480px
  phone,         // 480-600px  
  phoneLarge,    // 600-768px
  tablet,        // 768-1024px
  tabletLarge,   // 1024-1200px
  desktop,       // 1200-1440px
  desktopLarge,  // > 1440px
}

// UI element enumeration for space checking
enum UIElement {
  sideNavigation,
  floatingActionButton,
  tabBar,
  bottomNavigation,
  searchBar,
  filters,
}

// Responsive spacing values
class ResponsiveSpacing {
  final double xs, s, m, l, xl, xxl;
  final double horizontal, vertical;
  
  const ResponsiveSpacing({
    required this.xs,
    required this.s,
    required this.m,
    required this.l,
    required this.xl,
    required this.xxl,
    required this.horizontal,
    required this.vertical,
  });
}

// Responsive font sizes
class ResponsiveFonts {
  final double h1, h2, h3, h4, h5, h6;
  final double body1, body2, caption, overline;
  
  const ResponsiveFonts({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.h5,
    required this.h6,
    required this.body1,
    required this.body2,
    required this.caption,
    required this.overline,
  });
}

// Responsive layout dimensions
class ResponsiveLayout {
  final double maxContentWidth;
  final double cardHeight;
  final double buttonHeight;
  final double iconSize;
  final double avatarSize;
  final double borderRadius;
  
  const ResponsiveLayout({
    required this.maxContentWidth,
    required this.cardHeight,
    required this.buttonHeight,
    required this.iconSize,
    required this.avatarSize,
    required this.borderRadius,
  });
}

// Helper extension for responsive context
extension ResponsiveContext on BuildContext {
  DeviceType get deviceType => ResponsiveSystem.getDeviceType(this);
  ResponsiveSpacing get spacing => ResponsiveSystem.getSpacing(this);
  ResponsiveFonts get fonts => ResponsiveSystem.getFonts(this);
  ResponsiveLayout get layout => ResponsiveSystem.getLayout(this);
  EdgeInsets get safeAreaPadding => ResponsiveSystem.getSafeAreaPadding(this);
  
  bool get isSmallScreen => deviceType.index <= DeviceType.phone.index;
  bool get isMediumScreen => deviceType == DeviceType.phoneLarge || deviceType == DeviceType.tablet;
  bool get isLargeScreen => deviceType.index >= DeviceType.tabletLarge.index;
  
  bool hasSpaceFor(UIElement element) => ResponsiveSystem.hasSpaceFor(this, element);
  
  Widget constrainedContainer({
    required Widget child,
    EdgeInsets? padding,
    Color? backgroundColor,
  }) => ResponsiveSystem.constrainedContainer(
    context: this,
    child: child,
    padding: padding,
    backgroundColor: backgroundColor,
  );
} 
