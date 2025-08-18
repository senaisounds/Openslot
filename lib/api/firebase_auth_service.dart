// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/utils/logger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

/// Custom authentication exception for better error handling
class AuthException implements Exception {
  final String code;
  final String message;
  final Object? originalError;

  AuthException(this.code, this.message, {this.originalError});

  @override
  String toString() => 'AuthException($code): $message';
}

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
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  
  // Instance of Firestore to interact with user data
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Maximum number of retries for transient errors
  static const int _maxRetries = 3;

  // Getter to retrieve the current user.
  User? get currentUser => firebaseAuth.currentUser;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // Method to format a phone number to E.164 format.
  String formattedPhone(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '';
    
    // Add US country code if not present
    if (digitsOnly.length == 10) {
      return '+1$digitsOnly';
    } else if (digitsOnly.startsWith('1') && digitsOnly.length == 11) {
      return '+$digitsOnly';
    } else if (digitsOnly.startsWith('+')) {
      return digitsOnly;
    } else {
      return '+1$digitsOnly';
    }
  }

  /// Convert Firebase auth exceptions to user-friendly error messages
  String _getAuthErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'email-already-in-use':
          return 'This email address is already associated with an account.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Please choose a stronger password.';
        case 'operation-not-allowed':
          return 'This sign-in method is not allowed. Please contact support.';
        case 'invalid-verification-code':
          return 'The verification code is invalid. Please try again.';
        case 'invalid-verification-id':
          return 'The verification session has expired. Please request a new code.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in method.';
        case 'invalid-credential':
          return 'The sign-in credentials are invalid. Please try again.';
        case 'network-request-failed':
          return 'A network error occurred. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many sign-in attempts. Please try again later.';
        default:
          return 'Authentication error: ${e.message ?? e.code}';
      }
    } else if (e is FirebaseException) {
      return 'Firebase error: ${e.message ?? e.code}';
    }
    return 'Authentication error: $e';
  }
  
  // Get SlottedUser from Firestore
  Future<SlottedUser?> getSlottedUser(String uid) async {
    if (uid.isEmpty) {
      Logger.e('Error getting user: uid is empty', tag: 'Auth');
      return null;
    }

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final docSnapshot = await firestore.collection('users').doc(uid).get();
        if (!docSnapshot.exists) {
          return null;
        }
        return SlottedUser.fromDocument(docSnapshot);
      } catch (e, stackTrace) {
        final isLastAttempt = attempt == _maxRetries - 1;
        final errorMsg = 'Error getting user (attempt ${attempt + 1}/$_maxRetries): $e';
        
        if (isLastAttempt) {
          Logger.e(errorMsg, tag: 'Auth', error: e, stackTrace: stackTrace);
          return null;
        } else {
          Logger.w(errorMsg, tag: 'Auth');
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }
    return null;
  }
  
  // Create or update SlottedUser in Firestore
  Future<void> updateUserData(SlottedUser user) async {
    if (user.id.isEmpty) {
      throw AuthException('invalid-user-id', 'User ID cannot be empty');
    }

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        await firestore.collection('users').doc(user.id).set(
          user.toDocument(),
          SetOptions(merge: true),
        );
        return;
      } catch (e, stackTrace) {
        final isLastAttempt = attempt == _maxRetries - 1;
        final errorMsg = 'Error updating user data (attempt ${attempt + 1}/$_maxRetries): $e';
        
        if (isLastAttempt) {
          Logger.e(errorMsg, tag: 'Auth', error: e, stackTrace: stackTrace);
          throw AuthException('update-user-failed', 'Failed to update user data', originalError: e);
        } else {
          Logger.w(errorMsg, tag: 'Auth');
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    if (email.isEmpty) {
      throw AuthException('empty-email', 'Email cannot be empty');
    }
    if (password.isEmpty) {
      throw AuthException('empty-password', 'Password cannot be empty');
    }

    try {
      return await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      final message = _getAuthErrorMessage(e);
      Logger.e('Error signing in with email: $message', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException(e.code, message, originalError: e);
    } catch (e, stackTrace) {
      Logger.e('Unexpected error signing in with email: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException('unknown', 'An unexpected error occurred', originalError: e);
    }
  }
  
  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    if (email.isEmpty) {
      throw AuthException('empty-email', 'Email cannot be empty');
    }
    if (password.isEmpty) {
      throw AuthException('empty-password', 'Password cannot be empty');
    }
    if (password.length < 6) {
      throw AuthException('weak-password', 'Password must be at least 6 characters');
    }

    try {
      return await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      final message = _getAuthErrorMessage(e);
      Logger.e('Error creating user with email: $message', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException(e.code, message, originalError: e);
    } catch (e, stackTrace) {
      Logger.e('Unexpected error creating user: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException('unknown', 'An unexpected error occurred', originalError: e);
    }
  }
  
  // Sign in with phone number
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    if (phoneNumber.isEmpty) {
      throw AuthException('empty-phone', 'Phone number cannot be empty');
    }

    final formattedNum = formattedPhone(phoneNumber);
    if (formattedNum.length < 10) {
      throw AuthException('invalid-phone', 'Invalid phone number format');
    }

    try {
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedNum,
        verificationCompleted: verificationCompleted,
        verificationFailed: (FirebaseAuthException e) {
          Logger.e('Phone verification failed: ${e.message}', tag: 'Auth', error: e);
          verificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          Logger.d('Verification code sent to $phoneNumber', tag: 'Auth');
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          Logger.d('Verification code auto-retrieval timed out', tag: 'Auth');
          codeAutoRetrievalTimeout(verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      final message = _getAuthErrorMessage(e);
      Logger.e('Error in phone verification: $message', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException(e.code, message, originalError: e);
    } catch (e, stackTrace) {
      Logger.e('Unexpected error in phone verification: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException('phone-auth-error', 'An error occurred during phone verification', originalError: e);
    }
  }
  
  // Verify phone code
  Future<UserCredential> verifyPhoneCode(String verificationId, String smsCode) async {
    if (verificationId.isEmpty) {
      throw AuthException('empty-verification-id', 'Verification ID cannot be empty');
    }
    if (smsCode.isEmpty) {
      throw AuthException('empty-sms-code', 'SMS code cannot be empty');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e, stackTrace) {
      final message = _getAuthErrorMessage(e);
      Logger.e('Error verifying phone code: $message', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException(e.code, message, originalError: e);
    } catch (e, stackTrace) {
      Logger.e('Unexpected error verifying phone code: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException('verification-error', 'Failed to verify SMS code', originalError: e);
    }
  }

  // Method to sign out the current user.
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
      Logger.i('User signed out successfully', tag: 'Auth');
    } catch (e, stackTrace) {
      Logger.e('Error signing out: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException('sign-out-failed', 'Failed to sign out', originalError: e);
    }
  }
  
  // Check if user exists in Firestore by phone number
  Future<DocumentSnapshot?> getUserByPhone(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      Logger.e('Error getting user by phone: Phone number is empty', tag: 'Auth');
      return null;
    }

    try {
      final formattedNumber = formattedPhone(phoneNumber);
      final querySnapshot = await firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedNumber)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return querySnapshot.docs.first;
    } catch (e, stackTrace) {
      Logger.e('Error getting user by phone: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  // Update user's last login time
  Future<void> updateLastLogin(String uid) async {
    if (uid.isEmpty) {
      Logger.e('Error updating last login: User ID is empty', tag: 'Auth');
      return;
    }

    try {
      await firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      Logger.d('Updated last login for user $uid', tag: 'Auth');
    } catch (e, stackTrace) {
      // Don't throw for this non-critical operation, just log it
      Logger.e('Error updating last login: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
    }
  }
  
  // Save an event to user's saved events
  Future<void> saveEvent(String uid, String eventId) async {
    if (uid.isEmpty) {
      throw AuthException('invalid-user-id', 'User ID cannot be empty');
    }
    if (eventId.isEmpty) {
      throw AuthException('invalid-event-id', 'Event ID cannot be empty');
    }

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        // First check if the user document exists and has a savedEvents field
        final userDoc = await firestore.collection('users').doc(uid).get();
        
        if (!userDoc.exists) {
          Logger.e('User document does not exist for $uid', tag: 'Auth');
          throw AuthException('user-not-found', 'User document not found');
        }
        
        final userData = userDoc.data();
        if (userData == null) {
          Logger.e('User data is null for $uid', tag: 'Auth');
          throw AuthException('user-data-null', 'User data is null');
        }
        
        // If the user doesn't have a savedEvents field yet, create it
        if (!userData.containsKey('savedEvents')) {
          Logger.d('Creating savedEvents array for user $uid', tag: 'Auth');
          await firestore.collection('users').doc(uid).set({
            'savedEvents': [eventId]
          }, SetOptions(merge: true));
        } else {
          // Otherwise just add to the existing array
          await firestore.collection('users').doc(uid).update({
            'savedEvents': FieldValue.arrayUnion([eventId]),
          });
        }
        
        Logger.d('Event $eventId saved for user $uid', tag: 'Auth');
        return;
      } catch (e, stackTrace) {
        final isLastAttempt = attempt == _maxRetries - 1;
        final errorMsg = 'Error saving event (attempt ${attempt + 1}/$_maxRetries): $e';
        
        if (isLastAttempt) {
          Logger.e(errorMsg, tag: 'Auth', error: e, stackTrace: stackTrace);
          if (e is AuthException) rethrow;
          throw AuthException('save-event-failed', 'Failed to save event', originalError: e);
        } else {
          Logger.w(errorMsg, tag: 'Auth');
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }
  }
  
  // Remove an event from user's saved events
  Future<void> unsaveEvent(String uid, String eventId) async {
    if (uid.isEmpty) {
      throw AuthException('invalid-user-id', 'User ID cannot be empty');
    }
    if (eventId.isEmpty) {
      throw AuthException('invalid-event-id', 'Event ID cannot be empty');
    }

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        await firestore.collection('users').doc(uid).update({
          'savedEvents': FieldValue.arrayRemove([eventId]),
        });
        Logger.d('Event $eventId removed from saved for user $uid', tag: 'Auth');
        return;
      } catch (e, stackTrace) {
        final isLastAttempt = attempt == _maxRetries - 1;
        final errorMsg = 'Error removing saved event (attempt ${attempt + 1}/$_maxRetries): $e';
        
        if (isLastAttempt) {
          Logger.e(errorMsg, tag: 'Auth', error: e, stackTrace: stackTrace);
          throw AuthException('unsave-event-failed', 'Failed to remove saved event', originalError: e);
        } else {
          Logger.w(errorMsg, tag: 'Auth');
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }
  }
  
  // Check if event is saved by user
  Future<bool> isEventSaved(String uid, String eventId) async {
    if (uid.isEmpty || eventId.isEmpty) {
      Logger.w('Invalid parameters checking if event is saved. uid: $uid, eventId: $eventId', tag: 'Auth');
      return false;
    }

    try {
      Logger.d('Checking if event $eventId is saved for user $uid', tag: 'Auth');
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        Logger.d('User document does not exist for $uid', tag: 'Auth');
        return false;
      }
      
      final userData = userDoc.data();
      if (userData == null) {
        Logger.d('User data is null for $uid', tag: 'Auth');
        return false;
      }
      
      if (!userData.containsKey('savedEvents')) {
        Logger.d('No savedEvents field in user data for $uid', tag: 'Auth');
        return false;
      }
      
      final savedEvents = List<String>.from(userData['savedEvents'] ?? []);
      final isSaved = savedEvents.contains(eventId);
      Logger.d('Event $eventId is${isSaved ? '' : ' not'} saved for user $uid.', tag: 'Auth');
      return isSaved;
    } catch (e, stackTrace) {
      Logger.e('Error checking if event is saved: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Sign in with Apple - Updated to meet Guideline 4.8 requirements
  Future<UserCredential> signInWithApple() async {
    try {
      // Generate a random nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple Sign In with proper configuration for privacy options
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        // Web authentication options for proper Apple Sign In flow
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.openslot.app',
          redirectUri: Uri.parse('https://open-mic-5cc8e.firebaseapp.com/__/auth/handler'),
        ),
      );

      // Create OAuthProvider for Apple
      final oauthProvider = OAuthProvider('apple.com');
      final credential = oauthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,

        rawNonce: rawNonce,
      );

      // Sign in with Firebase
      final userCredential = await firebaseAuth.signInWithCredential(credential);
      
      // Handle user data creation/update with minimal data collection
      if (userCredential.user != null) {
        await _handleAppleSignInUserData(userCredential.user!, appleCredential);
      }
      
      Logger.d('Apple Sign In successful for user: ${userCredential.user?.uid}', tag: 'Auth');
      
      return userCredential;
    } on FirebaseAuthException catch (e, stackTrace) {
      final message = _getAuthErrorMessage(e);
      Logger.e('Error signing in with Apple: $message', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException(e.code, message, originalError: e);
    } catch (e, stackTrace) {
      Logger.e('Unexpected error signing in with Apple: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException('apple-auth-error', 'An error occurred during Apple Sign In', originalError: e);
    }
  }

  // Handle Apple Sign In user data with minimal collection
  Future<void> _handleAppleSignInUserData(User user, AuthorizationCredentialAppleID appleCredential) async {
    try {
      // Check if user exists in Firestore
      SlottedUser? slottedUser = await getSlottedUser(user.uid);
      
      if (slottedUser == null) {
        // Create new user with minimal data collection
        slottedUser = SlottedUser()
          ..id = user.uid
          ..createdAt = DateTime.now()
          ..lastLogin = DateTime.now()
          ..isHost = false;
        
        // Only collect name and email as required by Guideline 4.8
        if (appleCredential.givenName != null && appleCredential.familyName != null) {
          slottedUser.username = '${appleCredential.givenName} ${appleCredential.familyName}'.trim();
        }
        
        // Handle email - respect user's privacy choice
        if (appleCredential.email != null && appleCredential.email!.isNotEmpty) {
          slottedUser.email = appleCredential.email!;
        }
        
        // No additional data collection for advertising purposes
        // No tracking of user interactions without explicit consent
        
        await updateUserData(slottedUser);
        Logger.d('Created new user from Apple Sign In: ${user.uid}', tag: 'Auth');
      } else {
        // Update existing user's last login time only
        await updateLastLogin(user.uid);
        Logger.d('Updated existing user login time: ${user.uid}', tag: 'Auth');
      }
    } catch (e, stackTrace) {
      // Don't fail the sign-in process for data handling errors
      Logger.e('Error handling Apple Sign In user data: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
    }
  }

  // Generate a random nonce for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // SHA256 hash of the nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }


  
  // Check if email exists in Firestore
  Future<bool> doesEmailExist(String email) async {
    if (email.isEmpty) {
      return false;
    }
    
    try {
      // TODO: Replace deprecated fetchSignInMethodsForEmail with proper alternative
      // For now, using a simple email validation approach
      return email.contains('@') && email.contains('.');
    } catch (e) {
      Logger.e('Error checking if email exists: $e', tag: 'Auth');
      return false;
    }
  }

  // Delete user data from Firestore
  Future<void> deleteUserData(String uid) async {
    if (uid.isEmpty) {
      throw AuthException('invalid-user-id', 'User ID cannot be empty');
    }

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        // Delete user document from Firestore
        await firestore.collection('users').doc(uid).delete();
        Logger.d('User data deleted for user $uid', tag: 'Auth');
        return;
      } catch (e, stackTrace) {
        final isLastAttempt = attempt == _maxRetries - 1;
        final errorMsg = 'Error deleting user data (attempt ${attempt + 1}/$_maxRetries): $e';
        
        if (isLastAttempt) {
          Logger.e(errorMsg, tag: 'Auth', error: e, stackTrace: stackTrace);
          throw AuthException('delete-user-data-failed', 'Failed to delete user data', originalError: e);
        } else {
          Logger.w(errorMsg, tag: 'Auth');
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }
  }

  // Delete the current user from Firebase Auth
  Future<void> deleteUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException('no-current-user', 'No user is currently signed in');
    }

    try {
      await user.delete();
      Logger.d('User deleted from Firebase Auth: ${user.uid}', tag: 'Auth');
    } on FirebaseAuthException catch (e, stackTrace) {
      final message = _getAuthErrorMessage(e);
      Logger.e('Error deleting user: $message', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException(e.code, message, originalError: e);
    } catch (e, stackTrace) {
      Logger.e('Unexpected error deleting user: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException('delete-user-failed', 'An unexpected error occurred while deleting user', originalError: e);
    }
  }
}
