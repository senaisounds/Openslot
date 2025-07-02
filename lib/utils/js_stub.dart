/// Stub implementation of JavaScript functionality for non-web platforms
/// 
/// This stub allows the app to compile for mobile platforms while
/// still using web-specific code when running on web.
library;

/// Stub context class
class JSContext {
  bool hasProperty(String name) => false;
  
  dynamic operator [](String key) => JSStub();
  
  dynamic callMethod(String method, [List<dynamic>? args]) => null;
}

/// Stub for nested JS objects
class JSStub {
  bool hasProperty(String name) => false;
  
  dynamic operator [](String key) => JSStub();
}

/// Global context stub
final context = JSContext();

/// Check if simple autocomplete is available (always false for mobile)
bool hasSimpleAutocomplete() => false; 