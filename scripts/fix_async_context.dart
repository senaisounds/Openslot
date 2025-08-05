import 'dart:io';

/// A script to help fix BuildContext usage across async gaps
void main() async {
  print('Scanning for BuildContext across async gaps issues...');
  

  
  // Define patterns to search for
  final asyncBuildContextPattern = RegExp(r"info • Don't use 'BuildContext's across async gaps • ([^\•]+)");
  
  // Run flutter analyze and capture the output
  final analyzeResult = await Process.run('flutter', ['analyze']);
  final output = analyzeResult.stdout.toString();
  
  // Store the files with async BuildContext issues
  final problemFiles = <String, List<int>>{};
  
  // Process the output and extract async BuildContext information
  for (final line in output.split('\n')) {
    final matches = asyncBuildContextPattern.allMatches(line);
    for (final match in matches) {
      final location = match.group(1)!.trim();
      
      final parts = location.split(':');
      if (parts.length >= 3) {
        final filePath = parts[0];
        final lineNumber = int.tryParse(parts[1]);
        
        if (lineNumber != null) {
          if (!problemFiles.containsKey(filePath)) {
            problemFiles[filePath] = [];
          }
          
          if (!problemFiles[filePath]!.contains(lineNumber)) {
            problemFiles[filePath]!.add(lineNumber);
          }
        }
      }
    }
  }
  
  if (problemFiles.isEmpty) {
    print('No BuildContext across async gaps issues found.');
    return;
  }
  
  // Generate a report and fix instructions
  print('\nFound BuildContext async gap issues in ${problemFiles.length} files:');
  
  int totalIssues = 0;
  final fixInstructions = StringBuffer();
  
  fixInstructions.writeln('\n# BuildContext Async Gap Fixes\n');
  fixInstructions.writeln('## Problem Description\n');
  fixInstructions.writeln('Using a BuildContext after an async gap is unsafe because the widget might have been unmounted. ');
  fixInstructions.writeln('This can lead to bugs, memory leaks, and app crashes.\n');
  fixInstructions.writeln('## Recommended Fix Pattern\n');
  fixInstructions.writeln('```dart');
  fixInstructions.writeln('// Before fixing:');
  fixInstructions.writeln('void someMethod(BuildContext context) async {');
  fixInstructions.writeln('  await someAsyncOperation();');
  fixInstructions.writeln('  Navigator.of(context).pop(); // UNSAFE! Widget might be unmounted');
  fixInstructions.writeln('}');
  fixInstructions.writeln('');
  fixInstructions.writeln('// After fixing:');
  fixInstructions.writeln('void someMethod(BuildContext context) async {');
  fixInstructions.writeln('  // Use our utility to document the context use');
  fixInstructions.writeln('  PerformanceOptimizer.checkContextBeforeAsyncGap(context, "someMethod");');
  fixInstructions.writeln('  await someAsyncOperation();');
  fixInstructions.writeln('  // Check if still mounted before using context');
  fixInstructions.writeln('  if (mounted) {');
  fixInstructions.writeln('    Navigator.of(context).pop(); // Now safe');
  fixInstructions.writeln('  }');
  fixInstructions.writeln('}');
  fixInstructions.writeln('```\n');
  
  fixInstructions.writeln('## Issues Found\n');
  
  for (final entry in problemFiles.entries) {
    final filePath = entry.key;
    final lines = entry.value;
    totalIssues += lines.length;
    
    print(' - $filePath: ${lines.length} issue(s)');
    
    fixInstructions.writeln('### $filePath\n');
    
    // Read the file to get context for each issue
    final file = File(filePath);
    if (await file.exists()) {
      final fileLines = await file.readAsLines();
      
      for (final lineNumber in lines) {
        if (lineNumber > 0 && lineNumber <= fileLines.length) {
          final lineIndex = lineNumber - 1;
          
          // Get the problematic line and a bit of context
          final startIndex = lineIndex > 3 ? lineIndex - 3 : 0;
          final endIndex = lineIndex + 3 < fileLines.length ? lineIndex + 3 : fileLines.length - 1;
          
          fixInstructions.writeln('Line $lineNumber:');
          fixInstructions.writeln('```dart');
          
          for (int i = startIndex; i <= endIndex; i++) {
            if (i == lineIndex) {
              fixInstructions.writeln('${i+1}:  ${fileLines[i]} // <-- UNSAFE CONTEXT USAGE');
            } else {
              fixInstructions.writeln('${i+1}:  ${fileLines[i]}');
            }
          }
          
          fixInstructions.writeln('```\n');
          
          // Try to detect the context of the issue
          final line = fileLines[lineIndex];
          if (line.contains('Navigator.of(context)') || line.contains('context).push') || line.contains('context).pop')) {
            fixInstructions.writeln('Fix suggestion: Add `if (mounted)` check before using Navigator.\n');
          } else if (line.contains('showDialog') || line.contains('showModalBottomSheet')) {
            fixInstructions.writeln('Fix suggestion: Add `if (mounted)` check before showing a dialog or bottom sheet.\n');
          } else if (line.contains('SnackBar') || line.contains('ScaffoldMessenger')) {
            fixInstructions.writeln('Fix suggestion: Check `mounted` before using ScaffoldMessenger or showing a SnackBar.\n');
          } else {
            fixInstructions.writeln('Fix suggestion: Add `if (mounted)` check before using the context after the async operation.\n');
          }
        }
      }
    }
  }
  
  // Write the fix instructions to a file
  final fixFile = File('context_async_fixes.md');
  await fixFile.writeAsString(fixInstructions.toString());
  
  print('\nSummary:');
  print('- Files with issues: ${problemFiles.length}');
  print('- Total issues: $totalIssues');
  print('\nDetailed fix instructions have been written to: context_async_fixes.md');
  print('Use the PerformanceOptimizer.checkContextBeforeAsyncGap and isSafeToUseContext methods to fix these issues.');
} 