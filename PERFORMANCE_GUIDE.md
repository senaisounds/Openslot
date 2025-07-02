# Slotted Performance Guide

This guide provides comprehensive information about performance optimization techniques, tools, and best practices for the Slotted application.

## Table of Contents

1. [Introduction](#introduction)
2. [Key Performance Metrics](#key-performance-metrics)
3. [Performance Tools](#performance-tools)
4. [Common Performance Issues](#common-performance-issues)
5. [Best Practices](#best-practices)
6. [Optimization Scripts](#optimization-scripts)
7. [Testing Performance](#testing-performance)

## Introduction

Performance is critical to the Slotted app experience. Poor performance can lead to:
- Reduced user engagement
- Higher user abandonment
- Negative reviews
- Higher battery consumption
- Poor user experience

This guide documents the tools and practices we've implemented to maintain high performance.

## Key Performance Metrics

We monitor the following key metrics:
- **Startup Time**: How long it takes for the app to become interactive
- **Frame Rate**: Maintaining a smooth 60fps scrolling and animation experience
- **Memory Usage**: Keeping memory consumption reasonable
- **Network Efficiency**: Minimizing network requests and payload sizes
- **Battery Impact**: Reducing CPU and network usage to save battery

## Performance Tools

We've developed several tools to help monitor and improve performance:

### 1. Performance Monitor

Located in `lib/utils/performance_monitor.dart`, this tool provides:
- Timing operations to identify bottlenecks
- Tracking of long-running operations
- Performance metrics for critical operations

Usage example:
```dart
// Start timing an operation
PerformanceMonitor.startOperation('fetch_events');

// ... perform the operation

// End timing
PerformanceMonitor.endOperation('fetch_events');

// Get statistics for an operation
final stats = PerformanceMonitor.getOperationStats('fetch_events');
```

### 2. Performance Optimizer

Located in `lib/utils/performance_optimizer.dart`, this tool offers:
- Image cache optimization
- Widget rendering optimizations
- BuildContext safety helpers
- Resource tracking

Usage example:
```dart
// Initialize performance optimizations
PerformanceOptimizer.initialize();

// Configure image cache
PerformanceOptimizer.configureImageCache(
  maxSize: 100,
  maxSizeBytes: 50 * 1024 * 1024
);

// Check context usage across async gaps
BuildContext safeContext = PerformanceOptimizer.checkContextBeforeAsyncGap(
  context,
  'showCalendarEvent'
);

// Safe context usage after async operation
if (PerformanceOptimizer.isSafeToUseContext(context, mounted, 'showCalendarDialog')) {
  showDialog(...);
}
```

### 3. Custom Cache Manager

Located in `lib/utils/custom_cache_manager.dart`, this tool provides:
- Efficient image caching
- Memory leak prevention
- Cross-platform cache optimization

Usage example:
```dart
// Initialize cache manager
await CustomCacheManager.init();

// Use with CachedNetworkImage
CachedNetworkImage(
  cacheManager: CustomCacheManager.instance,
  imageUrl: imageUrl,
  // ...
)
```

### 4. Error Boundary

Located in `lib/common/error_boundary.dart`, this widget prevents app crashes by:
- Catching errors in the widget tree
- Displaying fallback UI
- Logging errors for analytics

Usage example:
```dart
ErrorBoundary(
  fallback: const ErrorFallbackWidget(),
  child: MyWidgetThatMightFail(),
)
```

## Common Performance Issues

### 1. Deprecated API Usage

We've fixed several deprecated API usages:
- `withOpacity()` → Updated with our extension using `withValues()`
- Unsafe BuildContext usage across async gaps
- Color object manipulations with modern APIs

### 2. Memory Leaks

Common sources of memory leaks and how we prevent them:
- Unsubscribed stream subscriptions
- Unmounted widget state updates
- Uncancelled timers
- Large image caches

### 3. Jank and UI Freezes

Sources of UI jank and our solutions:
- Heavy computations on the UI thread → Moved to Isolates
- Excessive rebuilds → Implemented efficient state management
- Large image loading → Implemented proper caching and loading strategies
- Complex animations → Optimized with RepaintBoundary

## Best Practices

### 1. Widget Optimization

```dart
// DO: Use const constructors
const MyWidget(
  text: 'Hello',
)

// DON'T: Create new instances unnecessarily
MyWidget(
  text: 'Hello',
)
```

### 2. Image Optimization

```dart
// DO: Use optimized image loading
CachedNetworkImage(
  imageUrl: url,
  cacheManager: CustomCacheManager.instance,
  placeholder: (context, url) => const ShimmerImage(),
  errorWidget: (context, url, error) => const ErrorImage(),
)

// DON'T: Use raw Image.network without caching
Image.network(url)
```

### 3. State Management

```dart
// DO: Minimize rebuilds with proper state scoping
SomeProvider(
  child: ChildThatNeedsData(),
)

// DON'T: Wrap your entire app in every provider
MultiProvider(
  providers: [
    Provider1(),
    Provider2(),
    // ... dozens more
  ],
  child: MyApp(),
)
```

### 4. Async Operations

```dart
// DO: Use mounted checks with BuildContext
void handleLogin() async {
  PerformanceOptimizer.checkContextBeforeAsyncGap(context, "login");
  await authService.login();
  if (mounted) {
    Navigator.pushNamed(context, '/home');
  }
}

// DON'T: Use BuildContext after async operations without checks
void handleLogin() async {
  await authService.login();
  Navigator.pushNamed(context, '/home'); // May be unmounted!
}
```

## Optimization Scripts

We've created several optimization scripts to help maintain performance:

1. **fix_withopacity_usage.dart**: Fixes deprecated withOpacity calls
2. **replace_prints.dart**: Replaces print statements with proper logging
3. **remove_unused_code.dart**: Identifies unused variables and methods
4. **remove_unused_imports.dart**: Removes unused imports
5. **fix_async_context.dart**: Identifies unsafe BuildContext usage

To run these scripts:
```bash
# First generate a report of unused code
dart scripts/remove_unused_code.dart

# Clean up unused imports
dart scripts/remove_unused_imports.dart

# Fix withOpacity usage
dart scripts/fix_withopacity_usage.dart

# Replace print with logger
dart scripts/replace_prints.dart

# Find unsafe BuildContext usage
dart scripts/fix_async_context.dart
```

## Testing Performance

### 1. Performance Testing Framework

We've set up performance tests in `test/performance/`:
- Reservation performance test
- Startup time test
- Rendering performance test

### 2. Performance Profiling

How to profile the app's performance:
- Use Flutter DevTools
- Enable our PerformanceMonitor in debug builds
- Check the performance dashboard in Firebase

### 3. Benchmarking

Key benchmarks we aim to maintain:
- App startup under 2 seconds on mid-range devices
- Smooth 60fps scrolling in the events list
- Memory usage under 150MB during normal usage
- Network requests under 50KB for common operations

---

## Contributing

When contributing to Slotted, please:
1. Run the optimization scripts before submitting PRs
2. Fix any performance issues identified by the analyzer
3. Write performance tests for critical paths
4. Document performance considerations in the code

For questions about performance optimization, contact the team at developers@slotted.com 