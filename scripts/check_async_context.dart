import 'dart:io';

void main() async {
  // Get all Dart files in the lib directory
  final libDir = Directory('lib');
  final dartFiles = await _findDartFiles(libDir);
  
  // Track files with potential async context issues
  final filesWithIssues = <String, List<_AsyncContextIssue>>{};
  
  for (final file in dartFiles) {
    final content = await File(file).readAsString();
    final lines = content.split('\n');
    
    final issues = <_AsyncContextIssue>[];
    
    // Find async methods that use BuildContext
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Check for method declarations with both async and BuildContext
      if (_isAsyncMethodWithContext(line)) {
        // Extract method name
        final methodNameMatch = RegExp(r'(?:void|Future|FutureOr)\s+(\w+)').firstMatch(line);
        final methodName = methodNameMatch?.group(1) ?? 'unknown';
        
        // Find the end of the method
        int methodEndLine = _findMethodEnd(lines, i);
        
        // Check for context usage after await
        final contextUsageAfterAwait = _findContextUsageAfterAwait(lines, i, methodEndLine);
        
        if (contextUsageAfterAwait.isNotEmpty) {
          issues.add(_AsyncContextIssue(
            methodName: methodName,
            methodStartLine: i + 1,
            methodEndLine: methodEndLine + 1,
            contextUsageLines: contextUsageAfterAwait,
          ));
        }
      }
    }
    
    if (issues.isNotEmpty) {
      filesWithIssues[file] = issues;
    }
  }
  
  // Print results
  print('=== BuildContext Usage Across Async Gaps Report ===\n');
  
  if (filesWithIssues.isEmpty) {
    print('No BuildContext usage across async gaps found! 🎉');
    return;
  }
  
  int totalIssues = 0;
  
  print('Detailed report by file:');
  for (final file in filesWithIssues.keys) {
    final issues = filesWithIssues[file]!;
    totalIssues += issues.length;
    
    print('\n$file: ${issues.length} potential issues');
    
    for (final issue in issues) {
      print('\n  Method: ${issue.methodName} (lines ${issue.methodStartLine}-${issue.methodEndLine})');
      print('  Potential unsafe context usage after await:');
      
      for (final usage in issue.contextUsageLines) {
        print('    - Line ${usage.lineNumber}: ${usage.lineContent.trim()}');
      }
      
      print('  Suggestion: Store necessary values before await or check if mounted after await');
    }
  }
  
  print('\nTotal potential issues: $totalIssues');
  print('\nNote: This is a heuristic analysis and may include false positives.');
  print('Review each case manually to determine if it\'s actually problematic.');
  print('\nCommon fixes:');
  print('1. Store values from context before await: final theme = Theme.of(context);');
  print('2. Check if widget is still mounted: if (!mounted) return;');
  print('3. Use a state management solution that doesn\'t rely on BuildContext');
}

bool _isAsyncMethodWithContext(String line) {
  return line.contains('async') && 
         line.contains('BuildContext') && 
         (line.contains('void') || line.contains('Future'));
}

int _findMethodEnd(List<String> lines, int startLine) {
  int bracketCount = 0;
  bool methodStarted = false;
  
  for (int i = startLine; i < lines.length; i++) {
    final line = lines[i];
    
    // Count opening brackets
    for (int j = 0; j < line.length; j++) {
      if (line[j] == '{') {
        methodStarted = true;
        bracketCount++;
      } else if (line[j] == '}') {
        bracketCount--;
      }
    }
    
    // If we've started the method and bracket count is 0, we've found the end
    if (methodStarted && bracketCount == 0) {
      return i;
    }
  }
  
  // If we can't find the end, return the last line
  return lines.length - 1;
}

List<_ContextUsage> _findContextUsageAfterAwait(List<String> lines, int startLine, int endLine) {
  final contextUsages = <_ContextUsage>[];
  bool awaitFound = false;
  
  for (int i = startLine; i <= endLine; i++) {
    final line = lines[i];
    
    // Check for await
    if (!awaitFound && line.contains('await')) {
      awaitFound = true;
      continue;
    }
    
    // After await, check for context usage
    if (awaitFound) {
      if (_containsContextUsage(line)) {
        contextUsages.add(_ContextUsage(
          lineNumber: i + 1,
          lineContent: line,
        ));
      }
    }
  }
  
  return contextUsages;
}

bool _containsContextUsage(String line) {
  final contextPatterns = [
    r'context\.',
    r'of\(context',
    r'Theme\.of\(context',
    r'MediaQuery\.of\(context',
    r'Navigator\.of\(context',
    r'Scaffold\.of\(context',
    r'ScaffoldMessenger\.of\(context',
    r'Provider\.of<[^>]+>\(context',
    r'showDialog\([^)]*context:',
    r'showModalBottomSheet\([^)]*context:',
    r'showCupertinoDialog\([^)]*context:',
  ];
  
  for (final pattern in contextPatterns) {
    if (RegExp(pattern).hasMatch(line)) {
      return true;
    }
  }
  
  return false;
}

Future<List<String>> _findDartFiles(Directory directory) async {
  final files = <String>[];
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity.path);
    }
  }
  return files;
}

class _AsyncContextIssue {
  final String methodName;
  final int methodStartLine;
  final int methodEndLine;
  final List<_ContextUsage> contextUsageLines;
  
  _AsyncContextIssue({
    required this.methodName,
    required this.methodStartLine,
    required this.methodEndLine,
    required this.contextUsageLines,
  });
}

class _ContextUsage {
  final int lineNumber;
  final String lineContent;
  
  _ContextUsage({
    required this.lineNumber,
    required this.lineContent,
  });
} 