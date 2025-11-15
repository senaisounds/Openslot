#!/usr/bin/env dart
/// Payment Configuration Diagnostic Tool
/// 
/// Run this script to check if your payment system is properly configured.
/// 
/// Usage: dart scripts/test_payment_config.dart

import 'dart:io';

void main() async {
  print('🔍 OpenSlot Payment Configuration Diagnostic\n');
  print('=' * 60);
  
  bool allGood = true;
  
  // 1. Check Flutter Stripe package
  print('\n1️⃣  Checking Flutter Stripe package...');
  final pubspecResult = await Process.run('flutter', ['pub', 'deps']);
  if (pubspecResult.stdout.toString().contains('flutter_stripe')) {
    print('   ✅ flutter_stripe package installed');
  } else {
    print('   ❌ flutter_stripe package not found');
    allGood = false;
  }
  
  // 2. Check Firebase Functions files
  print('\n2️⃣  Checking Firebase Functions...');
  final functionsFiles = [
    'functions/src/index.ts',
    'functions/lib/index.js',
    'functions/package.json',
  ];
  
  for (final file in functionsFiles) {
    if (await File(file).exists()) {
      print('   ✅ $file exists');
    } else {
      print('   ❌ $file missing');
      allGood = false;
    }
  }
  
  // 3. Check for createPaymentIntent function
  print('\n3️⃣  Checking Payment Intent function...');
  final indexTs = File('functions/src/index.ts');
  if (await indexTs.exists()) {
    final content = await indexTs.readAsString();
    if (content.contains('createPaymentIntent')) {
      print('   ✅ createPaymentIntent function found');
    } else {
      print('   ❌ createPaymentIntent function not found');
      allGood = false;
    }
    
    if (content.contains('createStripeCustomer')) {
      print('   ✅ createStripeCustomer function found');
    } else {
      print('   ❌ createStripeCustomer function not found');
      allGood = false;
    }
    
    if (content.contains('reportStripeUsage')) {
      print('   ✅ reportStripeUsage function found');
    } else {
      print('   ❌ reportStripeUsage function not found');
      allGood = false;
    }
  }
  
  // 4. Check Stripe configuration files
  print('\n4️⃣  Checking Stripe configuration files...');
  final configFiles = [
    'lib/api/stripe_config.dart',
    'lib/api/stripe_customer_service.dart',
    'lib/api/stripe_usage_tracker.dart',
    'lib/widgets/modern_payment_widget.dart',
    'lib/api/apple_pay.dart',
  ];
  
  for (final file in configFiles) {
    if (await File(file).exists()) {
      print('   ✅ $file exists');
    } else {
      print('   ❌ $file missing');
      allGood = false;
    }
  }
  
  // 5. Check for hardcoded keys (security check)
  print('\n5️⃣  Security check - looking for hardcoded keys...');
  final grepResult = await Process.run(
    'grep',
    ['-r', 'pk_test_[^R]', 'lib/', '--include=*.dart'],
  );
  
  if (grepResult.stdout.toString().isEmpty) {
    print('   ✅ No hardcoded test keys found');
  } else {
    print('   ⚠️  Found potential hardcoded keys:');
    print('   ${grepResult.stdout}');
  }
  
  // 6. Check merchant identifier
  print('\n6️⃣  Checking Apple Pay configuration...');
  final stripeConfigFile = File('lib/api/stripe_config.dart');
  if (await stripeConfigFile.exists()) {
    final content = await stripeConfigFile.readAsString();
    if (content.contains('merchant.openslot.app')) {
      print('   ✅ Merchant identifier configured: merchant.openslot.app');
    } else {
      print('   ⚠️  Merchant identifier not found or different');
    }
  }
  
  // 7. Check iOS entitlements
  print('\n7️⃣  Checking iOS Apple Pay entitlements...');
  final iosEntitlements = File('ios/Runner/Runner.entitlements');
  if (await iosEntitlements.exists()) {
    final content = await iosEntitlements.readAsString();
    if (content.contains('com.apple.developer.in-app-payments')) {
      print('   ✅ Apple Pay capability enabled in iOS entitlements');
    } else {
      print('   ⚠️  Apple Pay capability not found in iOS entitlements');
    }
  } else {
    print('   ⚠️  iOS entitlements file not found');
  }
  
  // 8. Check environment config
  print('\n8️⃣  Checking environment configuration...');
  final envConfigFile = File('lib/config/environment_config.dart');
  if (await envConfigFile.exists()) {
    final content = await envConfigFile.readAsString();
    if (content.contains('apiBaseUrl')) {
      print('   ✅ API base URL configured');
      if (content.contains('us-central1-open-mic-5cc8e.cloudfunctions.net')) {
        print('   ✅ Using Firebase Functions endpoint');
      }
    } else {
      print('   ❌ API base URL not configured');
      allGood = false;
    }
  }
  
  // Summary
  print('\n${'=' * 60}');
  print('\n📊 Summary\n');
  
  if (allGood) {
    print('✅ All critical checks passed!');
    print('\n📝 Next steps:');
    print('   1. Configure Stripe keys in app Settings');
    print('   2. Deploy Firebase Functions: cd functions && npm run deploy');
    print('   3. Test payment with Stripe test card: 4242 4242 4242 4242');
    print('\n🎉 Your payment system is ready!');
  } else {
    print('❌ Some checks failed. Please review the issues above.');
    print('\n📚 Refer to PAYMENT_SYSTEM_ANALYSIS.md for details.');
  }
  
  print('\n${'=' * 60}');
  
  // Additional info
  print('\n💡 Quick Test:');
  print('   • Run app in debug mode');
  print('   • Create an event with price > \$0');
  print('   • Try to reserve the event');
  print('   • Payment sheet should appear');
  print('   • Use test card: 4242 4242 4242 4242');
  
  print('\n📖 Documentation:');
  print('   • Payment Analysis: PAYMENT_SYSTEM_ANALYSIS.md');
  print('   • Stripe Setup: STRIPE_SETUP_GUIDE.md');
  print('   • Integration Guide: STRIPE_INTEGRATION_ANALYSIS.md');
  
  print('\n✨ Done!\n');
}

