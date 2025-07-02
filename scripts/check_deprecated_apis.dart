import 'dart:io';

void main() async {
  // Get all Dart files in the lib directory
  final libDir = Directory('lib');
  final dartFiles = await _findDartFiles(libDir);
  
  // Define patterns for common deprecated APIs
  final deprecatedApis = <String, Map<String, dynamic>>{
    'withOpacity': {
      'pattern': r'\.withOpacity\(',
      'suggestion': 'Use .withAlpha() or Color.fromRGBO with alpha parameter instead',
      'count': 0,
    },
    'RaisedButton': {
      'pattern': r'RaisedButton\(',
      'suggestion': 'Use ElevatedButton instead',
      'count': 0,
    },
    'FlatButton': {
      'pattern': r'FlatButton\(',
      'suggestion': 'Use TextButton instead',
      'count': 0,
    },
    'OutlineButton': {
      'pattern': r'OutlineButton\(',
      'suggestion': 'Use OutlinedButton instead',
      'count': 0,
    },
    'InputDecoration.hasFloatingPlaceholder': {
      'pattern': r'hasFloatingPlaceholder:',
      'suggestion': 'Use floatingLabelBehavior instead',
      'count': 0,
    },
    'CupertinoColors.activeBlue': {
      'pattern': r'CupertinoColors\.activeBlue',
      'suggestion': 'Use CupertinoColors.systemBlue instead',
      'count': 0,
    },
    'BuildContext.ancestorStateOfType': {
      'pattern': r'ancestorStateOfType\(',
      'suggestion': 'Use findAncestorStateOfType instead',
      'count': 0,
    },
    'BuildContext.ancestorWidgetOfExactType': {
      'pattern': r'ancestorWidgetOfExactType\(',
      'suggestion': 'Use findAncestorWidgetOfExactType instead',
      'count': 0,
    },
    'showDialog.child': {
      'pattern': r'showDialog\([^)]*child:',
      'suggestion': 'Use builder parameter instead of child',
      'count': 0,
    },
  };
  
  // Track files with deprecated APIs
  final filesWithDeprecatedApis = <String, Map<String, List<int>>>{};
  
  for (final file in dartFiles) {
    final content = await File(file).readAsString();
    final lines = content.split('\n');
    
    final fileDeprecations = <String, List<int>>{};
    
    // Check each line for deprecated APIs
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      for (final api in deprecatedApis.keys) {
        final pattern = RegExp(deprecatedApis[api]!['pattern'] as String);
        if (pattern.hasMatch(line)) {
          deprecatedApis[api]!['count'] = (deprecatedApis[api]!['count'] as int) + 1;
          
          if (!fileDeprecations.containsKey(api)) {
            fileDeprecations[api] = [];
          }
          fileDeprecations[api]!.add(i + 1); // +1 for 1-indexed line numbers
        }
      }
    }
    
    if (fileDeprecations.isNotEmpty) {
      filesWithDeprecatedApis[file] = fileDeprecations;
    }
  }
  
  // Print results
  print('=== Deprecated API Usage Report ===\n');
  
  if (filesWithDeprecatedApis.isEmpty) {
    print('No deprecated APIs found! 🎉');
    return;
  }
  
  // Print summary by API
  print('Summary by API:');
  for (final api in deprecatedApis.keys) {
    final count = deprecatedApis[api]!['count'] as int;
    if (count > 0) {
      print('- $api: $count occurrences');
      print('  Suggestion: ${deprecatedApis[api]!['suggestion']}');
    }
  }
  
  print('\nDetailed report by file:');
  for (final file in filesWithDeprecatedApis.keys) {
    print('\n$file:');
    
    for (final api in filesWithDeprecatedApis[file]!.keys) {
      final lines = filesWithDeprecatedApis[file]![api]!;
      print('- $api: ${lines.length} occurrences (lines: ${lines.join(', ')})');
      print('  Suggestion: ${deprecatedApis[api]!['suggestion']}');
    }
  }
  
  // Print total count
  final totalCount = deprecatedApis.values
      .map((api) => api['count'] as int)
      .reduce((a, b) => a + b);
  
  print('\nTotal deprecated API usages: $totalCount');
  print('\nRun "flutter analyze" for more detailed warnings.');
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