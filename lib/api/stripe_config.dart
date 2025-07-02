/// Configuration for Stripe API
/// 
/// This file contains the configuration for the Stripe API.
/// In a production environment, these values should be loaded from secure storage
/// or environment variables rather than being hardcoded.
class StripeConfig {
  /// The merchant identifier for Apple Pay
  static const String merchantIdentifier = 'merchant.your.identifier';
  
  /// The publishable key for Stripe in test mode
  static const String testPublishableKey = 
    'pk_test_51RMvr1Q0wBFV119bSMA6fLWwYtL6XpYUlMAqDH3BThLhFqfyhgJfed7RE3TqrWVrZB9D0LNVecYb89AlNNnzDd9D00fxkX1DX0';
  
  /// The publishable key for Stripe in production mode
  static const String livePublishableKey = 
    'pk_live_YOUR_NEW_LIVE_PUBLISHABLE_KEY';
  
  /// Get the appropriate publishable key based on debug mode
  static String getPublishableKey(bool isDebug) {
    return isDebug ? testPublishableKey : livePublishableKey;
  }
} 