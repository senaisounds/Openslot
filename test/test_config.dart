// Test configuration for OpenSlot app
class TestConfig {
  // Timeout settings
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(seconds: 30);
  
  // Retry settings
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
  
  // Mock settings
  static const bool enableNetworkMocks = true;
  static const bool enableFirebaseMocks = true;
  
  // Test data settings
  static const String testUserId = 'test-user-123';
  static const String testEventId = 'event-1';
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'testpassword123';
}
