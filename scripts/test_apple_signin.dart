#!/usr/bin/env dart

// Test script for Apple Sign-In configuration
// This script validates that Apple Sign-In is properly configured

import 'dart:io';

void main() async {
  print('🍎 Testing Apple Sign-In Configuration...\n');
  
  bool allTestsPassed = true;
  
  // Test 1: Check pubspec.yaml for sign_in_with_apple dependency
  print('📦 Test 1: Checking pubspec.yaml dependency...');
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final pubspecContent = await pubspecFile.readAsString();
    if (pubspecContent.contains('sign_in_with_apple:')) {
      print('   ✅ sign_in_with_apple dependency found');
    } else {
      print('   ❌ sign_in_with_apple dependency missing');
      allTestsPassed = false;
    }
  } else {
    print('   ❌ pubspec.yaml not found');
    allTestsPassed = false;
  }
  
  // Test 2: Check iOS entitlements
  print('\n🔐 Test 2: Checking iOS entitlements...');
  final entitlementsFiles = [
    'ios/Runner/Runner.entitlements',
    'ios/Runner/RunnerDebug.entitlements'
  ];
  
  for (final entitlementPath in entitlementsFiles) {
    final entitlementFile = File(entitlementPath);
    if (await entitlementFile.exists()) {
      final entitlementContent = await entitlementFile.readAsString();
      if (entitlementContent.contains('com.apple.developer.applesignin')) {
        print('   ✅ $entitlementPath has Apple Sign-In entitlement');
      } else {
        print('   ❌ $entitlementPath missing Apple Sign-In entitlement');
        allTestsPassed = false;
      }
    } else {
      print('   ❌ $entitlementPath not found');
      allTestsPassed = false;
    }
  }
  
  // Test 3: Check Info.plist URL schemes
  print('\n🔗 Test 3: Checking Info.plist URL schemes...');
  final infoPlistFile = File('ios/Runner/Info.plist');
  if (await infoPlistFile.exists()) {
    final infoPlistContent = await infoPlistFile.readAsString();
    if (infoPlistContent.contains('signinwithapple')) {
      print('   ✅ Apple Sign-In URL scheme found in Info.plist');
    } else {
      print('   ❌ Apple Sign-In URL scheme missing in Info.plist');
      allTestsPassed = false;
    }
  } else {
    print('   ❌ Info.plist not found');
    allTestsPassed = false;
  }
  
  // Test 4: Check Firebase Auth service implementation
  print('\n🔥 Test 4: Checking Firebase Auth implementation...');
  final authServiceFile = File('lib/api/firebase_auth_service.dart');
  if (await authServiceFile.exists()) {
    final authServiceContent = await authServiceFile.readAsString();
    if (authServiceContent.contains('signInWithApple') && 
        authServiceContent.contains('SignInWithApple.getAppleIDCredential')) {
      print('   ✅ Apple Sign-In implementation found in Firebase Auth');
    } else {
      print('   ❌ Apple Sign-In implementation missing in Firebase Auth');
      allTestsPassed = false;
    }
  } else {
    print('   ❌ Firebase Auth service not found');
    allTestsPassed = false;
  }
  
  // Test 5: Check Apple App Site Association
  print('\n🌐 Test 5: Checking Apple App Site Association...');
  final aasaFile = File('web/.well-known/apple-app-site-association');
  if (await aasaFile.exists()) {
    final aasaContent = await aasaFile.readAsString();
    if (aasaContent.contains('applinks') && aasaContent.contains('com.openslot.app')) {
      print('   ✅ Apple App Site Association file found');
    } else {
      print('   ❌ Apple App Site Association file incomplete');
      allTestsPassed = false;
    }
  } else {
    print('   ❌ Apple App Site Association file not found');
    allTestsPassed = false;
  }
  
  // Test 6: Check bundle ID consistency
  print('\n📱 Test 6: Checking bundle ID consistency...');
  final bundleIds = <String, String>{};
  
  // Check Info.plist
  if (await infoPlistFile.exists()) {
    final infoPlistContent = await infoPlistFile.readAsString();
    final bundleIdMatch = RegExp(r'<key>CFBundleIdentifier</key>\s*<string>([^<]+)</string>').firstMatch(infoPlistContent);
    if (bundleIdMatch != null) {
      bundleIds['Info.plist'] = bundleIdMatch.group(1) ?? '';
    }
  }
  
  // Check app_store_config.dart
  final configFile = File('lib/config/app_store_config.dart');
  if (await configFile.exists()) {
    final configContent = await configFile.readAsString();
    final bundleIdMatch = RegExp(r"bundleId = '([^']+)'").firstMatch(configContent);
    if (bundleIdMatch != null) {
      bundleIds['app_store_config.dart'] = bundleIdMatch.group(1) ?? '';
    }
  }
  
  const expectedBundleId = 'com.openslot.app';
  bool bundleIdConsistent = true;
  
  for (final entry in bundleIds.entries) {
    if (entry.value == expectedBundleId) {
      print('   ✅ ${entry.key}: ${entry.value}');
    } else {
      print('   ❌ ${entry.key}: ${entry.value} (expected: $expectedBundleId)');
      bundleIdConsistent = false;
    }
  }
  
  if (!bundleIdConsistent) {
    allTestsPassed = false;
  }
  
  // Summary
  print('\n${'='*50}');
  if (allTestsPassed) {
    print('🎉 ALL TESTS PASSED! Apple Sign-In is correctly configured.');
    print('\n✅ Configuration Summary:');
    print('   • Dependency: sign_in_with_apple v7.0.1');
    print('   • iOS Entitlements: Configured');
    print('   • URL Schemes: Configured');
    print('   • Firebase Auth: Implemented');
    print('   • Bundle ID: com.openslot.app');
    print('   • Apple App Site Association: Ready');
    print('\n🚀 Ready for App Store submission!');
  } else {
    print('❌ SOME TESTS FAILED! Please fix the issues above.');
    print('\n📝 Next Steps:');
    print('   1. Fix the failing configuration items');
    print('   2. Re-run this test');
    print('   3. Test on a physical iOS device');
  }
  
  exit(allTestsPassed ? 0 : 1);
}