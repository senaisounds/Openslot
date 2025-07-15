// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/utils/logger.dart';

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

  // Instagram OAuth authentication
  Future<UserCredential> signInWithInstagram() async {
    try {
      // 1. Create a Custom OAuth provider for Instagram
      final provider = OAuthProvider('instagram.com');
      
      // 2. Add scopes - these allow access to user's profile data
      provider.addScope('user_profile');
      provider.addScope('user_media');
      
      // 3. Set custom parameters to identify our app
      provider.setCustomParameters({
        'auth_type': 'rerequest',
      });
      
      // 4. Sign in with pop-up (for mobile/web)
      final result = await firebaseAuth.signInWithPopup(provider);
      
      Logger.d('Instagram login successful for user: ${result.user?.uid}', tag: 'Auth');
      
      // 5. If successful, get and save the Instagram profile picture
      if (result.user != null) {
        await _saveInstagramProfilePicture(result.user!.uid, result.additionalUserInfo?.profile);
      }
      
      return result;
    } on FirebaseAuthException catch (e, stackTrace) {
      final message = _getAuthErrorMessage(e);
      Logger.e('Error signing in with Instagram: $message', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException(e.code, message, originalError: e);
    } catch (e, stackTrace) {
      Logger.e('Unexpected error signing in with Instagram: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
      throw AuthException('instagram-auth-error', 'An error occurred during Instagram login', originalError: e);
    }
  }
  
  // Save the Instagram profile picture to the user's profile
  Future<void> _saveInstagramProfilePicture(String uid, Map<String, dynamic>? profile) async {
    if (profile == null) {
      Logger.w('Instagram profile data not available', tag: 'Auth');
      return;
    }
    
    try {
      // Extract profile picture URL from Instagram data
      final profilePicUrl = profile['profile_picture_url'] ?? profile['profile_pic_url'];
      
      if (profilePicUrl == null || profilePicUrl.toString().isEmpty) {
        Logger.w('Instagram profile picture URL not found in profile data', tag: 'Auth');
        return;
      }
      
      // Get the current user data
      final userDoc = await firestore.collection('users').doc(uid).get();
      SlottedUser user;
      
      if (userDoc.exists && userDoc.data() != null) {
        // Update existing user
        user = SlottedUser.fromDocument(userDoc);
      } else {
        // Create new user
        user = SlottedUser()..id = uid;
        
        // Extract username from Instagram if available
        if (profile['username'] != null && profile['username'].toString().isNotEmpty) {
          user.username = profile['username'].toString();
        }
        
        // Save Instagram handle if available
        if (profile['username'] != null && profile['username'].toString().isNotEmpty) {
          user.instagram = profile['username'].toString();
        }
      }
      
      // Set profile picture URL from Instagram
      user.photoUrl = profilePicUrl.toString();
      
      // Update user document
      await updateUserData(user);
      
      Logger.d('Instagram profile picture saved for user $uid', tag: 'Auth');
    } catch (e, stackTrace) {
      // Don't throw for this non-critical operation, just log it
      Logger.e('Error saving Instagram profile picture: $e', tag: 'Auth', error: e, stackTrace: stackTrace);
    }
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
}
