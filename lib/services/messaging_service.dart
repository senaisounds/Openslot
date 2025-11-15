import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:slotted/models/enhanced_notification_types.dart';
import 'package:slotted/utils/logger.dart';

/// Service for in-app messaging between hosts and attendees
class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  static MessagingService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Message stream controllers for real-time updates
  final Map<String, StreamController<List<Message>>> _messageControllers = {};
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  MessagingService._internal();

  /// Send a message to an event conversation
  Future<void> sendMessage({
    required String eventId,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? replyToId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final message = Message(
        id: '', // Will be set by Firestore
        eventId: eventId,
        senderId: user.uid,
        senderName: user.displayName ?? 'User',
        senderAvatar: user.photoURL,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        replyToId: replyToId,
      );

      // Save message to Firestore
      final docRef = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .add(message.toMap());

      // Update last message timestamp for the event
      await _firestore
          .collection('events')
          .doc(eventId)
          .update({
            'lastMessageAt': FieldValue.serverTimestamp(),
            'lastMessage': content.length > 100 
                ? '${content.substring(0, 100)}...' 
                : content,
          });

      // Send notifications to other participants
      await _notifyEventParticipants(eventId, message, docRef.id);

      Logger.d('Message sent successfully', tag: 'MessagingService');
    } catch (e) {
      Logger.e('Error sending message: $e', tag: 'MessagingService');
      rethrow;
    }
  }

  /// Send a broadcast message to all attendees (host only)
  Future<void> sendBroadcastMessage({
    required String eventId,
    required String content,
    bool urgent = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify user is the host
      final event = await _firestore.collection('events').doc(eventId).get();
      if (!event.exists || event.data()!['hostId'] != user.uid) {
        throw Exception('Only hosts can send broadcast messages');
      }

      final message = Message(
        id: '',
        eventId: eventId,
        senderId: user.uid,
        senderName: user.displayName ?? 'Host',
        senderAvatar: user.photoURL,
        content: content,
        type: MessageType.broadcast,
        timestamp: DateTime.now(),
        isUrgent: urgent,
      );

      // Save broadcast message
      final docRef = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .add(message.toMap());

      // Create individual notifications for all attendees
      await _notifyAllAttendees(eventId, message, docRef.id);

      Logger.d('Broadcast message sent successfully', tag: 'MessagingService');
    } catch (e) {
      Logger.e('Error sending broadcast message: $e', tag: 'MessagingService');
      rethrow;
    }
  }

  /// Upload and send an image message
  Future<void> sendImageMessage({
    required String eventId,
    required File imageFile,
    String caption = '',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload image to Firebase Storage
      final fileName = 'messages/$eventId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadTask = _storage.ref().child(fileName).putFile(imageFile);
      
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Send message with image
      await sendMessage(
        eventId: eventId,
        content: caption.isNotEmpty ? caption : 'Shared an image',
        type: MessageType.image,
        imageUrl: imageUrl,
      );

      Logger.d('Image message sent successfully', tag: 'MessagingService');
    } catch (e) {
      Logger.e('Error sending image message: $e', tag: 'MessagingService');
      rethrow;
    }
  }

  /// React to a message with an emoji
  Future<void> reactToMessage({
    required String eventId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reactionRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .doc(user.uid);

      await reactionRef.set({
        'userId': user.uid,
        'emoji': emoji,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Logger.d('Reaction added successfully', tag: 'MessagingService');
    } catch (e) {
      Logger.e('Error adding reaction: $e', tag: 'MessagingService');
      rethrow;
    }
  }

  /// Get messages stream for an event
  Stream<List<Message>> getMessagesStream(String eventId) {
    if (!_messageControllers.containsKey(eventId)) {
      _setupMessageStream(eventId);
    }
    return _messageControllers[eventId]!.stream;
  }

  /// Setup real-time message stream for an event
  void _setupMessageStream(String eventId) {
    final controller = StreamController<List<Message>>.broadcast();
    _messageControllers[eventId] = controller;

    final subscription = _firestore
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            final messages = snapshot.docs
                .map((doc) => Message.fromMap(doc.data(), doc.id))
                .toList();
            controller.add(messages);
          },
          onError: (error) {
            Logger.e('Error in message stream: $error', tag: 'MessagingService');
            controller.addError(error);
          },
        );

    _messageSubscriptions[eventId] = subscription;
  }

  /// Get message reactions
  Future<List<MessageReaction>> getMessageReactions(String eventId, String messageId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .get();

      return snapshot.docs
          .map((doc) => MessageReaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Logger.e('Error getting reactions: $e', tag: 'MessagingService');
      return [];
    }
  }

  /// Mark messages as read for current user
  Future<void> markMessagesAsRead(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('readStatus')
          .doc(user.uid)
          .set({
            'lastReadAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
          });
    } catch (e) {
      Logger.e('Error marking messages as read: $e', tag: 'MessagingService');
    }
  }

  /// Get unread message count for an event
  Future<int> getUnreadMessageCount(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      // Get last read timestamp
      final readDoc = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('readStatus')
          .doc(user.uid)
          .get();

      final lastReadAt = readDoc.exists 
          ? (readDoc.data()!['lastReadAt'] as Timestamp?)?.toDate()
          : null;

      // Count messages after last read time
      Query query = _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages');

      if (lastReadAt != null) {
        query = query.where('timestamp', isGreaterThan: lastReadAt);
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      Logger.e('Error getting unread count: $e', tag: 'MessagingService');
      return 0;
    }
  }

  /// Notify event participants about new message
  Future<void> _notifyEventParticipants(String eventId, Message message, String messageId) async {
    try {
      // Get all attendees and host
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return;

      final eventData = eventDoc.data()!;
      final hostId = eventData['hostId'] as String;
      final attendees = List<String>.from(eventData['attendees'] ?? []);

      // Create list of users to notify (exclude sender)
      final usersToNotify = <String>{};
      usersToNotify.add(hostId);
      usersToNotify.addAll(attendees);
      usersToNotify.remove(message.senderId); // Don't notify sender

      // Send push notifications
      for (final userId in usersToNotify) {
        await _sendMessageNotification(userId, eventId, message);
      }
    } catch (e) {
      Logger.e('Error notifying participants: $e', tag: 'MessagingService');
    }
  }

  /// Notify all attendees about broadcast message
  Future<void> _notifyAllAttendees(String eventId, Message message, String messageId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return;

      final attendees = List<String>.from(eventDoc.data()!['attendees'] ?? []);
      final eventName = eventDoc.data()!['name'] ?? 'Event';

      // Send high-priority notifications to all attendees
      for (final attendeeId in attendees) {
        final notification = NotificationTemplates.hostMessage(
          eventId: eventId,
          eventName: eventName,
          hostName: message.senderName,
          message: message.content,
          userId: attendeeId,
        );

        // Save notification to Firestore for in-app display
        await _firestore
            .collection('notifications')
            .add(notification.toMap());
      }
    } catch (e) {
      Logger.e('Error notifying all attendees: $e', tag: 'MessagingService');
    }
  }

  /// Send push notification for new message
  Future<void> _sendMessageNotification(String userId, String eventId, Message message) async {
    try {
      // Create notification document for Firebase Functions to send push notification
      await _firestore.collection('pushNotifications').add({
        'userId': userId,
        'title': 'New message from ${message.senderName}',
        'body': message.content.length > 100 
            ? '${message.content.substring(0, 100)}...'
            : message.content,
        'data': {
          'type': 'message',
          'eventId': eventId,
          'messageId': message.id,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.e('Error sending message notification: $e', tag: 'MessagingService');
    }
  }

  /// Clean up streams when no longer needed
  void disposeMessageStream(String eventId) {
    _messageSubscriptions[eventId]?.cancel();
    _messageSubscriptions.remove(eventId);
    
    _messageControllers[eventId]?.close();
    _messageControllers.remove(eventId);
  }

  /// Clean up all streams
  void dispose() {
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();

    for (final controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();
  }
}

/// Message model
class Message {
  final String id;
  final String eventId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? imageUrl;
  final String? replyToId;
  final bool isUrgent;
  final bool isDeleted;

  const Message({
    required this.id,
    required this.eventId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.timestamp,
    this.imageUrl,
    this.replyToId,
    this.isUrgent = false,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
      'replyToId': replyToId,
      'isUrgent': isUrgent,
      'isDeleted': isDeleted,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      eventId: map['eventId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatar: map['senderAvatar'],
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      imageUrl: map['imageUrl'],
      replyToId: map['replyToId'],
      isUrgent: map['isUrgent'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}

/// Message reaction model
class MessageReaction {
  final String userId;
  final String emoji;
  final DateTime timestamp;

  const MessageReaction({
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  factory MessageReaction.fromMap(Map<String, dynamic> map) {
    return MessageReaction(
      userId: map['userId'] ?? '',
      emoji: map['emoji'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

/// Message types
enum MessageType {
  text,
  image,
  broadcast,
  system,
}
