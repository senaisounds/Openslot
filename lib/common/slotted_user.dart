import 'package:cloud_firestore/cloud_firestore.dart';

class SlottedUser {
  String bio = '';
  String? customerID;
  String? testCustomerID;
  String photoUrl = '';
  String instagram = '';
  bool isHost = false;
  List<String> openMics = [];
  String pushToken = '';
  String twitter = '';
  String username = '';
  String id = '';
  String? email;
  String? phoneNumber;
  bool isFirstTimer = true;
  DateTime? createdAt;
  DateTime? lastLogin;
  List<Map<String, dynamic>> awards = [];
  List<String> savedEvents = [];

  // Check if the user has a complete profile
  bool get hasCompleteProfile {
    return username.isNotEmpty && 
           (email != null && email!.isNotEmpty) && 
           (phoneNumber != null && phoneNumber!.isNotEmpty);
  }

  // Check if the user is a host
  bool get canHostEvents {
    return isHost;
  }

  // Get display name (username or "New User")
  String get displayName {
    return username.isNotEmpty ? username : 'New User';
  }

  // Get profile image URL (or placeholder)
  String get profileImageUrl {
    return photoUrl.isNotEmpty 
        ? photoUrl 
        : 'https://upload.wikimedia.org/wikipedia/commons/c/cd/Portrait_Placeholder_Square.png';
  }

  static SlottedUser fromDocument(DocumentSnapshot document) {
    try {
      if (document.data() == null) {
        return SlottedUser()..id = document.id;
      }
      
      final docData = document.data()! as Map<String, dynamic>;
      final slottedUser = SlottedUser();
      
      slottedUser.id = document.id;
      slottedUser.bio = docData['bio'] ?? '';
      slottedUser.customerID = docData['customerID'];
      slottedUser.testCustomerID = docData['testCustomerID'];
      slottedUser.photoUrl = docData['photoUrl'] ?? '';
      slottedUser.instagram = docData['instagram'] ?? '';
      slottedUser.isHost = docData['isHost'] ?? false;
      
      if (docData['openMics'] != null) {
        if (docData['openMics'] is List) {
          slottedUser.openMics = List<String>.from(docData['openMics']);
        } else {
          slottedUser.openMics = [];
        }
      }
      
      slottedUser.pushToken = docData['pushToken'] ?? '';
      slottedUser.twitter = docData['twitter'] ?? '';
      slottedUser.username = docData['username'] ?? '';
      slottedUser.email = docData['email'];
      slottedUser.phoneNumber = docData['phoneNumber'];
      slottedUser.isFirstTimer = docData['isFirstTimer'] ?? true;
      
      // Parse awards from document
      if (docData['awards'] != null && docData['awards'] is List) {
        slottedUser.awards = List<Map<String, dynamic>>.from(
          (docData['awards'] as List).map((award) => award as Map<String, dynamic>)
        );
      }
      
      // Parse saved events from document
      if (docData['savedEvents'] != null && docData['savedEvents'] is List) {
        slottedUser.savedEvents = List<String>.from(docData['savedEvents']);
      }
      
      if (docData['createdAt'] != null && docData['createdAt'] is Timestamp) {
        slottedUser.createdAt = (docData['createdAt'] as Timestamp).toDate();
      }
      
      if (docData['lastLogin'] != null && docData['lastLogin'] is Timestamp) {
        slottedUser.lastLogin = (docData['lastLogin'] as Timestamp).toDate();
      }

      return slottedUser;
    } catch (e) {
      throw Exception('Error creating user from document: $e');
    }
  }

  Map<String, dynamic> toDocument() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'bio': bio,
      'twitter': twitter,
      'instagram': instagram,
      'isFirstTimer': isFirstTimer,
      'customerID': customerID,
      'testCustomerID': testCustomerID,
      'isHost': isHost,
      'openMics': openMics,
      'pushToken': pushToken,
      'awards': awards,
      'savedEvents': savedEvents,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
  
  // Update user's last login time
  void updateLastLogin() {
    lastLogin = DateTime.now();
  }
  
  // Check if user has a specific permission
  bool hasPermission(String permission) {
    switch (permission) {
      case 'host_events':
        return isHost;
      case 'edit_profile':
        return true; // All users can edit their profiles
      default:
        return false;
    }
  }
}
