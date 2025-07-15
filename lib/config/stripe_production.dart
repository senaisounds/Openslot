// Stripe production configuration
class StripeProductionConfig {
  static const String publishableKey = 'pk_live_...'; // Replace with your live key
  static const String secretKey = 'sk_live_...'; // Replace with your live key
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
