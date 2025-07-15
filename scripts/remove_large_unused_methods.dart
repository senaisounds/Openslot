import 'dart:io';

/// Script to remove large unused methods that are taking up significant space
void main() async {
  print('🎯 Removing large unused methods to optimize codebase...\n');
  
  await _removeLargeUnusedMethods();
  
  print('\n✅ Large method cleanup complete!');
  print('💡 Next steps:');
  print('   1. Run: flutter analyze');
  print('   2. Run: flutter build --release');
  print('   3. Test app functionality');
}

Future<void> _removeLargeUnusedMethods() async {
  // Define files and their large unused methods
  final methodsToRemove = {
    'lib/pages/my_home_page.dart': [
      '_buildEventCard',
      '_buildTimeAndDuration', 
      '_shouldShowEvent',
      '_addToCalendar',
      '_buildHostInfo',
      '_buildActionButton',
      '_buildProfileIcon',
      '_buildAttendeesAvatars',
      '_getCurrentLocation',
      '_showHomeViewIndicator',
      '_selectEvent',
      '_toggleFavorite',
      '_reserveAction',
      '_enhanceEventCardWithGestures'
    ],
    'lib/pages/event_details.dart': [
      '_showErrorState',
      '_buildCompactRulesView',
      '_buildFullRulesView',
      '_toggleEventReminder'
    ],
    'lib/pages/events_map_page.dart': [
      '_buildCachedEventMarker',
      '_showNearbyEvents', 
      '_toggleSearchBar',
      '_toggleFilters',
      '_resetFilters',
      '_handleReserve',
      '_prefetchMapTiles'
    ],
    'lib/pages/live.dart': [
      '_updateEventState',
      '_removePerformer',
      '_handlePerformerTap',
      '_handleCriticalError',
      '_onScroll',
      '_scrollToTopSmoothly',
      '_loadMorePerformers',
      '_runProfileLoadingDiagnostics'
    ],
    'lib/pages/main_nav.dart': [
      '_buildConfig',
      '_buildTabItem',
      '_buildNavigationTitle',
      '_openNotifications',
      '_openSettings',
      '_showErrorDialog'
    ],
    'lib/pages/event_chat.dart': [
      '_setupTypingListener',
      '_updateLastSeen',
      '_buildTypingIndicator'
    ]
  };
  
  for (final entry in methodsToRemove.entries) {
    final filePath = entry.key;
    final methods = entry.value;
    
    await _removeMethodsFromFile(filePath, methods);
  }
}

Future<void> _removeMethodsFromFile(String filePath, List<String> methodNames) async {
  final file = File(filePath);
  if (!await file.exists()) {
    print('⚠️  File not found: $filePath');
    return;
  }
  
  String content = await file.readAsString();
  String originalContent = content;
  int removedMethods = 0;
  
  for (final methodName in methodNames) {
    // Pattern to match method definitions including their entire body
    final methodPattern = RegExp(
      r'\s*(?:\/\/[^\n]*\n\s*)*' r'(?:@[^\n]*\n\s*)*' r'(?:static\s+)?' r'(?:Future<[^>]*>\s*|[A-Za-z_][A-Za-z0-9_<>,\s]*\s+)?' + // Return type
      RegExp.escape(methodName) + 
      r'\s*\([^{]*\)\s*(?:async\s*)?\s*\{', // Method signature
      multiLine: true,
      dotAll: true
    );
    
    final match = methodPattern.firstMatch(content);
    if (match != null) {
      final startIndex = match.start;
      final methodStart = match.end - 1; // Position of opening brace
      
      // Find the matching closing brace
      int braceCount = 1;
      int currentIndex = methodStart + 1;
      
      while (currentIndex < content.length && braceCount > 0) {
        if (content[currentIndex] == '{') {
          braceCount++;
        } else if (content[currentIndex] == '}') {
          braceCount--;
        }
        currentIndex++;
      }
      
      if (braceCount == 0) {
        // Remove the entire method including comments
        final methodText = content.substring(startIndex, currentIndex);
        content = content.replaceFirst(methodText, '');
        removedMethods++;
      }
    }
  }
  
  if (removedMethods > 0) {
    // Clean up any double newlines that might have been created
    content = content.replaceAll(RegExp(r'\n\n\n+'), '\n\n');
    
    await file.writeAsString(content);
    print('✅ $filePath: Removed $removedMethods unused methods');
    
    // Calculate space saved
    final spaceSaved = originalContent.length - content.length;
    print('   📦 Space saved: $spaceSaved characters');
  } else {
    print('ℹ️  $filePath: No methods found to remove');
  }
} 