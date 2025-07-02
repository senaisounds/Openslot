import 'dart:io';

void main() async {
  print('=== Slotted App Store Submission Preparation ===\n');
  
  // Check if we're in the right directory
  if (!await _isFlutterProject()) {
    print('❌ Error: This doesn\'t appear to be a Flutter project directory.');
    print('Please run this script from the root of your Flutter project.');
    return;
  }
  
  print('🔍 Running pre-submission checks...\n');
  
  // Check for debug flags
  await _checkDebugFlags();
  
  // Check pubspec.yaml for version
  await _checkPubspecVersion();
  
  // Check for privacy policy
  await _checkPrivacyPolicy();
  
  // Check for App Store assets
  await _checkAppStoreAssets();
  
  // Run Flutter analyze
  await _runFlutterAnalyze();
  
  // Check for Firebase configuration
  await _checkFirebaseConfig();
  
  // Check for Stripe configuration
  await _checkStripeConfig();
  
  // Suggest running in release mode
  print('\n✅ Suggestion: Run the app in release mode to test performance:');
  print('   flutter run --release');
  
  print('\n✅ Suggestion: Build the app for App Store submission:');
  print('   flutter build ipa --release');
  
  print('\n🎉 Pre-submission checks completed!');
  print('\nRemember to:');
  print('1. Test thoroughly on real devices');
  print('2. Prepare App Store metadata (screenshots, descriptions, etc.)');
  print('3. Ensure your Apple Developer account is active');
  print('4. Consider TestFlight testing before full submission');
}

Future<bool> _isFlutterProject() async {
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    return false;
  }
  
  final content = await pubspecFile.readAsString();
  return content.contains('flutter:');
}

Future<void> _checkDebugFlags() async {
  print('Checking for debug flags...');
  
  final mainFile = File('lib/main.dart');
  if (await mainFile.exists()) {
    final content = await mainFile.readAsString();
    
    if (content.contains('debugPrint') || 
        content.contains('print(') ||
        content.contains('debugShowCheckedModeBanner: true') ||
        content.contains('const bool _debug = true')) {
      print('⚠️ Warning: Debug flags found in main.dart');
      print('   Consider removing debug prints and setting debugShowCheckedModeBanner to false');
    } else {
      print('✅ No obvious debug flags found in main.dart');
    }
  }
  
  // Check for debug mode in Logger class if it exists
  final loggerFile = File('lib/utils/logger.dart');
  if (await loggerFile.exists()) {
    final content = await loggerFile.readAsString();
    
    if (content.contains('static const bool _debugMode = true')) {
      print('⚠️ Warning: Logger is in debug mode');
      print('   Set _debugMode to false before submission');
    } else {
      print('✅ Logger appears to be configured for production');
    }
  }
}

Future<void> _checkPubspecVersion() async {
  print('\nChecking app version...');
  
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final content = await pubspecFile.readAsString();
    
    final versionMatch = RegExp(r'version:\s*(\d+\.\d+\.\d+)').firstMatch(content);
    if (versionMatch != null) {
      final version = versionMatch.group(1);
      print('✅ App version: $version');
      
      // Check if this is a new version
      final buildGradleFile = File('android/app/build.gradle');
      if (await buildGradleFile.exists()) {
        final buildGradleContent = await buildGradleFile.readAsString();
        final versionCodeMatch = RegExp(r'versionCode\s+(\d+)').firstMatch(buildGradleContent);
        
        if (versionCodeMatch != null) {
          final versionCode = int.parse(versionCodeMatch.group(1)!);
          print('   Android version code: $versionCode');
          
          if (versionCode < 2) {
            print('⚠️ Warning: This appears to be the first version. Make sure to increment');
            print('   versionCode for subsequent releases.');
          }
        }
      }
      
      // Check iOS version
      final plistFile = File('ios/Runner/Info.plist');
      if (await plistFile.exists()) {
        final plistContent = await plistFile.readAsString();
        if (plistContent.contains('<key>CFBundleShortVersionString</key>') && 
            plistContent.contains('<key>CFBundleVersion</key>')) {
          print('✅ iOS version info found in Info.plist');
        } else {
          print('⚠️ Warning: iOS version info may be missing in Info.plist');
        }
      }
    } else {
      print('⚠️ Warning: Could not find version in pubspec.yaml');
    }
  }
}

Future<void> _checkPrivacyPolicy() async {
  print('\nChecking for privacy policy...');
  
  bool privacyPolicyFound = false;
  
  // Check common locations for privacy policy
  final possibleLocations = [
    'lib/pages/privacy_policy.dart',
    'lib/screens/privacy_policy.dart',
    'lib/views/privacy_policy.dart',
    'assets/privacy_policy.html',
    'assets/privacy_policy.md',
    'privacy_policy.md',
  ];
  
  for (final location in possibleLocations) {
    if (await File(location).exists()) {
      print('✅ Privacy policy found at: $location');
      privacyPolicyFound = true;
      break;
    }
  }
  
  if (!privacyPolicyFound) {
    print('⚠️ Warning: Could not find a privacy policy file');
    print('   The App Store requires a privacy policy for all apps');
  }
}

Future<void> _checkAppStoreAssets() async {
  print('\nChecking for App Store assets...');
  
  // Check for app icon
  final appIconDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (await appIconDir.exists()) {
    final iconFiles = await appIconDir.list().toList();
    if (iconFiles.length > 3) { // Contents.json + at least a few icons
      print('✅ iOS app icons found');
    } else {
      print('⚠️ Warning: iOS app icons may be missing');
    }
  } else {
    print('⚠️ Warning: iOS app icon directory not found');
  }
  
  // Check for launch screen
  final launchScreenDir = Directory('ios/Runner/Assets.xcassets/LaunchImage.imageset');
  if (await launchScreenDir.exists()) {
    print('✅ iOS launch screen found');
  } else {
    final launchScreenStoryboard = File('ios/Runner/Base.lproj/LaunchScreen.storyboard');
    if (await launchScreenStoryboard.exists()) {
      print('✅ iOS launch screen storyboard found');
    } else {
      print('⚠️ Warning: iOS launch screen may be missing');
    }
  }
  
  // Check for screenshots directory
  final screenshotsDir = Directory('screenshots');
  if (await screenshotsDir.exists()) {
    print('✅ Screenshots directory found');
  } else {
    print('⚠️ Warning: Screenshots directory not found');
    print('   Consider creating a "screenshots" directory with App Store screenshots');
  }
}

Future<void> _runFlutterAnalyze() async {
  print('\nRunning Flutter analyze...');
  
  try {
    final process = await Process.start('flutter', ['analyze']);
    final exitCode = await process.exitCode;
    
    if (exitCode == 0) {
      print('✅ Flutter analyze completed successfully');
    } else {
      print('⚠️ Warning: Flutter analyze found issues');
      print('   Run "flutter analyze" to see the details');
    }
  } catch (e) {
    print('⚠️ Warning: Could not run Flutter analyze: $e');
  }
}

Future<void> _checkFirebaseConfig() async {
  print('\nChecking Firebase configuration...');
  
  // Check for Firebase config files
  final iosGoogleServiceInfo = File('ios/Runner/GoogleService-Info.plist');
  final androidGoogleServices = File('android/app/google-services.json');
  
  if (await iosGoogleServiceInfo.exists()) {
    print('✅ iOS Firebase configuration found');
  } else {
    print('⚠️ Warning: iOS Firebase configuration not found');
    print('   Missing: ios/Runner/GoogleService-Info.plist');
  }
  
  if (await androidGoogleServices.exists()) {
    print('✅ Android Firebase configuration found');
  } else {
    print('⚠️ Warning: Android Firebase configuration not found');
    print('   Missing: android/app/google-services.json');
  }
}

Future<void> _checkStripeConfig() async {
  print('\nChecking Stripe configuration...');
  
  // Check for Stripe API keys
  final stripeFile = File('lib/api/stripe.dart');
  if (await stripeFile.exists()) {
    final content = await stripeFile.readAsString();
    
    if (content.contains('sk_test_') && content.contains('sk_live_')) {
      print('✅ Stripe API keys found');
      
      if (content.contains('stripeKey =') && !content.contains('stripeKey = const')) {
        print('⚠️ Warning: Consider making Stripe API keys constant for better security');
      }
      
      // Check for hardcoded keys
      if (content.contains('sk_live_51')) {
        print('⚠️ Warning: Live Stripe API key appears to be hardcoded');
        print('   Consider using environment variables or a secure storage solution');
      }
    } else {
      print('⚠️ Warning: Stripe API keys may be missing or incomplete');
    }
  } else {
    print('ℹ️ Info: Stripe API file not found at expected location');
  }
} 