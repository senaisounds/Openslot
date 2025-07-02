/// Stub implementation of JavaScript util functionality for non-web platforms
/// 
/// This stub allows the app to compile for mobile platforms while
/// still using web-specific code when running on web.
library;

/// Stub for promiseToFuture
Future<dynamic> promiseToFuture(dynamic jsPromise) {
  return Future.value(null);
} 