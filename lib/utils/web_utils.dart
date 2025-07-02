import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Utility class for web-specific functionality
/// This is the non-web implementation (stub)
class WebUtils {
  /// Initialize web utilities
  static void init() {
    debugPrint('WebUtils init called on non-web platform');
  }
  
  /// Handle successful web authentication
  static void handleWebAuthSuccess(User user) {
    // No-op on non-web platforms
  }
  
  /// Check if the app is running in a mobile browser
  static bool isMobileBrowser() {
    return false;
  }
  
  /// Check if the app is running in Safari
  static bool isSafariBrowser() {
    return false;
  }
  
  /// Open a URL in a new tab
  static void openUrl(String url) {
    // No-op on non-web platforms
  }
} 