// Performance Monitoring Helper
// Add this to debug performance issues

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  static bool _enabled = false;
  static bool _initialized = false;

  /// Initialize the performance monitor
  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    
    if (kDebugMode) {
      print('🔧 PerformanceMonitor initialized');
    }
  }

  /// Enable or disable performance monitoring
  static void setEnabled(bool enabled) {
    _enabled = enabled;
    if (kDebugMode) {
      print('🎯 PerformanceMonitor ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Track frame performance for operations
  static void trackFramePerformance(String operation) {
    if (_enabled && kDebugMode) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        print('🎯 Frame completed for: $operation');
      });
    }
  }
  
  /// Track memory usage for components
  static void trackMemoryUsage(String component) {
    if (_enabled && kDebugMode) {
      print('💾 Memory check for: $component');
    }
  }

  /// Check if monitoring is enabled
  static bool get isEnabled => _enabled;

  /// Check if monitor is initialized
  static bool get isInitialized => _initialized;
}
