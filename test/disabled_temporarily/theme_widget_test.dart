import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:slotted/pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'test_helpers.dart';

void main() {
  group('Theme Widget Tests', () {
    late ThemeProvider themeProvider;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUpAll(() async {
      // Setup Firebase for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      setupFirebaseCoreMocks();
      await Firebase.initializeApp();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark', // Always dark mode
      });
      themeProvider = ThemeProvider();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      
      // Wait for the initial theme to load
      await Future.delayed(const Duration(milliseconds: 100));
    });

    testWidgets('Settings page should use dark theme', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            Provider<FirebaseAuth>.value(value: mockAuth),
          ],
          child: CupertinoApp(
            home: SettingsPage(user: mockUser),
          ),
        ),
      );

      // Wait for widget to build
      await tester.pumpAndSettle();

      // Verify app is in dark mode
      expect(themeProvider.isDarkMode, true);
      
      // Appearance option should not be present
      expect(find.text('Appearance'), findsNothing);
    });
  });
} 