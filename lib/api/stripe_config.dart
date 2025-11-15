import 'dart:io';

import 'package:slotted/utils/logger.dart';
import 'package:slotted/utils/secure_storage.dart';

/// Enhanced configuration for Stripe API with improved security
/// 
/// This configuration loads keys from secure storage and environment variables
/// for enhanced security in production environments.
class StripeConfig {
  /// The merchant identifier for Apple Pay
  static const String merchantIdentifier = 'merchant.openslot.app';
  
  /// Default test publishable key (fallback only)
  static const String _defaultTestKey = 'pk_test_REPLACE_WITH_YOUR_TEST_KEY';
  
  /// Default live publishable key (fallback only)  
  static const String _defaultLiveKey = 'pk_live_REPLACE_WITH_YOUR_LIVE_KEY';
  
  /// Cached keys to avoid repeated secure storage access
  static String? _cachedTestKey;
  static String? _cachedLiveKey;
  
  /// Get the appropriate publishable key based on debug mode
  static Future<String> getPublishableKey(bool isDebug) async {
    try {
      if (isDebug) {
        return await _getTestKey();
      } else {
        return await _getLiveKey();
      }
    } catch (e) {
      Logger.w('No Stripe key configured: $e', tag: 'StripeConfig');
      // Fallback to environment variables, or return placeholder for development
      try {
        return isDebug ? _getTestKeyFromEnv() : _getLiveKeyFromEnv();
      } catch (envError) {
        Logger.w('Using placeholder Stripe key for development', tag: 'StripeConfig');
        return isDebug ? _defaultTestKey : _defaultLiveKey;
      }
    }
  }
  
  /// Get test key with caching
  static Future<String> _getTestKey() async {
    if (_cachedTestKey != null) {
      return _cachedTestKey!;
    }
    
    try {
      // Try to get from secure storage first
      final key = await SecureStorage.instance.read(key: 'stripe_test_publishable_key');
      if (key != null && key.isNotEmpty && _isValidStripeKey(key, true)) {
        _cachedTestKey = key;
        return key;
      }
    } catch (e) {
      Logger.w('Failed to get test key from secure storage: $e', tag: 'StripeConfig');
    }
    
    // Fallback to environment variable
    final envKey = _getTestKeyFromEnv();
    if (_isValidStripeKey(envKey, true)) {
      _cachedTestKey = envKey;
      return envKey;
    }
    
    throw Exception('No valid test Stripe publishable key found');
  }
  
  /// Get live key with caching
  static Future<String> _getLiveKey() async {
    if (_cachedLiveKey != null) {
      return _cachedLiveKey!;
    }
    
    try {
      // Try to get from secure storage first
      final key = await SecureStorage.instance.read(key: 'stripe_live_publishable_key');
      if (key != null && key.isNotEmpty && _isValidStripeKey(key, false)) {
        _cachedLiveKey = key;
        return key;
      }
    } catch (e) {
      Logger.w('Failed to get live key from secure storage: $e', tag: 'StripeConfig');
    }
    
    // Fallback to environment variable
    final envKey = _getLiveKeyFromEnv();
    if (_isValidStripeKey(envKey, false)) {
      _cachedLiveKey = envKey;
      return envKey;
    }
    
    throw Exception('No valid live Stripe publishable key found');
  }
  
  /// Get test key from environment variables
  static String _getTestKeyFromEnv() {
    return const String.fromEnvironment('STRIPE_TEST_PUBLISHABLE_KEY', 
      defaultValue: _defaultTestKey);
  }
  
  /// Get live key from environment variables
  static String _getLiveKeyFromEnv() {
    return const String.fromEnvironment('STRIPE_LIVE_PUBLISHABLE_KEY',
      defaultValue: _defaultLiveKey);
  }
  
  /// Validate Stripe publishable key format
  static bool _isValidStripeKey(String key, bool isTest) {
    if (key.isEmpty || key.contains('REPLACE_WITH_YOUR')) {
      return false;
    }
    
    if (isTest) {
      return key.startsWith('pk_test_');
    } else {
      return key.startsWith('pk_live_');
    }
  }
  
  /// Store Stripe keys securely
  static Future<void> storeKeys({
    String? testKey,
    String? liveKey,
  }) async {
    try {
      if (testKey != null && _isValidStripeKey(testKey, true)) {
        await SecureStorage.instance.write(key: 'stripe_test_publishable_key', value: testKey);
        _cachedTestKey = testKey;
        Logger.i('Test Stripe key stored securely', tag: 'StripeConfig');
      }
      
      if (liveKey != null && _isValidStripeKey(liveKey, false)) {
        await SecureStorage.instance.write(key: 'stripe_live_publishable_key', value: liveKey);
        _cachedLiveKey = liveKey;
        Logger.i('Live Stripe key stored securely', tag: 'StripeConfig');
      }
    } catch (e) {
      Logger.e('Error storing Stripe keys: $e', tag: 'StripeConfig');
      rethrow;
    }
  }
  
  /// Clear cached keys (useful for testing or key rotation)
  static void clearCache() {
    _cachedTestKey = null;
    _cachedLiveKey = null;
    Logger.d('Stripe key cache cleared', tag: 'StripeConfig');
  }
  
  /// Get merchant name for payment sheets
  static String getMerchantName() {
    return 'OpenSlot';
  }
  
  /// Get supported countries for payments
  static List<String> getSupportedCountries() {
    return ['US', 'CA'];
  }
  
  /// Get supported currencies
  static List<String> getSupportedCurrencies() {
    return ['USD', 'CAD'];
  }
  
  /// Check if Apple Pay is available on this platform
  static bool isApplePayAvailable() {
    return Platform.isIOS;
  }
  
  /// Check if Google Pay is available on this platform
  static bool isGooglePayAvailable() {
    return Platform.isAndroid;
  }
} 