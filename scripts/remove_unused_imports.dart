import 'dart:io';

/// A script to automatically remove unused imports from Dart files
void main() async {
  print('Removing unused imports from the codebase...');
  
  // Parse the unused code report
  final reportFile = File('unused_code_report.md');
  if (!await reportFile.exists()) {
    print('Error: unused_code_report.md not found. Run remove_unused_code.dart first.');
    return;
  }
  
  final reportContent = await reportFile.readAsString();
  
  // Extract the unused imports section
  final importsRegex = RegExp(r'== Unused Imports ==([\s\S]*?)(?=\n==|$)');
  final importsMatch = importsRegex.firstMatch(reportContent);
  
  if (importsMatch == null) {
    print('No unused imports found in the report.');
    return;
  }
  
  final importsSection = importsMatch.group(1)!;
  
  // Parse the imports section to get file-to-imports mapping
  final filePattern = RegExp(r'(lib/[^:]+):\s*');
  final importPattern = RegExp(r'- (.+)');
  
  final Map<String, List<String>> fileToImports = {};
  String? currentFile;
  
  for (final line in importsSection.split('\n')) {
    final fileMatch = filePattern.firstMatch(line);
    if (fileMatch != null) {
      currentFile = fileMatch.group(1);
      fileToImports[currentFile!] = [];
    } else {
      final importMatch = importPattern.firstMatch(line);
      if (importMatch != null && currentFile != null) {
        fileToImports[currentFile]!.add(importMatch.group(1)!);
      }
    }
  }
  
  // Remove the unused imports from each file
  int filesModified = 0;
  int importsRemoved = 0;
  
  for (final entry in fileToImports.entries) {
    final filePath = entry.key;
    final imports = entry.value;
    
    if (imports.isEmpty) continue;
    
    final file = File(filePath);
    if (!await file.exists()) {
      print('Warning: File not found: $filePath');
      continue;
    }
    
    String content = await file.readAsString();
    bool fileModified = false;
    
    for (final importStr in imports) {
      // Escape special characters in the import string for regex
      final escapedImport = RegExp.escape(importStr);
      // Create a pattern that matches the entire import line
      final importLinePattern = RegExp(r"import\s+'" + escapedImport + r"';\s*\n?");
      
      // Check if the pattern is found in the content
      if (importLinePattern.hasMatch(content)) {
        content = content.replaceAll(importLinePattern, '');
        importsRemoved++;
        fileModified = true;
        print('Removed import: $importStr from $filePath');
      } else {
        // Try with double quotes
        final doubleQuotePattern = RegExp(r'import\s+"' + escapedImport + r'";\s*\n?');
        if (doubleQuotePattern.hasMatch(content)) {
          content = content.replaceAll(doubleQuotePattern, '');
          importsRemoved++;
          fileModified = true;
          print('Removed import: $importStr from $filePath');
        } else {
          print('Warning: Could not find import line for $importStr in $filePath');
        }
      }
    }
    
    // Write the updated content back to the file
    if (fileModified) {
      // Remove any double newlines that might have been created
      content = content.replaceAll(RegExp(r'\n\n\n+'), '\n\n');
      await file.writeAsString(content);
      filesModified++;
    }
  }
  
  print('\nSummary:');
  print('- Files modified: $filesModified');
  print('- Imports removed: $importsRemoved');
} 