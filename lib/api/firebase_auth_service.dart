// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:slotted/widgets/code_verification_page.dart';

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

  // Method to format a phone number to E.164 format.
  String formattedPhone(String phoneNumber) {
    return '+1${phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}';
  }

  // Method to sign in a user with email and password.
  Future<void> signIn(String rawPhoneNumber, BuildContext context) async {
    final phoneNumber = formattedPhone(rawPhoneNumber);
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification completed
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        // Handle error
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(e.message ?? e.toString()),
            actions: [
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        // Code sent for manual entry
        Navigator.of(context).push(CupertinoPageRoute(
          builder: (context) =>
              CodeVerificationPage(verificationId: verificationId),
        ));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto retrieval timeout
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Verifcation timed out.'),
            actions: [
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to sign out the current user.
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}
