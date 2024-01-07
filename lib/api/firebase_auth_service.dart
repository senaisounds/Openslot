import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  // Private constructor to create a singleton instance.
  FirebaseAuthService._privateConstructor();

  // Static private instance of the class, part of the singleton pattern.
  static final FirebaseAuthService _instance =
      FirebaseAuthService._privateConstructor();

  // Factory constructor to return the singleton instance.
  factory FirebaseAuthService() {
    return _instance;
  }

  // Instance of FirebaseAuth to interact with Firebase authentication.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Getter to retrieve the current user.
  User? get currentUser => _firebaseAuth.currentUser;

  // Method to sign in a user with email and password.
  Future<void> signIn(String phoneNumber) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification completed
        print('verification completed');
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        // Handle error
        print('verification failed');
        print(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        // Code sent for manual entry
        print('code sent');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto retrieval timeout
        print('code auto retrieval timeout');
      },
    );
  }

  // Method to sign out the current user.
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}
