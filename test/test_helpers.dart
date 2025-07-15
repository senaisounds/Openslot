import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:slotted/common/slotted_user.dart';
import 'dart:async';

// Simple mock classes
class MockSlottedUser extends Mock implements SlottedUser {
  @override
  String get id => 'mock-slotted-user-id';
  
  @override
  String get username => 'Mock User';
  
  @override
  String get email => 'mock@test.com';
  
  @override
  String get customerID => 'mock-customer-id';
  
  @override
  String get testCustomerID => 'mock-test-customer-id';
  
  @override
  bool get isHost => true;
  
  @override
  String get phoneNumber => '+1234567890';
  
  @override
  String get photoUrl => '';
  
  @override
  String get bio => 'Mock user bio';
  
  @override
  String get twitter => '';
  
  @override
  String get instagram => '';
  
  @override
  bool get isFirstTimer => false;
  
  @override
  List<String> get openMics => [];
  
  @override
  String get pushToken => '';
  
  @override
  List<Map<String, dynamic>> get awards => [];
  
  @override
  List<String> get savedEvents => [];
  
  @override
  DateTime? get lastLogin => DateTime.now();
  
  @override
  DateTime? get createdAt => DateTime.now();
}

class MockUser extends Mock implements User {
  @override
  String get uid => 'mock-user-id';
  @override
  String? get email => 'mock@test.com';
  @override
  String? get displayName => 'Mock User';
  @override
  String? get photoURL => 'https://example.com/photo.jpg';
  @override
  bool get emailVerified => true;
  @override
  bool get isAnonymous => false;
  @override
  List<UserInfo> get providerData => [];
  @override
  String? get phoneNumber => '+1234567890';
  @override
  String? get refreshToken => 'mock-refresh-token';
  @override
  String? get tenantId => null;
  @override
  Future<void> delete() async {}
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock-id-token';
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    return MockIdTokenResult();
  }
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    return MockUserCredential();
  }
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async {
    return MockUserCredential();
  }
  @override
  Future<void> reload() async {}
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<User> unlink(String providerId) async {
    // Return a mock User (or this)
    return this;
  }
  @override
  Future<void> updateDisplayName(String? displayName) async {}
  @override
  Future<void> updateEmail(String email) async {}
  @override
  Future<void> updatePassword(String password) async {}
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {}
  @override
  Future<void> updatePhotoURL(String? photoURL) async {}
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) async {}
}

class MockUserCredential extends Mock implements UserCredential {
  @override
  User? get user => MockUser();
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
  @override
  AuthCredential? get credential => null;
  @override
  String? get operationType => null;
}

class MockIdTokenResult extends Mock implements IdTokenResult {
  @override
  DateTime? get authTime => DateTime.now();
  @override
  Map<String, dynamic>? get claims => {};
  @override
  DateTime? get expirationTime => DateTime.now().add(const Duration(hours: 1));
  @override
  DateTime? get issuedAtTime => DateTime.now();
  @override
  String? get signInProvider => 'password';
  @override
  String? get token => 'mock-id-token';
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  User? _currentUser;
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();
  
  @override
  User? get currentUser => _currentUser;
  
  void signIn(User user) {
    _currentUser = user;
    _authStateController.add(_currentUser);
  }
  
  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(_currentUser);
  }
  
  @override
  Stream<User?> authStateChanges() {
    return _authStateController.stream;
  }

  @override
  Stream<User?> idTokenChanges() {
    return _authStateController.stream;
  }

  @override
  Stream<User?> userChanges() {
    return _authStateController.stream;
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    final user = MockUser();
    signIn(user);
    return MockUserCredential();
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = MockUser();
    signIn(user);
    return MockUserCredential();
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = MockUser();
    signIn(user);
    return MockUserCredential();
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {}

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) async => [];

  @override
  FirebaseApp get app => MockFirebaseApp();

  @override
  Future<void> setSettings({
    bool? appVerificationDisabledForTesting,
    String? userAccessGroup,
    String? phoneNumber,
    String? smsCode,
    bool? forceRecaptchaFlow,
  }) async {}
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

class MockDocumentReference extends Mock implements DocumentReference {}

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
