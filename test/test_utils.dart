import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'test_config.dart';

/// Test utilities for OpenSlot app
class TestUtils {
  /// Create a mock HTTP client with predefined responses
  static http.Client createMockHttpClient({
    Map<String, http.Response> responses = const {},
    Duration delay = Duration.zero,
  }) {
    final mockClient = MockClient();
    
    for (final entry in responses.entries) {
      when(mockClient.get(Uri.parse(entry.key)))
          .thenAnswer((_) async {
        if (delay > Duration.zero) {
          await Future.delayed(delay);
        }
        return entry.value;
      });
    }
    
    return mockClient;
  }
  
  /// Create test event data
  static Map<String, dynamic> createTestEventData({
    String? id,
    String? name,
    String? category,
    DateTime? date,
    int? slots,
    double? price,
    String? host,
  }) {
    return {
      'id': id ?? 'test-event-1752163695500',
      'name': name ?? 'Test Event',
      'category': category ?? 'Comedy',
      'date': (date ?? DateTime.now().add(const Duration(days: 1))).toIso8601String(),
      'slots': slots ?? 50,
      'price': price ?? 15.00,
      'host': host ?? TestConfig.testUserId,
      'hostName': 'Test Host',
      'address': '123 Test Street',
      'ended': false,
      'live': false,
      'isPrivate': false,
      'attendees': [],
      'waitlist': [],
      'location': {
        'latitude': 40.7128,
        'longitude': -74.0060,
      },
    };
  }
  
  /// Create test user data
  static Map<String, dynamic> createTestUserData({
    String? id,
    String? username,
    String? email,
  }) {
    return {
      'id': id ?? TestConfig.testUserId,
      'username': username ?? 'testuser',
      'email': email ?? TestConfig.testEmail,
      'photoUrl': 'https://example.com/photo.jpg',
      'bio': 'Test user bio',
      'isHost': true,
      'savedEvents': [],
      'hostingEvents': [],
    };
  }
  
  /// Wait for async operations with timeout
  static Future<void> waitForAsync({
    Duration timeout = TestConfig.defaultTimeout,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  /// Retry operation with exponential backoff
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = TestConfig.maxRetries,
    Duration delay = TestConfig.retryDelay,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay * attempts);
      }
    }
    throw Exception('Max retries exceeded');
  }
}

class MockClient extends Mock implements http.Client {}
