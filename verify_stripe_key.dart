import 'package:slotted/api/stripe_config.dart';

void main() async {
  print('Checking if Stripe key was saved...\n');
  
  try {
    // Try to get the test key
    final testKey = await StripeConfig.getPublishableKey(true);
    
    if (testKey.contains('pk_test_51RMvr1Q0wBFV119b')) {
      print('✅ SUCCESS! Stripe test key is saved correctly.');
      print('Key starts with: ${testKey.substring(0, 20)}...');
      print('\nThe key you pasted was saved successfully!');
    } else if (testKey.contains('REPLACE_WITH_YOUR')) {
      print('❌ Key was NOT saved - still using placeholder.');
      print('Current key: $testKey');
    } else {
      print('⚠️  Found a key, but it might not be the right one:');
      print('Key: ${testKey.substring(0, 30)}...');
    }
  } catch (e) {
    print('❌ Error checking key: $e');
  }
}
