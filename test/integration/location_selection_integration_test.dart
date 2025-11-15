import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/pages/location.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Location Selection Integration Tests', () {
    testWidgets('Full user journey - open, search, select, confirm', 
        (WidgetTester tester) async {
      Map<String, dynamic>? selectedLocation;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: Text('Create Event'),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CupertinoButton.filled(
                      child: const Text('Select Location'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => LocationPage(
                              onPicked: (data) {
                                selectedLocation = data;
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    if (selectedLocation != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Selected Location:'),
                            Text(selectedLocation!['address'].toString()),
                            if (selectedLocation!['latlng'] != null)
                              Text(
                                'Lat: ${(selectedLocation!['latlng'] as LatLng).latitude.toStringAsFixed(4)}, '
                                'Lng: ${(selectedLocation!['latlng'] as LatLng).longitude.toStringAsFixed(4)}',
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Tap the select location button
      expect(find.text('Select Location'), findsOneWidget);
      await tester.tap(find.text('Select Location'));
      await tester.pumpAndSettle();

      // Step 2: Verify location page opened
      expect(find.text('Pick Location'), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsOneWidget);

      // Step 3: Search for a location
      await tester.enterText(
        find.byType(CupertinoTextField),
        'San Francisco, CA',
      );
      await tester.pumpAndSettle();

      // Wait for debounce and search to complete
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Step 4: Confirm selection
      await tester.tap(find.byIcon(CupertinoIcons.check_mark_circled_solid));
      await tester.pumpAndSettle();

      // Step 5: Verify we're back on the create event page
      expect(find.text('Create Event'), findsOneWidget);
      expect(find.text('Pick Location'), findsNothing);

      // Step 6: Verify location was selected
      expect(selectedLocation, isNotNull);
      expect(selectedLocation!['address'], isNotNull);
      expect(selectedLocation!['address'], contains('San Francisco'));
    });

    testWidgets('User can go back without selecting', (WidgetTester tester) async {
      Map<String, dynamic>? selectedLocation;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              child: const Text('Open Location Picker'),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => LocationPage(
                      onPicked: (data) {
                        selectedLocation = data;
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open location picker
      await tester.tap(find.text('Open Location Picker'));
      await tester.pumpAndSettle();

      // Verify it opened
      expect(find.text('Pick Location'), findsOneWidget);

      // Go back without selecting
      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      // Should be back to original page
      expect(find.text('Open Location Picker'), findsOneWidget);
      expect(find.text('Pick Location'), findsNothing);

      // No location should be selected
      expect(selectedLocation, isNull);
    });

    testWidgets('Pre-filled location is displayed correctly', 
        (WidgetTester tester) async {
      const initialLocation = LatLng(37.7749, -122.4194); // San Francisco

      await tester.pumpWidget(
        CupertinoApp(
          home: LocationPage(
            onPicked: (data) {},
            eventLocation: initialLocation,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Wait for reverse geocoding
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Location page should be displayed with the initial location
      expect(find.text('Pick Location'), findsOneWidget);
      
      // Note: In a real integration test with network access,
      // we would verify the reverse geocoded address appears
    });

    testWidgets('Multiple location selections in sequence', 
        (WidgetTester tester) async {
      final List<Map<String, dynamic>> selections = [];

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              child: Text('Selections: ${selections.length}'),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => LocationPage(
                      onPicked: (data) {
                        selections.add(data);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First selection
      await tester.tap(find.text('Selections: 0'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CupertinoTextField), 'New York');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.check_mark_circled_solid));
      await tester.pumpAndSettle();

      expect(selections.length, 1);

      // Second selection
      await tester.tap(find.text('Selections: 1'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CupertinoTextField), 'Los Angeles');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.check_mark_circled_solid));
      await tester.pumpAndSettle();

      expect(selections.length, 2);
      expect(selections[0]['address'], contains('New York'));
      expect(selections[1]['address'], contains('Los Angeles'));
    });

    testWidgets('Search field clears between sessions', 
        (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // First session
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CupertinoTextField), 'Chicago');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      // Second session
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Search field should be empty
      final textField = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('Handles rapid navigation', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Rapidly open and close
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Pick Location'), findsOneWidget);
        
        await tester.tap(find.byIcon(CupertinoIcons.back));
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsOneWidget);
      }
    });
  });

  group('Location Selection with Edit Event Flow', () {
    testWidgets('Simulates full event creation flow', 
        (WidgetTester tester) async {
      String? eventLocation;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Create Event'),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const CupertinoTextField(
                    placeholder: 'Event Name',
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) => CupertinoButton(
                      child: Text(
                        eventLocation ?? 'Select Location',
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => LocationPage(
                              onPicked: (data) {
                                // Simulate the edit_event.dart flow
                                final address = data['address'] as String?;
                                if (address != null && address.isNotEmpty) {
                                  // This would update the event location
                                  eventLocation = address;
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Select Location'), findsOneWidget);

      // Tap to select location
      await tester.tap(find.text('Select Location'));
      await tester.pumpAndSettle();

      // Enter location
      await tester.enterText(
        find.byType(CupertinoTextField).last,
        'Golden Gate Park, San Francisco',
      );
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.byIcon(CupertinoIcons.check_mark_circled_solid));
      await tester.pumpAndSettle();

      // Verify we're back and location is set
      expect(find.text('Create Event'), findsOneWidget);
      // Note: In a real integration test, we would verify the location
      // was properly saved to the event
    });
  });
}

