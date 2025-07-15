import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/event_class.dart';
import 'performance_monitor.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initialize();
    PerformanceMonitor.setEnabled(true);
  });

  tearDownAll(() async {
    await TestSetup.cleanup();
  });

  setUp(() {
    PerformanceMonitor.clearMetrics();
  });

  group('Performance Benchmarks', () {
    testWidgets('Widget rendering performance', (WidgetTester tester) async {
      // Measure widget tree creation
      final createTime = await PerformanceMonitor.measureAsync(
        'widget_tree_creation',
        () async {
          await TestSetup.safePumpWidget(
            tester,
            TestSetup.createSimpleTestWidget(
              child: Scaffold(
                body: ListView.builder(
                  itemCount: 100,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Item $index'),
                      subtitle: Text('Subtitle for item $index'),
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );

      // Measure scroll performance
      final scrollTime = await PerformanceMonitor.measureAsync(
        'scroll_performance',
        () async {
          final listFinder = find.byType(ListView);
          await tester.fling(listFinder, const Offset(0, -500), 1000);
          await tester.pumpAndSettle();
        },
      );

      // Assert performance benchmarks
      expect(createTime, lessThan(1000), reason: 'Widget creation should be under 1 second');
      expect(scrollTime, lessThan(500), reason: 'Scrolling should be under 500ms');

      // Generate performance report
      final stats = PerformanceMonitor.getAllStats();
      expect(stats, isNotEmpty);
      
      print('\n📊 Widget Performance Report:');
      print('Widget creation: ${createTime.toStringAsFixed(2)}ms');
      print('Scroll performance: ${scrollTime.toStringAsFixed(2)}ms');
    }, timeout: const Timeout(Duration(seconds: 15)));

    testWidgets('Event list rendering performance', (WidgetTester tester) async {
      // Create test events
      final events = List.generate(50, (index) => Event(
        id: 'event-$index',
        name: 'Test Event $index',
        host: 'host-$index',
        hostName: 'Host $index',
        date: DateTime.now().add(Duration(hours: index)),
        slots: 10 + index,
        price: index * 5.0,
        attendees: [],
        waitlist: [],
        live: index % 10 == 0,
        ended: false,
        address: '$index Test Street',
        category: 'Music',
        isPrivate: false,
      ));

      final renderTime = await PerformanceMonitor.measureAsync(
        'event_list_rendering',
        () async {
          await TestSetup.safePumpWidget(
            tester,
            TestSetup.createSimpleTestWidget(
              child: Scaffold(
                body: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      child: ListTile(
                        title: Text(event.name),
                        subtitle: Text('Host: ${event.hostName}'),
                        trailing: Text('\$${event.price.toStringAsFixed(2)}'),
                        leading: Icon(
                          event.live ? Icons.live_tv : Icons.event,
                          color: event.live ? Colors.red : Colors.blue,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );

      expect(renderTime, lessThan(2000), reason: 'Event list rendering should be under 2 seconds');
      
      print('\n📊 Event List Performance Report:');
      print('50 events rendered in: ${renderTime.toStringAsFixed(2)}ms');
    }, timeout: const Timeout(Duration(seconds: 20)));

    testWidgets('Form input performance', (WidgetTester tester) async {
      final TextEditingController nameController = TextEditingController();
      final TextEditingController emailController = TextEditingController();
      final TextEditingController bioController = TextEditingController();

      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      );

      // Measure text input performance
      final inputTime = await PerformanceMonitor.measureAsync(
        'text_input_performance',
        () async {
          await tester.enterText(find.byType(TextField).first, 'John Doe');
          await tester.enterText(find.byType(TextField).at(1), 'john.doe@example.com');
          await tester.enterText(find.byType(TextField).at(2), 'This is a test bio with multiple lines.\nSecond line of the bio.');
        },
      );

      expect(inputTime, lessThan(1000), reason: 'Text input should be under 1 second');
      
      print('\n📊 Form Input Performance Report:');
      print('Text input performance: ${inputTime.toStringAsFixed(2)}ms');
    }, timeout: const Timeout(Duration(seconds: 15)));

    testWidgets('Image loading simulation performance', (WidgetTester tester) async {
      final imageUrls = List.generate(20, (index) => 'https://picsum.photos/200/200?random=$index');

      final imageLoadTime = await PerformanceMonitor.measureAsync(
        'image_loading_simulation',
        () async {
          await TestSetup.safePumpWidget(
            tester,
            TestSetup.createSimpleTestWidget(
              child: Scaffold(
                body: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 50),
                          ),
                          Text('Image $index'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );

      expect(imageLoadTime, lessThan(3000), reason: 'Image grid should load under 3 seconds');
      
      print('\n📊 Image Loading Performance Report:');
      print('20 image placeholders: ${imageLoadTime.toStringAsFixed(2)}ms');
    }, timeout: const Timeout(Duration(seconds: 20)));
  });

  group('Memory Performance Tests', () {
    testWidgets('Memory usage during heavy operations', (WidgetTester tester) async {
      // Simulate memory-intensive operations
      final memoryTestTime = await PerformanceMonitor.measureAsync(
        'memory_intensive_test',
        () async {
          // Create large data structures
          final largeList = List.generate(10000, (index) => 'Item $index with some data');
          final largeMap = {for (int i = 0; i < 1000; i++) 'key$i': 'value$i with more data'};
          
          await TestSetup.safePumpWidget(
            tester,
            TestSetup.createSimpleTestWidget(
              child: Scaffold(
                body: Column(
                  children: [
                    Text('Large list size: ${largeList.length}'),
                    Text('Large map size: ${largeMap.length}'),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 100, // Only show first 100 items
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(largeList[index]),
                            subtitle: Text(largeMap['key$index'] ?? ''),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          
          // Cleanup
          largeList.clear();
          largeMap.clear();
        },
      );

      expect(memoryTestTime, lessThan(5000), reason: 'Memory test should complete under 5 seconds');
      
      print('\n📊 Memory Performance Report:');
      print('Memory intensive test: ${memoryTestTime.toStringAsFixed(2)}ms');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('Performance Analytics', () {
    test('Performance monitor statistics', () {
      // Generate test data
      PerformanceMonitor.startMeasurement('test_operation');
      // Simulate work
      for (int i = 0; i < 1000000; i++) {
        // Busy work
      }
      final duration = PerformanceMonitor.endMeasurement('test_operation');

      // Test multiple measurements
      for (int i = 0; i < 10; i++) {
        PerformanceMonitor.measureSync('batch_operation', () {
          // Simulate varying work loads
          for (int j = 0; j < (i + 1) * 100000; j++) {
            // Variable busy work
          }
          return i;
        });
      }

      // Get statistics
      final stats = PerformanceMonitor.getStats('batch_operation');
      expect(stats, isNotNull);
      expect(stats!.count, equals(10));
      expect(stats.average, greaterThan(0));
      expect(stats.min, lessThanOrEqualTo(stats.max));
      expect(stats.median, greaterThan(0));
      expect(stats.p95, greaterThan(0));

      // Generate report
      final report = PerformanceMonitor.generateReport();
      expect(report, contains('Performance Report'));
      expect(report, contains('test_operation'));
      expect(report, contains('batch_operation'));
      
      print('\n📊 Performance Statistics:');
      print('Test operation duration: ${duration.toStringAsFixed(2)}ms');
      print('Batch operation stats: $stats');
    });

    test('Performance thresholds and alerts', () async {
      final performanceThresholds = {
        'widget_rendering': 100.0, // ms
        'database_query': 500.0,   // ms
        'network_request': 1000.0, // ms
        'image_loading': 2000.0,   // ms
      };

      // Simulate various performance scenarios
      final testScenarios = [
        {'operation': 'widget_rendering', 'duration': 50.0, 'shouldPass': true},
        {'operation': 'widget_rendering', 'duration': 150.0, 'shouldPass': false},
        {'operation': 'database_query', 'duration': 300.0, 'shouldPass': true},
        {'operation': 'database_query', 'duration': 800.0, 'shouldPass': false},
        {'operation': 'network_request', 'duration': 500.0, 'shouldPass': true},
        {'operation': 'network_request', 'duration': 1500.0, 'shouldPass': false},
      ];

      for (final scenario in testScenarios) {
        final operation = scenario['operation'] as String;
        final duration = scenario['duration'] as double;
        final shouldPass = scenario['shouldPass'] as bool;
        final threshold = performanceThresholds[operation]!;

        // Simulate the measurement using the public API
        PerformanceMonitor.startMeasurement(operation);
        // Simulate work for the specified duration
        await Future.delayed(Duration(microseconds: (duration * 1000).round()));
        PerformanceMonitor.endMeasurement(operation);

        // Check threshold
        final passesThreshold = duration <= threshold;
        expect(passesThreshold, equals(shouldPass), 
               reason: '$operation with ${duration}ms should ${shouldPass ? 'pass' : 'fail'} threshold of ${threshold}ms');
      }

      print('\n📊 Performance Threshold Analysis:');
      for (final entry in performanceThresholds.entries) {
        final operation = entry.key;
        final threshold = entry.value;
        final stats = PerformanceMonitor.getStats(operation);
        final avgDuration = stats?.average ?? 0.0;
        final status = avgDuration <= threshold ? '✅ PASS' : '❌ FAIL';
        print('$operation: ${avgDuration.toStringAsFixed(2)}ms (threshold: ${threshold}ms) $status');
      }
    });
  });
}
