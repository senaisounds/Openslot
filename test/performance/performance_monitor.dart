import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Performance monitoring utility for OpenSlot app
class PerformanceMonitor {
  static final Map<String, List<double>> _metrics = {};
  static final Map<String, DateTime> _startTimes = {};
  static bool _isEnabled = true;

  /// Enable or disable performance monitoring
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Start measuring an operation
  static void startMeasurement(String operationName) {
    if (!_isEnabled) return;
    
    _startTimes[operationName] = DateTime.now();
    if (kDebugMode) {
      print('🚀 Starting measurement: $operationName');
    }
  }

  /// End measuring an operation and record the result
  static double endMeasurement(String operationName) {
    if (!_isEnabled) return 0.0;
    
    final startTime = _startTimes[operationName];
    if (startTime == null) {
      if (kDebugMode) {
        print('⚠️ Warning: No start time found for $operationName');
      }
      return 0.0;
    }

    final duration = DateTime.now().difference(startTime).inMilliseconds.toDouble();
    
    // Store the metric
    _metrics.putIfAbsent(operationName, () => []).add(duration);
    
    // Remove the start time
    _startTimes.remove(operationName);
    
    if (kDebugMode) {
      print('✅ Completed measurement: $operationName (${duration}ms)');
    }
    
    return duration;
  }

  /// Measure a synchronous operation
  static T measureSync<T>(String operationName, T Function() operation) {
    if (!_isEnabled) return operation();
    
    startMeasurement(operationName);
    try {
      final result = operation();
      endMeasurement(operationName);
      return result;
    } catch (e) {
      endMeasurement(operationName);
      rethrow;
    }
  }

  /// Measure an asynchronous operation
  static Future<T> measureAsync<T>(String operationName, Future<T> Function() operation) async {
    if (!_isEnabled) return await operation();
    
    startMeasurement(operationName);
    try {
      final result = await operation();
      endMeasurement(operationName);
      return result;
    } catch (e) {
      endMeasurement(operationName);
      rethrow;
    }
  }

  /// Get performance statistics for an operation
  static PerformanceStats? getStats(String operationName) {
    final measurements = _metrics[operationName];
    if (measurements == null || measurements.isEmpty) return null;

    final sortedMeasurements = List<double>.from(measurements)..sort();
    final count = measurements.length;
    final sum = measurements.reduce((a, b) => a + b);
    final average = sum / count;
    final min = sortedMeasurements.first;
    final max = sortedMeasurements.last;
    final median = count % 2 == 0
        ? (sortedMeasurements[count ~/ 2 - 1] + sortedMeasurements[count ~/ 2]) / 2
        : sortedMeasurements[count ~/ 2];
    final p95Index = ((count - 1) * 0.95).round();
    final p95 = sortedMeasurements[p95Index];

    return PerformanceStats(
      operationName: operationName,
      count: count,
      average: average,
      min: min,
      max: max,
      median: median,
      p95: p95,
      measurements: List.from(measurements),
    );
  }

  /// Get all performance statistics
  static Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};
    for (final operationName in _metrics.keys) {
      final operationStats = getStats(operationName);
      if (operationStats != null) {
        stats[operationName] = operationStats;
      }
    }
    return stats;
  }

  /// Clear all metrics
  static void clearMetrics() {
    _metrics.clear();
    _startTimes.clear();
  }

  /// Generate a performance report
  static String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Performance Report');
    buffer.writeln('=' * 50);
    
    final allStats = getAllStats();
    if (allStats.isEmpty) {
      buffer.writeln('No performance data available.');
      return buffer.toString();
    }

    // Sort by average duration (slowest first)
    final sortedStats = allStats.entries.toList()
      ..sort((a, b) => b.value.average.compareTo(a.value.average));

    for (final entry in sortedStats) {
      final stats = entry.value;
      buffer.writeln('\n🔍 ${stats.operationName}');
      buffer.writeln('   Count: ${stats.count}');
      buffer.writeln('   Average: ${stats.average.toStringAsFixed(2)}ms');
      buffer.writeln('   Min: ${stats.min.toStringAsFixed(2)}ms');
      buffer.writeln('   Max: ${stats.max.toStringAsFixed(2)}ms');
      buffer.writeln('   Median: ${stats.median.toStringAsFixed(2)}ms');
      buffer.writeln('   95th percentile: ${stats.p95.toStringAsFixed(2)}ms');
      
      // Performance rating
      final rating = _getPerformanceRating(stats.average);
      buffer.writeln('   Rating: $rating');
    }

    buffer.writeln('\n' + '=' * 50);
    return buffer.toString();
  }

  /// Get performance rating based on average duration
  static String _getPerformanceRating(double averageMs) {
    if (averageMs < 100) return '🟢 Excellent';
    if (averageMs < 500) return '🟡 Good';
    if (averageMs < 1000) return '🟠 Fair';
    return '🔴 Needs Improvement';
  }

  /// Monitor memory usage (iOS/Android specific)
  static Future<MemoryInfo> getMemoryInfo() async {
    try {
      final memoryInfo = await MethodChannel('performance_monitor')
          .invokeMethod<Map<dynamic, dynamic>>('getMemoryInfo');
      
      return MemoryInfo(
        usedMemoryMB: (memoryInfo?['usedMemory'] as num?)?.toDouble() ?? 0.0,
        totalMemoryMB: (memoryInfo?['totalMemory'] as num?)?.toDouble() ?? 0.0,
        availableMemoryMB: (memoryInfo?['availableMemory'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      // Fallback for platforms that don't support native memory monitoring
      return MemoryInfo(
        usedMemoryMB: 0.0,
        totalMemoryMB: 0.0,
        availableMemoryMB: 0.0,
      );
    }
  }

  /// Monitor frame rendering performance
  static void startFrameMonitoring() {
    if (!_isEnabled) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _monitorFrameCallback();
    });
  }

  static void _monitorFrameCallback() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toDouble();
    _metrics.putIfAbsent('frame_render', () => []).add(timestamp);
    
    // Keep only last 60 frames (1 second at 60fps)
    final frameMetrics = _metrics['frame_render']!;
    if (frameMetrics.length > 60) {
      frameMetrics.removeRange(0, frameMetrics.length - 60);
    }
    
    // Continue monitoring
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _monitorFrameCallback();
    });
  }

  /// Get frame rate information
  static FrameRateInfo getFrameRateInfo() {
    final frameMetrics = _metrics['frame_render'];
    if (frameMetrics == null || frameMetrics.length < 2) {
      return FrameRateInfo(fps: 0.0, frameCount: 0);
    }

    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    final oneSecondAgo = now - 1000;
    
    final recentFrames = frameMetrics.where((timestamp) => timestamp > oneSecondAgo).toList();
    final fps = recentFrames.length.toDouble();
    
    return FrameRateInfo(fps: fps, frameCount: recentFrames.length);
  }
}

/// Performance statistics for a specific operation
class PerformanceStats {
  final String operationName;
  final int count;
  final double average;
  final double min;
  final double max;
  final double median;
  final double p95;
  final List<double> measurements;

  PerformanceStats({
    required this.operationName,
    required this.count,
    required this.average,
    required this.min,
    required this.max,
    required this.median,
    required this.p95,
    required this.measurements,
  });

  @override
  String toString() {
    return 'PerformanceStats(operation: $operationName, avg: ${average.toStringAsFixed(2)}ms)';
  }
}

/// Memory usage information
class MemoryInfo {
  final double usedMemoryMB;
  final double totalMemoryMB;
  final double availableMemoryMB;

  MemoryInfo({
    required this.usedMemoryMB,
    required this.totalMemoryMB,
    required this.availableMemoryMB,
  });

  double get usagePercentage => totalMemoryMB > 0 ? (usedMemoryMB / totalMemoryMB) * 100 : 0.0;

  @override
  String toString() {
    return 'MemoryInfo(used: ${usedMemoryMB.toStringAsFixed(1)}MB, total: ${totalMemoryMB.toStringAsFixed(1)}MB, usage: ${usagePercentage.toStringAsFixed(1)}%)';
  }
}

/// Frame rate monitoring information
class FrameRateInfo {
  final double fps;
  final int frameCount;

  FrameRateInfo({required this.fps, required this.frameCount});

  String get performanceLevel {
    if (fps >= 55) return 'Excellent (60 FPS)';
    if (fps >= 25) return 'Good (30 FPS)';
    return 'Poor (< 30 FPS)';
  }

  @override
  String toString() {
    return 'FrameRateInfo(fps: ${fps.toStringAsFixed(1)}, level: $performanceLevel)';
  }
}
