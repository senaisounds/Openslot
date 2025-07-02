import 'dart:io';

void main(List<String> args) async {
  print('=== Slotted App Improvement Suite ===\n');
  
  // Check if we're in the right directory
  if (!await _isFlutterProject()) {
    print('❌ Error: This doesn\'t appear to be a Flutter project directory.');
    print('Please run this script from the root of your Flutter project.');
    return;
  }
  
  // Parse arguments
  bool runAll = args.isEmpty || args.contains('all');
  bool fixLogs = runAll || args.contains('logs');
  bool fixStripe = runAll || args.contains('stripe');
  bool checkDeprecated = runAll || args.contains('deprecated');
  bool checkAsync = runAll || args.contains('async');
  bool prepareForAppStore = runAll || args.contains('appstore');
  
  // Show help if requested
  if (args.contains('--help') || args.contains('-h')) {
    _showHelp();
    return;
  }
  
  // Create scripts directory if it doesn't exist
  final scriptsDir = Directory('scripts');
  if (!await scriptsDir.exists()) {
    await scriptsDir.create();
    print('Created scripts directory');
  }
  
  // Run selected scripts
  if (fixLogs) {
    print('\n🔍 Running Logger Replacement Script...');
    await _runScript('scripts/replace_prints.dart');
  }
  
  if (fixStripe) {
    print('\n🔍 Running Stripe Error Fix Script...');
    await _runScript('scripts/fix_stripe_errors.dart');
  }
  
  if (checkDeprecated) {
    print('\n🔍 Running Deprecated API Check...');
    await _runScript('scripts/check_deprecated_apis.dart');
  }
  
  if (checkAsync) {
    print('\n🔍 Running Async Context Check...');
    await _runScript('scripts/check_async_context.dart');
  }
  
  if (prepareForAppStore) {
    print('\n🔍 Running App Store Preparation Check...');
    await _runScript('scripts/prepare_for_app_store.dart');
  }
  
  print('\n✅ All selected scripts have been executed!');
  print('\nNext steps:');
  print('1. Review the output from each script');
  print('2. Fix any issues identified');
  print('3. Run "flutter analyze" to check for any remaining issues');
  print('4. Test your app thoroughly before submission');
}

Future<bool> _isFlutterProject() async {
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    return false;
  }
  
  final content = await pubspecFile.readAsString();
  return content.contains('flutter:');
}

Future<void> _runScript(String scriptPath) async {
  final scriptFile = File(scriptPath);
  
  if (!await scriptFile.exists()) {
    print('⚠️ Warning: Script not found: $scriptPath');
    return;
  }
  
  try {
    final process = await Process.start('dart', [scriptPath]);
    
    // Forward stdout and stderr
    process.stdout.listen((data) {
      stdout.add(data);
    });
    
    process.stderr.listen((data) {
      stderr.add(data);
    });
    
    final exitCode = await process.exitCode;
    
    if (exitCode != 0) {
      print('⚠️ Warning: Script exited with code $exitCode: $scriptPath');
    }
  } catch (e) {
    print('⚠️ Error running script $scriptPath: $e');
  }
}

void _showHelp() {
  print('Usage: dart scripts/run_all.dart [options]');
  print('\nOptions:');
  print('  all        Run all scripts (default if no options specified)');
  print('  logs       Replace print statements with Logger calls');
  print('  stripe     Fix Stripe integration errors');
  print('  deprecated Check for deprecated API usage');
  print('  async      Check for BuildContext usage across async gaps');
  print('  appstore   Run App Store submission preparation checks');
  print('  --help, -h Show this help message');
  print('\nExamples:');
  print('  dart scripts/run_all.dart                # Run all scripts');
  print('  dart scripts/run_all.dart logs stripe    # Only run logs and stripe scripts');
} 