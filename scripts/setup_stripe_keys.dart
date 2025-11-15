#!/usr/bin/env dart

/// Script to securely store Stripe API keys
/// 
/// Usage:
/// dart run scripts/setup_stripe_keys.dart
/// 
/// Then follow the prompts to enter your keys

import 'dart:io';

void main() async {
  print('═══════════════════════════════════════════════════════════');
  print('         OpenSlot - Stripe Key Configuration');
  print('═══════════════════════════════════════════════════════════\n');
  
  print('This script will help you configure your Stripe API keys.\n');
  print('You can find your keys at: https://dashboard.stripe.com/apikeys\n');
  
  // Get test key
  print('Enter your Stripe TEST publishable key (pk_test_...)');
  print('(Press Enter to skip): ');
  final testKey = stdin.readLineSync()?.trim() ?? '';
  
  // Get live key
  print('\nEnter your Stripe LIVE publishable key (pk_live_...)');
  print('(Press Enter to skip): ');
  final liveKey = stdin.readLineSync()?.trim() ?? '';
  
  // Validate keys
  bool hasValidKeys = false;
  
  if (testKey.isNotEmpty && testKey.startsWith('pk_test_')) {
    print('✓ Valid test key provided');
    hasValidKeys = true;
  } else if (testKey.isNotEmpty) {
    print('✗ Invalid test key format (should start with pk_test_)');
  }
  
  if (liveKey.isNotEmpty && liveKey.startsWith('pk_live_')) {
    print('✓ Valid live key provided');
    hasValidKeys = true;
  } else if (liveKey.isNotEmpty) {
    print('✗ Invalid live key format (should start with pk_live_)');
  }
  
  if (!hasValidKeys) {
    print('\n✗ No valid keys provided. Exiting.');
    exit(1);
  }
  
  // Generate dart code to store keys
  print('\n═══════════════════════════════════════════════════════════');
  print('To store these keys, add this code to your app:');
  print('═══════════════════════════════════════════════════════════\n');
  
  print('import \'package:slotted/api/stripe_config.dart\';');
  print('');
  print('// Call this once when setting up your app');
  print('await StripeConfig.storeKeys(');
  if (testKey.isNotEmpty && testKey.startsWith('pk_test_')) {
    print('  testKey: \'$testKey\',');
  }
  if (liveKey.isNotEmpty && liveKey.startsWith('pk_live_')) {
    print('  liveKey: \'$liveKey\',');
  }
  print(');');
  
  print('\n═══════════════════════════════════════════════════════════');
  print('Alternative: Set environment variables');
  print('═══════════════════════════════════════════════════════════\n');
  
  if (testKey.isNotEmpty && testKey.startsWith('pk_test_')) {
    print('export STRIPE_TEST_PUBLISHABLE_KEY="$testKey"');
  }
  if (liveKey.isNotEmpty && liveKey.startsWith('pk_live_')) {
    print('export STRIPE_LIVE_PUBLISHABLE_KEY="$liveKey"');
  }
  
  print('\n═══════════════════════════════════════════════════════════');
  print('IMPORTANT SECURITY NOTES:');
  print('═══════════════════════════════════════════════════════════');
  print('1. Never commit these keys to version control');
  print('2. Use environment variables for CI/CD');
  print('3. Rotate keys regularly');
  print('4. Keep test and live keys separate');
  print('═══════════════════════════════════════════════════════════\n');
}


