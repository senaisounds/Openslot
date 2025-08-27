/// Configuration for Stripe API
/// 
/// This file contains the configuration for the Stripe API.
/// In a production environment, these values should be loaded from secure storage
/// or environment variables rather than being hardcoded.
class StripeConfig {
  /// The merchant identifier for Apple Pay
  static const String merchantIdentifier = 'merchant.your.identifier';
  
  /// The publishable key for Stripe in test mode
  /// TODO: Move to environment variables or Firebase Remote Config
  static const String testPublishableKey = 
    String.fromEnvironment('STRIPE_TEST_PUBLISHABLE_KEY', 
      defaultValue: 'pk_test_REPLACE_WITH_YOUR_TEST_KEY');
  
  /// The publishable key for Stripe in production mode
  /// TODO: Move to environment variables or Firebase Remote Config
  static const String livePublishableKey = 
    String.fromEnvironment('STRIPE_LIVE_PUBLISHABLE_KEY',
      defaultValue: 'pk_live_REPLACE_WITH_YOUR_LIVE_KEY');
  
  /// Get the appropriate publishable key based on debug mode
  static String getPublishableKey(bool isDebug) {
    return isDebug ? testPublishableKey : livePublishableKey;
  }
} 