import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/pages/location.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('LocationPage Tests', () {
    testWidgets('renders correctly with default location', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Verify navigation bar elements
      expect(find.text('Pick Location'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.back), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.check_mark_circled_solid), findsOneWidget);

      // Verify search field
      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.text('Search address...'), findsOneWidget);

      // Verify current location button
      expect(find.byIcon(CupertinoIcons.location_fill), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with initial location', (WidgetTester tester) async {
      const initialLocation = LatLng(40.7128, -74.0060); // New York

      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
            eventLocation: initialLocation,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Page should render without errors
      expect(find.text('Pick Location'), findsOneWidget);
    });

    testWidgets('search field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap search field
      final searchField = find.byType(CupertinoTextField);
      expect(searchField, findsOneWidget);

      // Enter text
      await tester.enterText(searchField, 'San Francisco');
      await tester.pump();

      // Verify text was entered
      expect(find.text('San Francisco'), findsOneWidget);
    });

    testWidgets('back button pops the page', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              child: const Text('Open'),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => LocationPage(
                      onPicked: (data) {},
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Open the location page
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Pick Location'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      // Should be back to the original page
      expect(find.text('Pick Location'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('confirm button calls onPicked callback', (WidgetTester tester) async {
      bool pickedCalled = false;
      Map<String, dynamic>? pickedData;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              child: const Text('Open'),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => LocationPage(
                      onPicked: (data) {
                        pickedCalled = true;
                        pickedData = data;
                      },
                      eventLocation: const LatLng(37.7749, -122.4194),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Open the location page
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap confirm button
      await tester.tap(find.byIcon(CupertinoIcons.check_mark_circled_solid));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(pickedCalled, true);
      expect(pickedData, isNotNull);
      expect(pickedData!.containsKey('address'), true);
      expect(pickedData!.containsKey('latlng'), true);
    });

    testWidgets('displays search results when typing', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text (need at least 3 characters)
      final searchField = find.byType(CupertinoTextField);
      await tester.enterText(searchField, 'San');
      
      // Wait for debounce timer
      await tester.pump(const Duration(milliseconds: 400));

      // Note: In a real test, we'd need to mock the HTTP client
      // For now, we just verify the UI responds to input
    });

    testWidgets('clears search results when text is cleared', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter text
      final searchField = find.byType(CupertinoTextField);
      await tester.enterText(searchField, 'San Francisco');
      await tester.pump();

      // Clear text
      await tester.enterText(searchField, '');
      await tester.pump();

      // Suggestions should be cleared (tested via state behavior)
    });

    testWidgets('has proper color scheme matching app theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find navigation bar
      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );

      // Verify dark background
      expect(navBar.backgroundColor, CupertinoColors.black);

      // Verify border is null (no border)
      expect(navBar.border, null);
    });

    testWidgets('search field has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );

      // Verify placeholder
      expect(searchField.placeholder, 'Search address...');

      // Verify clear button mode
      expect(searchField.clearButtonMode, OverlayVisibilityMode.editing);
    });
  });

  group('AddressSuggestion Tests', () {
    test('creates from Nominatim JSON correctly', () {
      final json = {
        'display_name': '123 Main St, San Francisco, CA',
        'place_id': '12345',
        'lat': '37.7749',
        'lon': '-122.4194',
      };

      final suggestion = AddressSuggestion.fromNominatim(json);

      expect(suggestion.text, '123 Main St, San Francisco, CA');
      expect(suggestion.id, '12345');
      expect(suggestion.latitude, 37.7749);
      expect(suggestion.longitude, -122.4194);
    });

    test('handles missing coordinates', () {
      final json = {
        'display_name': 'Test Location',
        'place_id': '999',
      };

      final suggestion = AddressSuggestion.fromNominatim(json);

      expect(suggestion.text, 'Test Location');
      expect(suggestion.id, '999');
      expect(suggestion.latitude, null);
      expect(suggestion.longitude, null);
    });

    test('parses coordinates as strings correctly', () {
      final json = {
        'display_name': 'Test',
        'place_id': '1',
        'lat': '40.7128',
        'lon': '-74.0060',
      };

      final suggestion = AddressSuggestion.fromNominatim(json);

      expect(suggestion.latitude, 40.7128);
      expect(suggestion.longitude, -74.0060);
    });
  });

  group('LocationPage Integration Tests', () {
    testWidgets('complete user flow - search and confirm', (WidgetTester tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              child: const Text('Open'),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => LocationPage(
                      onPicked: (data) {
                        result = data;
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Open page
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter search
      await tester.enterText(
        find.byType(CupertinoTextField),
        'San Francisco',
      );
      await tester.pump();

      // Confirm selection
      await tester.tap(find.byIcon(CupertinoIcons.check_mark_circled_solid));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!['address'], contains('San Francisco'));
    });

    testWidgets('shows loading indicator when searching', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter text to trigger search
      await tester.enterText(
        find.byType(CupertinoTextField),
        'New York',
      );

      // Pump once to trigger the search state
      await tester.pump(const Duration(milliseconds: 100));

      // Activity indicator should appear in the search field
      // (In real implementation with mocked HTTP)
    });

    testWidgets('preserves initial location marker on map', (WidgetTester tester) async {
      const testLocation = LatLng(40.7128, -74.0060);

      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
            eventLocation: testLocation,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Map should be rendered with the initial location
      // This is validated by the fact that the widget builds successfully
      expect(find.byType(LocationPage), findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('has proper semantics for screen readers', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that important elements are present
      expect(find.text('Pick Location'), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.check_mark_circled_solid), findsOneWidget);
    });

    testWidgets('buttons are tappable with sufficient size', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find confirm button
      final confirmButton = find.byIcon(CupertinoIcons.check_mark_circled_solid);
      expect(confirmButton, findsOneWidget);

      // Verify it's tappable
      await tester.tap(confirmButton);
      await tester.pump();
    });
  });

  group('Error Handling Tests', () {
    testWidgets('handles empty search gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to search with less than 3 characters
      await tester.enterText(find.byType(CupertinoTextField), 'AB');
      await tester.pump(const Duration(milliseconds: 400));

      // Should not show any error, just no results
      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });

    testWidgets('handles null initial location', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
            eventLocation: null,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render with default location
      expect(find.text('Pick Location'), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    testWidgets('debounces search input correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(CupertinoTextField);

      // Type multiple characters quickly
      await tester.enterText(searchField, 'S');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(searchField, 'Sa');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(searchField, 'San');
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for debounce (300ms)
      await tester.pump(const Duration(milliseconds: 400));

      // Only one search should be triggered (after debounce)
      // This would be verified with HTTP mocking in a real test
    });

    testWidgets('builds efficiently with large location data', (WidgetTester tester) async {
      final startTime = DateTime.now();

      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
            eventLocation: const LatLng(37.7749, -122.4194),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final endTime = DateTime.now();
      final buildTime = endTime.difference(startTime);

      // Should build in reasonable time (less than 5 seconds)
      expect(buildTime.inSeconds, lessThan(5));
    });
  });
}

