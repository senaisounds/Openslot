# Slotted App Testing Guide

This document provides an overview of the testing strategy for the Slotted app, how to run tests, and best practices for maintaining and extending the test suite.

## Test Structure

The test suite is organized into three main categories:

1. **Unit Tests** - Test individual functions and classes in isolation
2. **Integration Tests** - Test how multiple components work together
3. **Performance Tests** - Measure and benchmark critical app operations

### Test Directory Structure

```
test/
├── unit/                 # Unit tests for individual components
│   └── reservation_logic_test.dart
├── integration/          # Integration tests for user flows
│   └── reservation_flow_test.dart
├── performance/          # Performance benchmarks
│   └── reservation_performance_test.dart
├── pages/                # Tests for specific pages
│   ├── edit_event_test.dart
│   └── my_home_page_test.dart
├── test_helpers.dart     # Common test utilities and mocks
├── basic_widget_test.dart
└── README.md             # This file
```

## Running Tests

### Running All Tests

To run all tests, use the following command from the project root:

```bash
flutter test
```

### Running Specific Test Categories

To run a specific category of tests:

```bash
# Run unit tests only
flutter test test/unit/

# Run integration tests only
flutter test test/integration/

# Run performance tests only
flutter test test/performance/

# Run a specific test file
flutter test test/unit/reservation_logic_test.dart
```

## Test Coverage

### Unit Tests

Unit tests cover core business logic and functions, including:

- **Reservation Logic** - Testing the event reservation system, including free events, paid events, waitlist behavior, and error handling.
- **API Service Methods** - Testing API interaction and response handling.
- **Model Classes** - Testing model data structures and transformations.

### Integration Tests

Integration tests cover critical user flows, including:

- **Reservation Flow** - Testing the complete reservation process from finding an event to reserving a spot.
- **Authentication Flow** - Testing user sign-up, login, and session handling.
- **Payment Flow** - Testing the payment process for paid events.

### Performance Tests

Performance tests measure critical metrics including:

- **Reservation Performance** - Measuring the response time for reservation operations under different conditions.
- **Event Scaling Performance** - Testing how the system performs with varying event sizes.
- **Concurrent Reservation Performance** - Testing how the system handles multiple simultaneous reservation requests.

## Test Development Best Practices

### Writing New Tests

When writing new tests, follow these best practices:

1. **Test One Thing Per Test** - Each test should verify a single behavior or feature.
2. **Use Descriptive Test Names** - Test names should clearly describe what's being tested.
3. **Arrange-Act-Assert Pattern** - Structure tests in three parts: setup, action, and verification.
4. **Use Mocks Appropriately** - Use mocks for external dependencies, but be careful not to over-mock.
5. **Test Edge Cases** - Include tests for error conditions, empty states, and boundary values.

### Example Test Structure

```dart
test('Can reserve a spot in an event with available slots', () async {
  // Arrange: Set up the test data and environment
  final event = createTestEvent(attendees: ['user1', 'user2']);
  final testUser = TestUser();
  
  // Act: Perform the action being tested
  final result = await reserveAction('', event, testUser);
  
  // Assert: Verify the expected outcome
  expect(result, 'Successfully reserved');
});
```

### Mocking

The `test_helpers.dart` file provides mock implementations for Firebase, HTTP, and other external dependencies. Use these mocks to ensure tests are fast, reliable, and don't depend on external services.

Example of using mocks:

```dart
// Mock a successful HTTP response
when(mockClient.post(
  Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
  headers: anyNamed('headers'),
  body: anyNamed('body'),
)).thenAnswer((_) async => MockResponse('Successfully reserved', 200));
```

## Troubleshooting Tests

If tests are failing, check the following:

1. **Widget Rendering Issues** - Make sure widgets are properly initialized and rendered.
2. **Async Issues** - Ensure `await` is used appropriately for async operations.
3. **State Management** - Check that state updates are properly awaited with `pumpAndSettle()`.
4. **Mock Configuration** - Verify that mocks are configured correctly.

## Continuous Integration

Tests are automatically run on our CI/CD pipeline for every pull request and merge to main. Pull requests with failing tests will be blocked from merging.

## Performance Benchmarking

Performance tests output benchmark results to the console. These results should be monitored over time to detect performance regressions.

Example performance metrics:

- Reservation operation time (free event): < 500ms
- Reservation operation time (paid event): < 2000ms
- Concurrent user capacity: 100 users with < 5% error rate 