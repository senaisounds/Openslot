// ignore: uri_does_not_exist
import 'dart:html' if (dart.library.io) 'package:slotted/utils/html_stub.dart' as html;
// ignore: uri_does_not_exist
import 'dart:js' if (dart.library.io) 'package:slotted/utils/js_stub.dart' as js;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:slotted/utils/connectivity_service.dart';

/// Utility class for web-specific functionality
/// This is the web implementation
class WebUtils {
  /// Initialize web utilities
  static void init() {
    debugPrint('WebUtils initialized for web platform');
    
    // Set up network listeners
    _setupNetworkListeners();
    
    // Set up a listener for URL hash changes for deep linking
    html.window.onHashChange.listen((event) {
      final hash = html.window.location.hash;
      if (hash.isNotEmpty) {
        debugPrint('URL hash changed: $hash');
        _handleDeepLink(hash);
      }
    });
    
    // Check for initial hash
    final initialHash = html.window.location.hash;
    if (initialHash.isNotEmpty) {
      _handleDeepLink(initialHash);
    }
  }
  
  /// Set up network listeners for web
  static void _setupNetworkListeners() {
    debugPrint('Setting up web network listeners');
    
    // Add online listener
    html.window.addEventListener('online', (event) {
      debugPrint('Web: Device went online');
      ConnectivityService.instance.setOnline(true);
    });
    
    // Add offline listener
    html.window.addEventListener('offline', (event) {
      debugPrint('Web: Device went offline');
      ConnectivityService.instance.setOnline(false);
    });
    
    // Initial status check
    ConnectivityService.instance.setOnline(html.window.navigator.onLine ?? true);
  }
  
  /// Handle URL hash changes for deep linking
  static void _handleDeepLink(String hash) {
    // Remove leading # if present
    final path = hash.startsWith('#') ? hash.substring(1) : hash;
    
    if (path.startsWith('/events/')) {
      // Handle event deep link
      final eventId = path.split('/').last;
      debugPrint('Deep link to event: $eventId');
      // Navigate to event (implementation depends on your navigation system)
    } else if (path.startsWith('/profile/')) {
      // Handle profile deep link
      final userId = path.split('/').last;
      debugPrint('Deep link to profile: $userId');
      // Navigate to profile
    }
  }
  
  /// Handle successful web authentication
  static void handleWebAuthSuccess(User user) {
    debugPrint('Web auth success for user: ${user.uid}');
    
    // Handle redirect back from OAuth providers
    try {
      // Check if we need to handle Instagram auth specifically
      if (user.providerData.any((element) => 
          element.providerId.toLowerCase().contains('instagram'))) {
        _handleInstagramAuthSuccess(user);
      }
      
      // Clear URL fragments after authentication to prevent issues with repeated auth
      if (html.window.location.href.contains('#')) {
        final baseUrl = html.window.location.href.split('#')[0];
        html.window.history.replaceState({}, '', baseUrl);
      }
    } catch (e) {
      debugPrint('Error handling web auth success: $e');
    }
  }
  
  /// Handle Instagram auth specifically
  static void _handleInstagramAuthSuccess(User user) {
    debugPrint('Instagram auth successful, processing additional data if needed');
    // Additional Instagram-specific handling
  }
  
  /// Check if the app is running in a mobile browser
  static bool isMobileBrowser() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('android') || 
           userAgent.contains('iphone') || 
           userAgent.contains('ipad') || 
           userAgent.contains('ipod') || 
           userAgent.contains('mobile');
  }
  
  /// Check if the app is running in Safari
  static bool isSafariBrowser() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('safari') && !userAgent.contains('chrome');
  }
  
  /// Open a URL in a new tab
  static void openUrl(String url) {
    html.window.open(url, '_blank');
  }
  
  /// Add a class to a Flutter-rendered element
  static void addClassToElement(String elementSelector, String className) {
    try {
      final elements = html.document.querySelectorAll(elementSelector);
      for (final element in elements) {
        element.classes.add(className);
      }
    } catch (e) {
      debugPrint('Error adding class to element: $e');
    }
  }
  
  /// Execute JavaScript
  static dynamic executeJavaScript(String code) {
    try {
      return js.context.callMethod('eval', [code]);
    } catch (e) {
      debugPrint('Error executing JavaScript: $e');
      return null;
    }
  }
  
  /// Check if recaptcha is present
  static bool hasRecaptcha() {
    try {
      final elements = html.document.getElementsByClassName('grecaptcha-badge');
      return elements.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Hide recaptcha badge
  static void hideRecaptchaBadge() {
    try {
      final elements = html.document.getElementsByClassName('grecaptcha-badge');
      for (var i = 0; i < elements.length; i++) {
        final element = elements[i] as html.Element;
        element.style.visibility = 'hidden';
        element.style.opacity = '0';
      }
    } catch (e) {
      debugPrint('Error hiding recaptcha badge: $e');
    }
  }
} 