import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:slotted/utils/logger.dart';
import 'package:slotted/utils/performance_monitor.dart';

/// A utility class for optimizing app performance
class PerformanceOptimizer {
  // Settings
  static bool _initialized = false;
  static bool _enableGpuTelemetry = false;
  static const bool _disableOverdraw = true;
  static const bool _disableClipLayers = false;
  static const bool _enableLayoutTimeTracking = false;
  static int _maxImageCacheSize = 50;
  static int _maxImageCacheSizeBytes = 50 * 1024 * 1024; // 50 MB
  
  /// Initialize performance optimization settings
  static void initialize() {
    if (_initialized) return;
    
    try {
      Logger.d('Initializing PerformanceOptimizer', tag: 'Performance');
      
      // Initialize performance monitoring
      PerformanceMonitor.initialize();
      
      // Configure image caching
      PaintingBinding.instance.imageCache.maximumSize = _maxImageCacheSize;
      PaintingBinding.instance.imageCache.maximumSizeBytes = _maxImageCacheSizeBytes;
      
      // Enable strict render view in debug mode
      if (kDebugMode) {
        // Debug rendering optimizations
        debugPaintSizeEnabled = false;
        debugPaintBaselinesEnabled = false;
        debugPaintLayerBordersEnabled = false;
        debugRepaintRainbowEnabled = false;
        
        // Disable various debug features that impact performance
        debugProfileBuildsEnabled = false;
        debugProfilePaintsEnabled = _enableGpuTelemetry;
        
        // Disable overdraw visualization
        if (_disableOverdraw) {
          debugDisableClipLayers = _disableClipLayers;
          debugDisablePhysicalShapeLayers = true;
        }
      }
      
      // Configure system UI settings for better performance
      SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
        return;
      });
      
      // Set release-mode only optimizations
      if (!kDebugMode) {
        // Any release-mode specific settings
      }
      
      // Enable layout time tracking if needed
      if (_enableLayoutTimeTracking) {
        debugProfileLayoutsEnabled = true;
        debugEnhanceLayoutTimelineArguments = true;
      }
      
      Logger.d('PerformanceOptimizer initialized successfully', tag: 'Performance');
      _initialized = true;
    } catch (e, stack) {
      Logger.e('Error initializing PerformanceOptimizer: $e', error: e, stackTrace: stack, tag: 'Performance');
    }
  }
  
  /// Update image cache size settings
  static void setImageCacheSize(int maxSize, int maxSizeBytes) {
    _maxImageCacheSize = maxSize;
    _maxImageCacheSizeBytes = maxSizeBytes;
    
    // Update the actual cache
    PaintingBinding.instance.imageCache.maximumSize = maxSize;
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxSizeBytes;
    
    Logger.d('Updated image cache size: $maxSize items, ${maxSizeBytes ~/ (1024 * 1024)}MB', tag: 'Performance');
  }
  
  /// Clear image cache
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    Logger.d('Image cache cleared', tag: 'Performance');
  }
  
  /// Enable or disable GPU telemetry
  static void setEnableGpuTelemetry(bool enable) {
    _enableGpuTelemetry = enable;
    
    if (kDebugMode) {
      debugProfilePaintsEnabled = enable;
    }
    
    Logger.d('GPU telemetry ${enable ? 'enabled' : 'disabled'}', tag: 'Performance');
  }
  
  /// Optimize a widget for better performance
  static Widget optimizeWidget(Widget widget) {
    // Here you could apply performance optimizations to widgets
    // such as wrapping with RepaintBoundary for complex widgets
    // or using const constructors where appropriate
    
    return widget;
  }
  
  /// Create a performance-optimized image widget
  static Widget optimizedImage(Widget imageWidget) {
    // Wrap the image widget with RepaintBoundary to prevent unnecessary repaints
    return RepaintBoundary(
      child: imageWidget,
    );
  }
  
  /// Optimize list performance
  static Widget optimizeList(Widget listWidget) {
    // Apply list-specific optimizations
    return listWidget;
  }
  
  /// Create a repaint boundary to improve rendering performance
  static Widget createRepaintBoundary(Widget child) {
    return RepaintBoundary(
      child: child,
    );
  }
  
  /// Check if a BuildContext is valid and safely use it across async gaps
  /// 
  /// This is a utility method that should be used to document and improve code that uses
  /// BuildContext across async operations. It doesn't actually prevent the issue but 
  /// helps track places that need proper mounted checks.
  /// 
  /// @param context The BuildContext to check
  /// @param operation A description of the operation being performed
  /// @returns The same context (for chaining)
  static BuildContext checkContextBeforeAsyncGap(BuildContext context, String operation) {
    if (kDebugMode) {
      Logger.d('Context used before async gap in operation: $operation', tag: 'ContextUsage');
    }
    return context;
  }
  
  /// Safely use BuildContext after an async operation
  /// 
  /// @param context The BuildContext to check
  /// @param mounted Whether the widget is still mounted
  /// @param operation A description of the operation being performed
  /// @returns true if the context is safe to use, false otherwise
  static bool isSafeToUseContext(BuildContext? context, bool mounted, String operation) {
    final isSafe = context != null && mounted;
    
    if (kDebugMode && !isSafe) {
      Logger.w('Prevented unsafe context use after async gap in: $operation', tag: 'ContextUsage');
    }
    
    return isSafe;
  }
  
  /// Helper to track potential memory leaks from subscriptions, controllers, etc.
  /// 
  /// @param objectType The type of object being tracked (e.g., "StreamSubscription")
  /// @param identifier A unique identifier for the object
  /// @param action The action being taken (e.g., "created", "disposed")
  static void trackResourceUsage(String objectType, String identifier, String action) {
    if (kDebugMode) {
      Logger.d('$objectType [$identifier] $action', tag: 'ResourceTracking');
    }
  }
} 