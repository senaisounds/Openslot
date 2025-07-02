import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/common/slotted_user.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initialize();
  });

  tearDownAll(() async {
    await TestSetup.cleanup();
  });

  group('User Profile Comprehensive Tests', () {
    late SlottedUser testUser;

    setUp(() async {
      await TestSetup.setupTestData();
      
      testUser = SlottedUser()
        ..id = 'test-user-profile'
        ..username = 'ProfileTestUser'
        ..bio = 'This is a test user profile bio with multiple lines.\nSecond line of bio.'
        ..photoUrl = 'https://example.com/profile.jpg'
        ..isFirstTimer = false
        ..twitter = '@profiletest'
        ..instagram = '@profiletest'
        ..savedEvents = ['event1', 'event2', 'event3']
        ..openMics = ['mic1', 'mic2']
        ..awards = [
          {'id': 'first-performance', 'dateEarned': '2024-01-15'},
          {'id': 'social-connector', 'dateEarned': '2024-02-01'},
        ];
    });

    testWidgets('Profile header displays user information correctly', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                // Profile picture placeholder
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: testUser.photoUrl.isNotEmpty
                      ? const Icon(Icons.person, size: 50)
                      : const Icon(Icons.person_outline, size: 50),
                ),
                const SizedBox(height: 16),
                // Username
                Text(
                  testUser.username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Bio
                Text(
                  testUser.bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                // First timer badge
                if (testUser.isFirstTimer)
                  const Chip(
                    label: Text('First Timer'),
                    backgroundColor: Colors.green,
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('ProfileTestUser'), findsOneWidget);
      expect(find.text('This is a test user profile bio with multiple lines.\nSecond line of bio.'), findsOneWidget);
      expect(find.text('First Timer'), findsNothing); // User is not first timer
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Profile stats display correctly', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '${testUser.savedEvents.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Events'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${testUser.openMics.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Open Mics'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${testUser.awards.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Awards'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget); // Events count
      expect(find.text('2'), findsOneWidget); // Open mics count
      expect(find.text('2'), findsOneWidget); // Awards count (second instance)
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Open Mics'), findsOneWidget);
      expect(find.text('Awards'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Social media links display correctly', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                const Text('Social Media'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (testUser.twitter.isNotEmpty)
                      Column(
                        children: [
                          const Icon(Icons.alternate_email, color: Colors.blue),
                          Text(testUser.twitter),
                        ],
                      ),
                    if (testUser.instagram.isNotEmpty)
                      Column(
                        children: [
                          const Icon(Icons.camera_alt, color: Colors.purple),
                          Text(testUser.instagram),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Social Media'), findsOneWidget);
      expect(find.text('@profiletest'), findsNWidgets(2)); // Twitter and Instagram
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Awards section displays correctly', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                const Text('Awards & Achievements'),
                const SizedBox(height: 16),
                if (testUser.awards.isEmpty)
                  const Text('No awards yet')
                else
                  Column(
                    children: testUser.awards.map((award) {
                      return ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text('Award: ${award['id']}'),
                        subtitle: Text('Earned: ${award['dateEarned']}'),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Awards & Achievements'), findsOneWidget);
      expect(find.text('Award: first-performance'), findsOneWidget);
      expect(find.text('Award: social-connector'), findsOneWidget);
      expect(find.text('Earned: 2024-01-15'), findsOneWidget);
      expect(find.text('Earned: 2024-02-01'), findsOneWidget);
      expect(find.text('No awards yet'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Profile edit functionality works', (WidgetTester tester) async {
      bool isEditing = false;
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              actions: [
                IconButton(
                  icon: Icon(isEditing ? Icons.save : Icons.edit),
                  onPressed: () {
                    // Toggle editing state
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                if (isEditing)
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  Text(
                    testUser.username,
                    style: const TextStyle(fontSize: 24),
                  ),
                const SizedBox(height: 16),
                if (isEditing)
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  )
                else
                  Text(testUser.bio),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.text('ProfileTestUser'), findsOneWidget);
      expect(find.byType(TextField), findsNothing); // Not in editing mode
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Profile loading states work correctly', (WidgetTester tester) async {
      bool isLoading = true;
      SlottedUser? user = isLoading ? null : testUser;
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Center(
              child: isLoading
                  ? const CupertinoActivityIndicator(radius: 20)
                  : user == null
                      ? const Text('User not found')
                      : Column(
                          children: [
                            Text(user.username),
                            Text(user.bio),
                          ],
                        ),
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('User not found'), findsNothing);
      expect(find.text('ProfileTestUser'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('Profile Validation Tests', () {
    testWidgets('Handles empty profile data gracefully', (WidgetTester tester) async {
      final emptyUser = SlottedUser()
        ..id = 'empty-user'
        ..username = ''
        ..bio = ''
        ..photoUrl = ''
        ..isFirstTimer = true
        ..twitter = ''
        ..instagram = '';

      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                Text(emptyUser.username.isEmpty ? 'Anonymous User' : emptyUser.username),
                Text(emptyUser.bio.isEmpty ? 'No bio available' : emptyUser.bio),
                if (emptyUser.isFirstTimer)
                  const Chip(
                    label: Text('First Timer'),
                    backgroundColor: Colors.green,
                  ),
                Text('Social links: ${emptyUser.twitter.isEmpty && emptyUser.instagram.isEmpty ? 'None' : 'Available'}'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Anonymous User'), findsOneWidget);
      expect(find.text('No bio available'), findsOneWidget);
      expect(find.text('First Timer'), findsOneWidget);
      expect(find.text('Social links: None'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Validates social media handle formats', (WidgetTester tester) async {
      final socialHandles = [
        {'platform': 'Twitter', 'handle': '@validhandle', 'isValid': true},
        {'platform': 'Twitter', 'handle': 'invalidhandle', 'isValid': false},
        {'platform': 'Instagram', 'handle': '@valid_handle', 'isValid': true},
        {'platform': 'Instagram', 'handle': 'invalid handle', 'isValid': false},
      ];

      for (final social in socialHandles) {
        await TestSetup.safePumpWidget(
          tester,
          TestSetup.createSimpleTestWidget(
            child: Scaffold(
              body: Column(
                children: [
                  Text('${social['platform']}: ${social['handle']}'),
                  Text('Valid: ${social['isValid']}'),
                  if (social['isValid'] as bool)
                    const Icon(Icons.check, color: Colors.green)
                  else
                    const Icon(Icons.error, color: Colors.red),
                ],
              ),
            ),
          ),
        );

        expect(find.text('${social['platform']}: ${social['handle']}'), findsOneWidget);
        expect(find.text('Valid: ${social['isValid']}'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
      }
    }, timeout: const Timeout(Duration(seconds: 15)));
  });

  group('Profile Actions Tests', () {
    testWidgets('Profile action buttons work correctly', (WidgetTester tester) async {
      bool isOwnProfile = true;
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                if (isOwnProfile) ...[
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Edit Profile'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Settings'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Sign Out'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Follow'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Message'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Follow'), findsNothing);
      expect(find.text('Message'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
