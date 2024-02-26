import 'package:cloud_firestore/cloud_firestore.dart';

class SlottedUser {
  String bio = '';
  String? customerID;
  String photoUrl = '';
  String instagram = '';
  bool isHost = false;
  List<String> openMics = [];
  String pushToken = '';
  String twitter = '';
  String username = '';

  static SlottedUser fromDocument(DocumentSnapshot document) {
    if (document.data() == null) {
      return SlottedUser();
    }
    final docData = document.data()! as Map<String, dynamic>;

    final slottedUser = SlottedUser();
    slottedUser.bio = docData['bio'] ?? '';
    slottedUser.customerID = docData['customerID'];
    slottedUser.photoUrl = docData['photoUrl'] ?? '';
    slottedUser.instagram = docData['instagram'] ?? '';
    slottedUser.isHost = docData['isHost'] ?? false;
    slottedUser.openMics = (docData['openMics'] ?? []).cast<String>();
    slottedUser.pushToken = docData['pushToken'] ?? '';
    slottedUser.twitter = docData['twitter'] ?? '';
    slottedUser.username = docData['username'] ?? '';

    return slottedUser;
  }
}
