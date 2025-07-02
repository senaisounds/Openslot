import 'dart:io';

/// A script to scan Dart files for deprecated withOpacity usage and replace with withValues
void main() async {
  print('Scanning for withOpacity usage in the codebase...');
  
  // Define the directory to scan
  final rootDir = Directory('lib');
  
  // Define patterns to search for
  final patterns = [
    RegExp(r'\.withOpacity\(([0-9\.]+)\)'),
    RegExp(r'\.withOpacity\(([a-zA-Z0-9_\.]+)\)'),
  ];
  
  // Count of files and occurrences modified
  int filesModified = 0;
  int occurrencesReplaced = 0;
  
  // Walk through all dart files
  await for (final entity in rootDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Skip the fix_withOpacity.dart file itself
      if (entity.path.contains('fix_withOpacity.dart')) {
        continue;
      }
      
      // Read file contents
      String content = await entity.readAsString();
      bool fileModified = false;
      
      // Check for import
      final hasExtensionImport = content.contains("import 'package:slotted/utils/fix_withOpacity.dart';");
      
      // Check for patterns and replace them
      for (final pattern in patterns) {
        final matches = pattern.allMatches(content);
        if (matches.isNotEmpty) {
          for (final match in matches) {
            final value = match.group(1);
            final replacement = '.withValues(alpha: $value)';
            content = content.replaceAll(match.group(0)!, replacement);
            occurrencesReplaced++;
            fileModified = true;
          }
        }
      }
      
      // Add the import if needed and file was modified
      if (fileModified && !hasExtensionImport) {
        const importStatement = "import 'package:slotted/utils/fix_withOpacity.dart';\n";
        
        // Find a good place to add the import
        if (content.contains("import 'package:flutter/")) {
          // Add after the last Flutter import
          final lastFlutterImport = RegExp(r"import 'package:flutter/[^']+';").allMatches(content).last;
          final insertPos = lastFlutterImport.end;
          content = '${content.substring(0, insertPos)}\n$importStatement${content.substring(insertPos)}';
        } else {
          // Add at the beginning of the file, after any existing imports
          final importSection = RegExp(r"(import '[^']+';(\n|$))+").firstMatch(content);
          if (importSection != null) {
            final insertPos = importSection.end;
            content = content.substring(0, insertPos) + 
                     importStatement + 
                     content.substring(insertPos);
          } else {
            // No imports found, add at the very beginning
            content = importStatement + content;
          }
        }
      }
      
      // Write modified content back to file
      if (fileModified) {
        await entity.writeAsString(content);
        filesModified++;
        print('Fixed withOpacity in: ${entity.path}');
      }
    }
  }
  
  print('\nSummary:');
  print('- Files modified: $filesModified');
  print('- Occurrences replaced: $occurrencesReplaced');
  print('\nNext steps:');
  print('1. Run flutter analyze to check if all warnings are resolved');
  print('2. Review the changes to ensure they work correctly');
  print('3. Test the app for visual consistency');
} 