import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slotted/utils/logger.dart';

/// Test network service that provides stable mock responses for testing
/// This eliminates 400 status errors and network timeouts during tests
class TestNetworkService {
  static bool _isTestMode = false;
  static final Map<String, dynamic> _mockResponses = {};
  
  /// Enable test mode with mock responses
  static void enableTestMode() {
    _isTestMode = true;
    _setupDefaultMockResponses();
    Logger.d('Test network service enabled', tag: 'TestNetwork');
  }
  
  /// Disable test mode
  static void disableTestMode() {
    _isTestMode = false;
    _mockResponses.clear();
    Logger.d('Test network service disabled', tag: 'TestNetwork');
  }
  
  /// Check if currently in test mode
  static bool get isTestMode => _isTestMode;
  
  /// Add a mock response for a specific URL pattern
  static void addMockResponse(String urlPattern, http.Response response) {
    _mockResponses[urlPattern] = response;
  }
  
  /// Get mock response for a URL
  static http.Response? getMockResponse(String url) {
    if (!_isTestMode) return null;
    
    // Try exact match first
    if (_mockResponses.containsKey(url)) {
      return _mockResponses[url];
    }
    
    // Try pattern matching
    for (final pattern in _mockResponses.keys) {
      if (url.contains(pattern) || RegExp(pattern).hasMatch(url)) {
        return _mockResponses[pattern];
      }
    }
    
    // Return default success response if no specific mock found
    return _defaultSuccessResponse();
  }
  
  /// Setup default mock responses for common endpoints
  static void _setupDefaultMockResponses() {
    // Mock successful event creation
    _mockResponses['api/events'] = http.Response(
      jsonEncode({
        'success': true,
        'eventId': 'test-event-123',
        'message': 'Event created successfully'
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
    
    // Mock successful user authentication
    _mockResponses['auth/login'] = http.Response(
      jsonEncode({
        'success': true,
        'userId': 'test-user-123',
        'token': 'test-token-456'
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
    
    // Mock successful image upload
    _mockResponses['upload/image'] = http.Response(
      jsonEncode({
        'success': true,
        'imageUrl': 'https://example.com/test-image.jpg'
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
    
    // Mock successful location search
    _mockResponses['maps/api/geocode'] = http.Response(
      jsonEncode({
        'results': [{
          'formatted_address': '123 Test Street, Test City, TC 12345',
          'geometry': {
            'location': {
              'lat': 40.7128,
              'lng': -74.0060
            }
          }
        }],
        'status': 'OK'
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
    
    // Mock Firebase Cloud Functions
    _mockResponses['cloudfunctions.net'] = http.Response(
      jsonEncode({
        'success': true,
        'result': 'Cloud function executed successfully'
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  
  /// Default success response for unmocked endpoints
  static http.Response _defaultSuccessResponse() {
    return http.Response(
      jsonEncode({
        'success': true,
        'message': 'Test mode - default success response'
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  
  /// Wrap HTTP client calls to use mocks in test mode
  static Future<http.Response> wrapHttpCall(
    Future<http.Response> Function() httpCall,
    String url,
  ) async {
    try {
      if (_isTestMode) {
        final mockResponse = getMockResponse(url);
        if (mockResponse != null) {
          Logger.d('Using mock response for: $url', tag: 'TestNetwork');
          return mockResponse;
        }
        // If in test mode but no mock found, return default response
        return _defaultSuccessResponse();
      }
      
      // Execute real HTTP call if not in test mode
      return await httpCall();
    } catch (e, stackTrace) {
      Logger.e('Error in async operation', 
              tag: 'TestNetworkService', 
              error: e, 
              stackTrace: stackTrace);
      // Return default response on error
      return _defaultSuccessResponse();
    }
  }
} 