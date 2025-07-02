import 'dart:io';

/// A script to scan Dart files for print statements and replace them with Logger calls
void main() async {
  print('Scanning for print statements in the codebase...');
  
  // Define the directory to scan
  final rootDir = Directory('lib');
  
  // Define patterns to search for
  final printPattern = RegExp(r'print\(([^;]+)\);');
  
  // Count of files and occurrences modified
  int filesModified = 0;
  int occurrencesReplaced = 0;
  
  // Logging levels to use
  const loggingLevels = ['d', 'i', 'w', 'e'];
  int currentLevel = 0;
  
  // Walk through all dart files
  await for (final entity in rootDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Skip logger.dart itself
      if (entity.path.contains('logger.dart')) {
        continue;
      }
      
      // Read file contents
      String content = await entity.readAsString();
      bool fileModified = false;
      
      // Check for import
      final hasLoggerImport = content.contains("import 'package:slotted/utils/logger.dart';");
      
      // Check for patterns and replace them
      final matches = printPattern.allMatches(content);
      if (matches.isNotEmpty) {
        for (final match in matches) {
          final value = match.group(1);
          
          // Determine logging level based on content
          String level = loggingLevels[0]; // Default to debug
          
          // Check for error terms to set appropriate level
          if (value!.toLowerCase().contains('error') || 
              value.toLowerCase().contains('exception') || 
              value.toLowerCase().contains('failed')) {
            level = loggingLevels[2]; // warning
          } else if (value.toLowerCase().contains('warning') || 
                    value.toLowerCase().contains('warn')) {
            level = loggingLevels[2]; // warning
          } else if (value.toLowerCase().contains('success') || 
                    value.toLowerCase().contains('completed')) {
            level = loggingLevels[1]; // info
          }
          
          // Extract filename for tag from path
          final pathParts = entity.path.split('/');
          final fileName = pathParts.last.replaceAll('.dart', '');
          
          // Create replacement with tag and message
          final replacement = 'Logger.$level($value, tag: \'$fileName\');';
          content = content.replaceAll(match.group(0)!, replacement);
          occurrencesReplaced++;
          fileModified = true;
          
          // Cycle through levels for more variation if needed
          currentLevel = (currentLevel + 1) % loggingLevels.length;
        }
      }
      
      // Add the import if needed and file was modified
      if (fileModified && !hasLoggerImport) {
        const importStatement = "import 'package:slotted/utils/logger.dart';\n";
        
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
        print('Fixed print statements in: ${entity.path}');
      }
    }
  }
  
  print('\nSummary:');
  print('- Files modified: $filesModified');
  print('- Occurrences replaced: $occurrencesReplaced');
  print('\nNext steps:');
  print('1. Run flutter analyze to check if all warnings are resolved');
  print('2. Review the changes to ensure they work correctly');
} 