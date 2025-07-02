import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:slotted/utils/logger.dart';

/// Custom cache manager to fix read-only database issues and provide better control over caching
class CustomCacheManager {
  static const key = 'slottedCacheKey';
  static late CacheManager instance;
  
  /// Initialize the custom cache manager
  /// [basePath] is the base directory path where cache files will be stored
  static Future<void> init([String? basePath]) async {
    try {
      // Create a simpler configuration that will work across platforms
      // Use a configuration that avoids database permission issues
      instance = CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 14),
          maxNrOfCacheObjects: 200,
          // Use a simpler file service that doesn't require database writes
          fileService: HttpFileService(),
        ),
      );
      
      Logger.d('CustomCacheManager initialized successfully');
    } catch (e) {
      // Fallback to an even simpler config if there's an error
      Logger.e('Error initializing CustomCacheManager: $e');
      try {
        // Try with minimal configuration
        instance = CacheManager(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
          ),
        );
        Logger.d('CustomCacheManager initialized with fallback config');
      } catch (fallbackError) {
        Logger.e('Fallback cache manager also failed: $fallbackError');
        // Use default cache manager as last resort
        instance = DefaultCacheManager();
        Logger.d('Using DefaultCacheManager as last resort');
      }
    }
  }
  
  /// Prefetch and cache an image for faster loading
  static Future<void> prefetchImage(String url) async {
    if (url.isEmpty) return;
    
    try {
      await instance.getSingleFile(url);
      Logger.d('Prefetched image: $url', tag: 'CacheManager');
    } catch (e) {
      Logger.e('Failed to prefetch image: $e', tag: 'CacheManager', error: e);
    }
  }
  
  /// Clear the cache
  static Future<void> clearCache() async {
    await instance.emptyCache();
    Logger.d('Cache cleared');
  }
  
  /// Get the size of the cache in bytes
  static Future<int> getCacheSize() async {
    if (kIsWeb) return 0;
    
    try {
      int totalSize = 0;
      final cacheDir = await path_provider.getTemporaryDirectory();
      final slottedCacheDir = Directory('${cacheDir.path}/slotted_cache');
      
      if (await slottedCacheDir.exists()) {
        await for (final file in slottedCacheDir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            final stat = await file.stat();
            totalSize += stat.size;
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      Logger.e('Error getting cache size: $e');
      return 0;
    }
  }
} 