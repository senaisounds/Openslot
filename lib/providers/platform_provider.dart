import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:slotted/utils/logger.dart';

/// Provider to handle platform-specific behavior and settings
class PlatformProvider extends ChangeNotifier {
  bool _isDesktop = false;
  bool _isTablet = false;
  bool _isMobile = true;
  final bool _isWebPlatform = kIsWeb;
  
  // Screen size breakpoints
  static const double desktopBreakpoint = 1200.0;
  static const double tabletBreakpoint = 768.0;
  
  PlatformProvider() {
    // Initialize with defaults - will be updated when layout is built
    _isDesktop = false;
    _isTablet = false;
    _isMobile = true;
  }
  
  // Getters
  bool get isDesktop => _isDesktop;
  bool get isTablet => _isTablet;
  bool get isMobile => _isMobile;
  bool get isWebPlatform => _isWebPlatform;
  
  /// Update device type based on screen width
  void updateDeviceType(BuildContext context) {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
    
      final isDesktop = screenWidth >= desktopBreakpoint;
      final isTablet = screenWidth >= tabletBreakpoint && screenWidth < desktopBreakpoint;
      final isMobile = screenWidth < tabletBreakpoint;
      
      if (isDesktop != _isDesktop || 
          isTablet != _isTablet || 
          isMobile != _isMobile) {
        _isDesktop = isDesktop;
        _isTablet = isTablet;
        _isMobile = isMobile;
        notifyListeners();
      }
    } catch (e) {
      Logger.e('Error updating device type', tag: 'PlatformProvider', error: e);
    }
  }
  
  /// Get the appropriate padding for different device types
  EdgeInsets getPadding(BuildContext context) {
    if (_isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0);
    } else if (_isTablet) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0);
    }
  }
  
  /// Get responsive font size
  double getResponsiveFontSize(double baseSize) {
    if (_isDesktop) {
      return baseSize * 1.1;
    } else if (_isTablet) {
      return baseSize * 1.05;
    } else {
      return baseSize;
    }
  }
  
  /// Maximum content width for desktop layouts
  double getMaxContentWidth() {
    return 1200.0;
  }
  
  /// Get responsive container for desktop view
  Widget wrapResponsive(Widget child) {
    if (!_isDesktop) {
      return child;
    }
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: getMaxContentWidth(),
        ),
        child: child,
      ),
    );
  }
  
  /// Check if the current platform is iOS
  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  
  /// Check if the current platform is Android
  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
} 