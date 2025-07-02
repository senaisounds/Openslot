import 'package:flutter/material.dart';
import 'package:slotted/common/responsive_system.dart';

/// Device Compatibility Checker
/// Helps ensure the app functions properly across all target devices
class DeviceCompatibilityChecker {
  
  /// Minimum supported screen dimensions
  static const double minScreenWidth = 320.0;   // iPhone SE (1st gen)
  static const double minScreenHeight = 568.0;  // iPhone SE (1st gen)
  
  /// Maximum supported screen dimensions  
  static const double maxScreenWidth = 2560.0;  // Large desktop displays
  static const double maxScreenHeight = 1600.0; // Large desktop displays
  
  /// Target device specifications to test against
  static const Map<String, DeviceSpec> targetDevices = {
    // iPhone Models
    'iPhone SE (1st gen)': DeviceSpec(320, 568, 2.0, DeviceCategory.phone),
    'iPhone SE (2nd/3rd gen)': DeviceSpec(375, 667, 2.0, DeviceCategory.phone),
    'iPhone 12 Mini': DeviceSpec(375, 812, 3.0, DeviceCategory.phone),
    'iPhone 12/13/14': DeviceSpec(390, 844, 3.0, DeviceCategory.phone),
    'iPhone 12/13/14 Pro': DeviceSpec(393, 852, 3.0, DeviceCategory.phone),
    'iPhone 14 Plus': DeviceSpec(428, 926, 3.0, DeviceCategory.phoneLarge),
    'iPhone 14 Pro Max': DeviceSpec(430, 932, 3.0, DeviceCategory.phoneLarge),
    
    // Android Models (common sizes)
    'Small Android': DeviceSpec(360, 640, 2.0, DeviceCategory.phone),
    'Medium Android': DeviceSpec(411, 731, 2.6, DeviceCategory.phone),
    'Large Android': DeviceSpec(428, 926, 3.0, DeviceCategory.phoneLarge),
    'Android Tablet': DeviceSpec(768, 1024, 2.0, DeviceCategory.tablet),
    
    // iPad Models
    'iPad Mini': DeviceSpec(744, 1133, 2.0, DeviceCategory.tablet),
    'iPad (9th gen)': DeviceSpec(810, 1080, 2.0, DeviceCategory.tablet),
    'iPad Air': DeviceSpec(820, 1180, 2.0, DeviceCategory.tablet),
    'iPad Pro 11"': DeviceSpec(834, 1194, 2.0, DeviceCategory.tabletLarge),
    'iPad Pro 12.9"': DeviceSpec(1024, 1366, 2.0, DeviceCategory.tabletLarge),
    
    // Desktop/Web
    'Small Desktop': DeviceSpec(1280, 720, 1.0, DeviceCategory.desktop),
    'Medium Desktop': DeviceSpec(1920, 1080, 1.0, DeviceCategory.desktop),
    'Large Desktop': DeviceSpec(2560, 1440, 1.0, DeviceCategory.desktopLarge),
  };
  
  /// Check if the current device is compatible
  static DeviceCompatibilityResult checkCompatibility(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final deviceType = ResponsiveSystem.getDeviceType(context);
    
    final issues = <CompatibilityIssue>[];
    final warnings = <String>[];
    final recommendations = <String>[];
    
    // Check minimum dimensions
    if (screenSize.width < minScreenWidth) {
      issues.add(CompatibilityIssue(
        type: IssueType.critical,
        message: 'Screen width (${screenSize.width.toInt()}px) is below minimum supported width (${minScreenWidth.toInt()}px)',
        recommendation: 'Some UI elements may be cut off or overlapping',
      ));
    }
    
    if (screenSize.height < minScreenHeight) {
      issues.add(CompatibilityIssue(
        type: IssueType.critical,
        message: 'Screen height (${screenSize.height.toInt()}px) is below minimum supported height (${minScreenHeight.toInt()}px)',
        recommendation: 'Content may not fit properly in the viewport',
      ));
    }
    
    // Check for very high pixel ratios
    if (pixelRatio > 4.0) {
      warnings.add('High pixel ratio (${pixelRatio.toStringAsFixed(1)}x) detected - monitor for performance issues');
    }
    
    // Check for unusually wide screens
    final aspectRatio = screenSize.width / screenSize.height;
    if (aspectRatio > 2.5) {
      warnings.add('Unusually wide aspect ratio (${aspectRatio.toStringAsFixed(2)}:1) - verify horizontal layout');
    }
    if (aspectRatio < 0.4) {
      warnings.add('Unusually narrow aspect ratio (${aspectRatio.toStringAsFixed(2)}:1) - verify vertical layout');
    }
    
    // Device-specific recommendations
    switch (deviceType) {
      case DeviceType.phoneSmall:
        recommendations.add('Consider using compact UI elements and reduced margins');
        recommendations.add('Test scrolling behavior with reduced viewport');
        break;
      case DeviceType.phone:
        recommendations.add('Standard phone layout - test with notches and home indicators');
        break;
      case DeviceType.phoneLarge:
        recommendations.add('Large phone - consider optimizing for one-handed use');
        break;
      case DeviceType.tablet:
        recommendations.add('Tablet layout - ensure content doesn\'t feel too spread out');
        break;
      case DeviceType.tabletLarge:
        recommendations.add('Large tablet - consider side navigation or multi-column layouts');
        break;
      case DeviceType.desktop:
      case DeviceType.desktopLarge:
        recommendations.add('Desktop layout - ensure content has maximum width constraints');
        recommendations.add('Test hover states and pointer interactions');
        break;
    }
    
    return DeviceCompatibilityResult(
      isCompatible: issues.where((issue) => issue.type == IssueType.critical).isEmpty,
      deviceType: deviceType,
      screenSize: screenSize,
      pixelRatio: pixelRatio,
      issues: issues,
      warnings: warnings,
      recommendations: recommendations,
    );
  }
  
  /// Get the closest matching target device
  static String? getClosestTargetDevice(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    double minDistance = double.infinity;
    String? closestDevice;
    
    for (final entry in targetDevices.entries) {
      final device = entry.value;
      final distance = ((screenSize.width - device.width).abs() + 
                       (screenSize.height - device.height).abs());
      
      if (distance < minDistance) {
        minDistance = distance;
        closestDevice = entry.key;
      }
    }
    
    return closestDevice;
  }
  
  /// Test UI elements for the current device
  static List<UITestResult> testUIElements(BuildContext context) {
    final results = <UITestResult>[];
    final layout = ResponsiveSystem.getLayout(context);
    final spacing = ResponsiveSystem.getSpacing(context);
    
    // Test button sizes
    results.add(UITestResult(
      element: 'Buttons',
      status: layout.buttonHeight >= 44 ? TestStatus.pass : TestStatus.fail,
      message: layout.buttonHeight >= 44 
          ? 'Button height (${layout.buttonHeight}px) meets minimum touch target'
          : 'Button height (${layout.buttonHeight}px) may be too small for touch',
    ));
    
    // Test spacing
    results.add(UITestResult(
      element: 'Spacing',
      status: spacing.m >= 8 ? TestStatus.pass : TestStatus.warning,
      message: spacing.m >= 8 
          ? 'Spacing (${spacing.m}px) provides adequate touch targets'
          : 'Spacing (${spacing.m}px) might be too tight',
    ));
    
    // Test text sizes
    final fonts = ResponsiveSystem.getFonts(context);
    results.add(UITestResult(
      element: 'Typography',
      status: fonts.body1 >= 14 ? TestStatus.pass : TestStatus.fail,
      message: fonts.body1 >= 14 
          ? 'Body text (${fonts.body1}px) is readable'
          : 'Body text (${fonts.body1}px) may be too small',
    ));
    
    return results;
  }
  
  /// Generate a compatibility report
  static CompatibilityReport generateReport(BuildContext context) {
    final compatibility = checkCompatibility(context);
    final closestDevice = getClosestTargetDevice(context);
    final uiTests = testUIElements(context);
    
    return CompatibilityReport(
      compatibility: compatibility,
      closestTargetDevice: closestDevice,
      uiTests: uiTests,
      timestamp: DateTime.now(),
    );
  }
  
  /// Simple crash prevention check for responsive system
  static bool isContextSafe(BuildContext? context) {
    if (context == null) return false;
    
    try {
      // Test if we can safely access MediaQuery
      MediaQuery.of(context);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Data classes for compatibility checking

class DeviceSpec {
  final double width;
  final double height;
  final double pixelRatio;
  final DeviceCategory category;
  
  const DeviceSpec(this.width, this.height, this.pixelRatio, this.category);
}

enum DeviceCategory {
  phone,
  phoneLarge,
  tablet,
  tabletLarge,
  desktop,
  desktopLarge,
}

class DeviceCompatibilityResult {
  final bool isCompatible;
  final DeviceType deviceType;
  final Size screenSize;
  final double pixelRatio;
  final List<CompatibilityIssue> issues;
  final List<String> warnings;
  final List<String> recommendations;
  
  const DeviceCompatibilityResult({
    required this.isCompatible,
    required this.deviceType,
    required this.screenSize,
    required this.pixelRatio,
    required this.issues,
    required this.warnings,
    required this.recommendations,
  });
}

class CompatibilityIssue {
  final IssueType type;
  final String message;
  final String recommendation;
  
  const CompatibilityIssue({
    required this.type,
    required this.message,
    required this.recommendation,
  });
}

enum IssueType {
  critical,
  warning,
  info,
}

class UITestResult {
  final String element;
  final TestStatus status;
  final String message;
  
  const UITestResult({
    required this.element,
    required this.status,
    required this.message,
  });
}

enum TestStatus {
  pass,
  warning,
  fail,
}

class CompatibilityReport {
  final DeviceCompatibilityResult compatibility;
  final String? closestTargetDevice;
  final List<UITestResult> uiTests;
  final DateTime timestamp;
  
  const CompatibilityReport({
    required this.compatibility,
    this.closestTargetDevice,
    required this.uiTests,
    required this.timestamp,
  });
  
  /// Generate a human-readable summary
  String getSummary() {
    final buffer = StringBuffer();
    
    buffer.writeln('=== DEVICE COMPATIBILITY REPORT ===');
    buffer.writeln('Generated: ${timestamp.toIso8601String()}');
    buffer.writeln('');
    
    buffer.writeln('DEVICE INFO:');
    buffer.writeln('Screen Size: ${compatibility.screenSize.width.toInt()} x ${compatibility.screenSize.height.toInt()}');
    buffer.writeln('Pixel Ratio: ${compatibility.pixelRatio.toStringAsFixed(1)}x');
    buffer.writeln('Device Type: ${compatibility.deviceType.name}');
    if (closestTargetDevice != null) {
      buffer.writeln('Closest Target: $closestTargetDevice');
    }
    buffer.writeln('');
    
    buffer.writeln('COMPATIBILITY: ${compatibility.isCompatible ? "✅ COMPATIBLE" : "❌ ISSUES FOUND"}');
    
    if (compatibility.issues.isNotEmpty) {
      buffer.writeln('\nISSUES:');
      for (final issue in compatibility.issues) {
        final icon = issue.type == IssueType.critical ? '🚨' : 
                     issue.type == IssueType.warning ? '⚠️' : 'ℹ️';
        buffer.writeln('$icon ${issue.message}');
        buffer.writeln('   → ${issue.recommendation}');
      }
    }
    
    if (compatibility.warnings.isNotEmpty) {
      buffer.writeln('\nWARNINGS:');
      for (final warning in compatibility.warnings) {
        buffer.writeln('⚠️  $warning');
      }
    }
    
    buffer.writeln('\nUI TESTS:');
    for (final test in uiTests) {
      final icon = test.status == TestStatus.pass ? '✅' : 
                   test.status == TestStatus.warning ? '⚠️' : '❌';
      buffer.writeln('$icon ${test.element}: ${test.message}');
    }
    
    if (compatibility.recommendations.isNotEmpty) {
      buffer.writeln('\nRECOMMENDATIONS:');
      for (final recommendation in compatibility.recommendations) {
        buffer.writeln('💡 $recommendation');
      }
    }
    
    return buffer.toString();
  }
} 