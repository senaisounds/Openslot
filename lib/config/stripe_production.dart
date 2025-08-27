// Stripe production configuration
class StripeProductionConfig {
  // SECURITY: Keys moved to environment variables
  static const String publishableKey = String.fromEnvironment('STRIPE_LIVE_PUBLISHABLE_KEY', 
    defaultValue: 'STRIPE_KEY_NOT_CONFIGURED');
  // Note: Secret keys should NEVER be in client code - keep in Cloud Functions only
  static const String merchantIdentifier = 'merchant.com.openslot.app';
  static const String currency = 'USD';
  static const String country = 'US';
  static const String webhookEndpoint = 'https://us-central1-open-mic-5cc8e.cloudfunctions.net/stripeWebhook';
  static const List<String> webhookEvents = [
    'payment_intent.succeeded',
    'payment_intent.payment_failed',
    'customer.subscription.created',
    'customer.subscription.updated',
    'customer.subscription.deleted',
  ];
  static const bool enableApplePay = true;
  static const bool enableGooglePay = true;
  static const bool enableCardPayments = true;
  static const bool enableBankTransfers = false;
  static const bool enable3DSecure = true;
  static const bool enableFraudDetection = true;
  static const Duration paymentTimeout = Duration(minutes: 10);
}
