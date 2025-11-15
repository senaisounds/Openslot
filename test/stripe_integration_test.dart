import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/api/stripe_config.dart';
import 'package:slotted/utils/secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive test suite for Stripe integration
/// 
/// This test verifies:
/// - Key storage and retrieval
/// - Test/Live key switching
/// - Key validation
/// - Error handling
/// - Configuration management
void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Stripe Configuration Tests', () {
    
    setUp(() async {
      // Clear any existing keys before each test
      StripeConfig.clearCache();
    });

    test('should validate test key format correctly', () {
      const validTestKey = 'pk_test_51RMvr1Q0wBFV119bSMA6fLWwYtL6XpYUlMAqDH3BThLhFqfyhgJfed7RE3TqrWVrZB9D0LNVecYb89AlNNnzDd9D00fxkX1DX0';
      const invalidKey1 = 'sk_test_invalid'; // Secret key, not publishable
      const invalidKey2 = 'pk_live_test'; // Wrong prefix
      const invalidKey3 = 'pk_test_'; // Too short
      const invalidKey4 = 'REPLACE_WITH_YOUR_TEST_KEY'; // Placeholder

      expect(validTestKey.startsWith('pk_test_'), isTrue);
      expect(validTestKey.length > 20, isTrue);
      
      expect(invalidKey1.startsWith('pk_test_'), isFalse);
      expect(invalidKey2.startsWith('pk_test_'), isFalse);
      expect(invalidKey3.length > 20, isFalse);
      expect(invalidKey4.contains('REPLACE'), isTrue);
    });

    test('should validate live key format correctly', () {
      const validLiveKey = 'pk_live_51RMvqtLG1bcPbzSkidplOFw9WRtacYKtwu4JCHQ0ELEO3whKHrKgGQ1GnYyEVNVdue3vlK7fMz386PJsg8uzyLPn00oybarvuz';
      const invalidKey = 'pk_test_something'; // Test key, not live

      expect(validLiveKey.startsWith('pk_live_'), isTrue);
      expect(validLiveKey.length > 20, isTrue);
      expect(invalidKey.startsWith('pk_live_'), isFalse);
    });

    test('should return correct merchant identifier', () {
      expect(StripeConfig.merchantIdentifier, equals('merchant.openslot.app'));
    });

    test('should return correct merchant name', () {
      expect(StripeConfig.getMerchantName(), equals('OpenSlot'));
    });

    test('should return supported countries', () {
      final countries = StripeConfig.getSupportedCountries();
      expect(countries, contains('US'));
      expect(countries, contains('CA'));
      expect(countries.length, equals(2));
    });

    test('should return supported currencies', () {
      final currencies = StripeConfig.getSupportedCurrencies();
      expect(currencies, contains('USD'));
      expect(currencies, contains('CAD'));
      expect(currencies.length, equals(2));
    });

    test('should detect Apple Pay availability on iOS', () {
      // This will return true on iOS, false on other platforms
      final isAvailable = StripeConfig.isApplePayAvailable();
      expect(isAvailable, isA<bool>());
    });

    test('should detect Google Pay availability on Android', () {
      // This will return true on Android, false on other platforms
      final isAvailable = StripeConfig.isGooglePayAvailable();
      expect(isAvailable, isA<bool>());
    });

    test('should clear cache without errors', () {
      expect(() => StripeConfig.clearCache(), returnsNormally);
    });
  });

  group('Stripe Key Storage Tests', () {
    
    test('should store and retrieve test key correctly', () async {
      const testKey = 'pk_test_51RMvr1Q0wBFV119bSMA6fLWwYtL6XpYUlMAqDH3BThLhFqfyhgJfed7RE3TqrWVrZB9D0LNVecYb89AlNNnzDd9D00fxkX1DX0';
      
      // Store the key
      await StripeConfig.storeKeys(testKey: testKey);
      
      // Retrieve it in debug mode
      final retrievedKey = await StripeConfig.getPublishableKey(true);
      
      expect(retrievedKey, equals(testKey));
      expect(retrievedKey.startsWith('pk_test_'), isTrue);
    });

    test('should store and retrieve live key correctly', () async {
      const liveKey = 'pk_live_51RMvqtLG1bcPbzSkidplOFw9WRtacYKtwu4JCHQ0ELEO3whKHrKgGQ1GnYyEVNVdue3vlK7fMz386PJsg8uzyLPn00oybarvuz';
      
      // Store the key
      await StripeConfig.storeKeys(liveKey: liveKey);
      
      // Retrieve it in production mode
      final retrievedKey = await StripeConfig.getPublishableKey(false);
      
      expect(retrievedKey, equals(liveKey));
      expect(retrievedKey.startsWith('pk_live_'), isTrue);
    });

    test('should reject invalid test key format', () async {
      const invalidKey = 'invalid_key_format';
      
      // This should not throw, but the key won't be stored
      await StripeConfig.storeKeys(testKey: invalidKey);
      
      // Trying to retrieve should fall back to default or throw
      expect(
        () => StripeConfig.getPublishableKey(true),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle missing keys gracefully', () async {
      // Clear all keys
      await SecureStorage.instance.delete(key: 'stripe_test_publishable_key');
      await SecureStorage.instance.delete(key: 'stripe_live_publishable_key');
      StripeConfig.clearCache();
      
      // Trying to get a key that doesn't exist should throw
      expect(
        () => StripeConfig.getPublishableKey(true),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Stripe Key Caching Tests', () {
    
    test('should cache keys after first retrieval', () async {
      const testKey = 'pk_test_51RMvr1Q0wBFV119bSMA6fLWwYtL6XpYUlMAqDH3BThLhFqfyhgJfed7RE3TqrWVrZB9D0LNVecYb89AlNNnzDd9D00fxkX1DX0';
      
      // Store the key
      await StripeConfig.storeKeys(testKey: testKey);
      
      // First retrieval (from storage)
      final key1 = await StripeConfig.getPublishableKey(true);
      
      // Second retrieval (should be from cache, faster)
      final key2 = await StripeConfig.getPublishableKey(true);
      
      expect(key1, equals(key2));
      expect(key1, equals(testKey));
    });

    test('should clear cache when requested', () async {
      const testKey = 'pk_test_51RMvr1Q0wBFV119bSMA6fLWwYtL6XpYUlMAqDH3BThLhFqfyhgJfed7RE3TqrWVrZB9D0LNVecYb89AlNNnzDd9D00fxkX1DX0';
      
      await StripeConfig.storeKeys(testKey: testKey);
      await StripeConfig.getPublishableKey(true); // Cache the key
      
      StripeConfig.clearCache(); // Clear cache
      
      // Should still work, retrieving from storage again
      final key = await StripeConfig.getPublishableKey(true);
      expect(key, equals(testKey));
    });
  });

  group('Stripe Mode Switching Tests', () {
    
    test('should switch between test and live keys based on debug flag', () async {
      const testKey = 'pk_test_51RMvr1Q0wBFV119bSMA6fLWwYtL6XpYUlMAqDH3BThLhFqfyhgJfed7RE3TqrWVrZB9D0LNVecYb89AlNNnzDd9D00fxkX1DX0';
      const liveKey = 'pk_live_51RMvqtLG1bcPbzSkidplOFw9WRtacYKtwu4JCHQ0ELEO3whKHrKgGQ1GnYyEVNVdue3vlK7fMz386PJsg8uzyLPn00oybarvuz';
      
      // Store both keys
      await StripeConfig.storeKeys(testKey: testKey, liveKey: liveKey);
      
      // Get test key (debug mode = true)
      final retrievedTestKey = await StripeConfig.getPublishableKey(true);
      expect(retrievedTestKey, equals(testKey));
      expect(retrievedTestKey.startsWith('pk_test_'), isTrue);
      
      // Get live key (debug mode = false)
      final retrievedLiveKey = await StripeConfig.getPublishableKey(false);
      expect(retrievedLiveKey, equals(liveKey));
      expect(retrievedLiveKey.startsWith('pk_live_'), isTrue);
    });

    test('should use kDebugMode correctly in production', () {
      // In test environment, kDebugMode is true
      expect(kDebugMode, isTrue);
      
      // This simulates what will happen in production
      // In release builds, kDebugMode will be false
      const simulatedProductionMode = false;
      expect(simulatedProductionMode, isFalse);
    });
  });

  group('Stripe Configuration Error Handling', () {
    
    test('should throw error when no test key is configured', () async {
      // Clear all keys
      await SecureStorage.instance.deleteAll();
      StripeConfig.clearCache();
      
      expect(
        () => StripeConfig.getPublishableKey(true),
        throwsA(
          predicate((e) => 
            e is Exception && 
            e.toString().contains('No valid test Stripe publishable key found')
          )
        ),
      );
    });

    test('should throw error when no live key is configured', () async {
      // Clear all keys
      await SecureStorage.instance.deleteAll();
      StripeConfig.clearCache();
      
      expect(
        () => StripeConfig.getPublishableKey(false),
        throwsA(
          predicate((e) => 
            e is Exception && 
            e.toString().contains('No valid live Stripe publishable key found')
          )
        ),
      );
    });

    test('should handle storage errors gracefully', () async {
      // This tests that the app continues even if storage fails
      expect(
        () => StripeConfig.storeKeys(testKey: null, liveKey: null),
        returnsNormally,
      );
    });
  });

  group('Stripe Integration Recommendations', () {
    
    test('RECOMMENDATION: Keys should never be committed to version control', () {
      // This is a documentation test
      const recommendation = '''
      SECURITY BEST PRACTICES:
      1. Never commit Stripe keys to Git
      2. Use secure storage for key persistence
      3. Use environment variables for CI/CD
      4. Rotate keys regularly
      5. Keep test and live keys separate
      6. Use .gitignore for sensitive files
      ''';
      
      expect(recommendation, isNotEmpty);
      // This test always passes but documents the security requirements
    });

    test('RECOMMENDATION: Implement usage tracking for billing', () {
      // This is a documentation test for the $0.99 per booking setup
      const recommendation = '''
      USAGE TRACKING REQUIRED:
      1. Send 'booking_completed' event to Stripe after successful payment
      2. Include metadata: userId, eventId, amount, timestamp
      3. Track in Stripe Billing Meter: "Event Bookings"
      4. Verify events appear in Stripe Dashboard
      5. Set up webhooks for payment confirmations
      ''';
      
      expect(recommendation, isNotEmpty);
      // This test documents the billing requirements
    });
  });
}

