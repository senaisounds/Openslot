import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:slotted/common/slotted_user.dart';
import 'dart:async';

/// Mock Firebase Auth for testing
class MockFirebaseAuth implements FirebaseAuth {
  User? _currentUser;
  final List<User> _users = [];
  
  @override
  User? get currentUser => _currentUser;
  
  @override
  Stream<User?> authStateChanges() => Stream.value(_currentUser);
  
  void signIn(User user) {
    _currentUser = user;
    if (!_users.contains(user)) {
      _users.add(user);
    }
  }
  
  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
  
  // Implement other required methods with default implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock User for testing
class MockUser implements User {
  final String _uid;
  final String _email;
  final String _displayName;
  
  MockUser({
    String? uid,
    String? email,
    String? displayName,
  }) : _uid = uid ?? 'test-user-id',
       _email = email ?? 'test@example.com',
       _displayName = displayName ?? 'Test User';
  
  @override
  String get uid => _uid;
  
  @override
  String? get email => _email;
  
  @override
  String? get displayName => _displayName;
  
  // Implement other required methods with default implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock SlottedUser for testing
class MockSlottedUser extends SlottedUser {
  MockSlottedUser({
    String? id,
    String? username,
    String? email,
    String? phoneNumber,
    bool? isHost,
    String? photoUrl,
    String? bio,
    List<Map<String, dynamic>>? awards,
    List<String>? savedEvents,
    List<String>? blockedUsers,
  }) {
    this.id = id ?? 'test-user-id';
    this.username = username ?? 'testuser';
    this.email = email ?? 'test@example.com';
    this.phoneNumber = phoneNumber ?? '+1234567890';
    this.isHost = isHost ?? false;
    this.photoUrl = photoUrl ?? '';
    this.bio = bio ?? 'Test user bio';
    this.awards = awards ?? [];
    this.savedEvents = savedEvents ?? [];
    this.blockedUsers = blockedUsers ?? [];
    isFirstTimer = false;
    createdAt = DateTime.now();
    lastLogin = DateTime.now();
  }
}

/// Simple test user data for testing
class TestUserData {
  static const String testUserId = 'test-user-id';
  static const String testUsername = 'testuser';
  static const String testEmail = 'test@example.com';
  static const String testDisplayName = 'Test User';
}

class MockUserCredential extends Mock implements UserCredential {
  @override
  User? get user => MockUser();
}

class MockIdTokenResult extends Mock implements IdTokenResult {
  // Let Mock's noSuchMethod handle most properties
  // Only override what's absolutely necessary for tests
}

class MockFirebaseApp extends Mock implements FirebaseApp {
  @override
  String get name => 'mock-app';

  @override
  FirebaseOptions get options => const FirebaseOptions(
    apiKey: 'mock-api-key',
    appId: 'mock-app-id',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project',
  );
}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  @override
  FirebaseApp get app => MockFirebaseApp();
}

class MockDocumentReference extends Mock {
  // Mock implementation that doesn't extend sealed class
  String get id => 'mock-doc-id';
  
  // Add any other methods needed for testing
  // Note: Returns MockDocumentSnapshot instead of DocumentSnapshot due to sealed class restrictions
  Future<MockDocumentSnapshot> get() async {
    // Create a mock DocumentSnapshot for testing
    return createMockDocumentSnapshot();
  }
  
  Future<void> set(Map<String, dynamic> data) async {}
  
  Future<void> update(Map<String, dynamic> data) async {}
  
  Future<void> delete() async {}
}

// Mock DocumentSnapshot wrapper that doesn't implement the sealed class
// Instead, it provides a compatible interface for testing
class MockDocumentSnapshot extends Mock {
  final String mockId;
  final Map<String, dynamic>? mockData;
  final bool mockExists;
  
  MockDocumentSnapshot({
    this.mockId = 'mock-doc-id',
    this.mockData,
    this.mockExists = true,
  });
  
  String get id => mockId;
  
  Map<String, dynamic>? data() => mockData ?? {'mock': 'data'};
  
  bool get exists => mockExists;
  
  // Provide a way to treat this as a DocumentSnapshot for testing
  // Since DocumentSnapshot is sealed, we can't implement it directly
  // Tests should use this mock's methods directly or use when() stubs
}

// Helper function to create a mock DocumentSnapshot wrapper for testing
// Note: This returns a Mock, not a DocumentSnapshot, due to sealed class restrictions
MockDocumentSnapshot createMockDocumentSnapshot({
  String? id,
  Map<String, dynamic>? data,
  bool? exists,
}) {
  return MockDocumentSnapshot(
    mockId: id ?? 'mock-doc-id',
    mockData: data,
    mockExists: exists ?? true,
  );
}

class MockFlutterLocalNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

// Setup function for test mocks
Future<void> setupTestMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Setup Firebase Core mocks if not already done
  setupFirebaseCoreMocks();
}

// Setup Firebase Core mocks
void setupFirebaseCoreMocks() {
  // This is called by other test files, so we keep it as a stub
  // The actual Firebase mocking is handled by specific test setups
}


