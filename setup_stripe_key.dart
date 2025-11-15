import 'package:slotted/api/stripe_config.dart';

void main() async {
  // Your Stripe test key
  const testKey = 'pk_test_51RMvqtLG1bcPbzSkEjmrDKQKgzq0lxlSU3TplU5vJnfaPGX7kI0x1GRQtKk6vSs0UWJXpz7tEk7HsC9PB0UduFkp00T7dEMHhh';
  
  print('Storing Stripe test key...');
  
  try {
    await StripeConfig.storeKeys(testKey: testKey);
    print('✅ Success! Stripe test key has been stored securely.');
    print('Now restart your app with: flutter run');
  } catch (e) {
    print('❌ Error storing key: $e');
  }
}



