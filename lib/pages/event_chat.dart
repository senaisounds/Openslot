import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/utils/logger.dart';
import 'dart:async';
import 'package:slotted/utils/safe_state_mixin.dart';


class EventChatPage extends StatefulWidget {
  const EventChatPage({
    super.key,
    required this.event,
    required this.user,
    this.debug = false,
  });

  final Event event;
  final User? user;
  final bool debug;

  @override
  State<EventChatPage> createState() => _EventChatPageState();
}

class _EventChatPageState extends State<EventChatPage> with TickerProviderStateMixin, SafeStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  SlottedUser? _currentUser;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  // Unused fields removed for optimization
  Timer? _typingTimer;
// Pagination
  static const int _messagesPerPage = 20;
  DocumentSnapshot? _lastDocument;
  
  // Animation controllers
  AnimationController? _sendButtonController;
  AnimationController? _typingIndicatorController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentUser();
    _setupScrollListener();
    _setupMessageListener();
    // Temporarily disable complex features that might cause issues
  }

  
  void _initializeAnimations() {
    try {
      _sendButtonController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _typingIndicatorController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );
      // Start the typing animation
      _typingIndicatorController?.repeat();
    } catch (e) {
      Logger.d('Error initializing animations: $e', tag: 'Event_chat');
    }
  }
  
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= _scrollController.position.maxScrollExtent * 0.1) {
        _loadMoreMessages();
      }
    });
  }
  
  void _setupMessageListener() {
    _messageController.addListener(() {
      // Simplified listener without animations for now
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText) {
        _sendButtonController?.forward();
        // _updateTypingStatus(true);
      } else {
        _sendButtonController?.reverse();
        // _updateTypingStatus(false);
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    if (widget.user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user!.uid)
            .get();
        
        if (mounted) {
          if (userDoc.exists) {
            setState(() {
              _currentUser = SlottedUser.fromDocument(userDoc);
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        Logger.d('Error loading current user: $e', tag: 'Event_chat');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      Query query = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_messagesPerPage);
      
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        if (snapshot.docs.length < _messagesPerPage) {
          _hasMoreMessages = false;
        }
      } else {
        _hasMoreMessages = false;
      }
    } catch (e) {
      Logger.d('Error loading more messages: $e', tag: 'Event_chat');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }
  
  void _updateTypingStatus(bool isTyping) {
    if (widget.user == null || !mounted) return;
    
    _typingTimer?.cancel();
    
    FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('typing')
        .doc(widget.user!.uid)
        .set({
      'isTyping': isTyping,
      'lastUpdate': FieldValue.serverTimestamp(),
      'username': _currentUser?.username ?? 'Unknown',
    });
    
    if (isTyping && mounted) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _updateTypingStatus(false);
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) {
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();
    _updateTypingStatus(false);
    
    setState(() {
      _isSending = true;
    });
    
    // Haptic feedback
    HapticFeedback.lightImpact();

    try {
      String? senderPhotoUrl = widget.user?.photoURL;
      String? senderName = widget.user?.displayName ?? 'Unknown';
      String? senderId = widget.user?.uid;

      // Try to get the latest photoUrl and username from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        if (data['photoUrl'] != null && (data['photoUrl'] as String).isNotEmpty) {
          senderPhotoUrl = data['photoUrl'];
        }
        if (data['username'] != null && (data['username'] as String).isNotEmpty) {
          senderName = data['username'];
        }
      }
    
      final messageRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('messages')
          .doc();
          
      await messageRef.set({
        'text': message,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'messageId': messageRef.id,
        'edited': false,
        'reactions': <String, List<String>>{},
      });

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      Logger.d('Error sending message: $e', tag: 'Event_chat');
      // Show error to user
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to send message: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Cancel the typing timer
    _typingTimer?.cancel();
    
    // Dispose animation controllers
    _sendButtonController?.dispose();
    _typingIndicatorController?.dispose();
    
    // Dispose text editing controller and focus node
    _messageController.dispose();
    _messageFocusNode.dispose();
    
    // Dispose scroll controller
    _scrollController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.backgroundDark.withValues(alpha: 0.5),
        border: null,
        middle: Text(
          'Event Chat: ${widget.event.name}',
          style: const TextStyle(color: CupertinoColors.white),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: AppColors.accent),
        ),
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                AppColors.secondary.withValues(alpha: 0.05),
                AppColors.accent.withValues(alpha: 0.05),
                AppColors.backgroundDark.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : _buildMessageList(),
              ),
              // Temporarily disable typing indicator
              // if (_typingUsers.isNotEmpty)
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          Logger.e('Error loading chat messages: ${snapshot.error}', tag: 'Event_chat');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 48,
                  color: CupertinoColors.systemRed,
                ),
                SizedBox(height: 16),
                Text(
                  'Failed to load messages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemRed,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please check your connection and try again',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }
        
        final messages = snapshot.data!.docs;
        
        // Show empty state if no messages
        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.chat_bubble_2,
                  size: 48,
                  color: CupertinoColors.systemGrey,
                ),
                SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Be the first to start the conversation!',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final currentUserId = widget.user?.uid;
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index].data() as Map<String, dynamic>;
            final isMe = msg['senderId'] == currentUserId;
            final senderName = msg['senderName'] ?? 'Unknown';
            final senderPhotoUrl = msg['senderPhotoUrl'] ?? '';
            final text = msg['text'] ?? '';
            final isHost = msg['senderId'] == widget.event.host;
            // Optionally format timestamp
            String? timeString;
            if (msg['timestamp'] != null && msg['timestamp'] is Timestamp) {
              final dt = (msg['timestamp'] as Timestamp).toDate();
              timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: senderPhotoUrl.isNotEmpty ? NetworkImage(senderPhotoUrl) : null,
                      child: senderPhotoUrl.isEmpty ? const Icon(CupertinoIcons.person, size: 18) : null,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                              if (isHost) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEE7D30), // AppColors.slottedOrange
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'HOST',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.accent.withValues(alpha: 0.7)
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: isMe ? Colors.white : CupertinoColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (timeString != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
                            child: Text(
                              timeString,
                              style: const TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.systemGrey2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: widget.user?.photoURL != null && widget.user!.photoURL!.isNotEmpty
                          ? NetworkImage(widget.user!.photoURL!)
                          : null,
                      child: (widget.user?.photoURL == null || widget.user!.photoURL!.isEmpty)
                          ? const Icon(CupertinoIcons.person, size: 18)
                          : null,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              placeholder: 'Type a message...',
              placeholderStyle: TextStyle(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.7),
              ),
              style: const TextStyle(color: CupertinoColors.white),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isSending ? null : _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isSending 
                    ? CupertinoColors.systemGrey.withValues(alpha: 0.3)
                    : AppColors.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isSending 
                      ? CupertinoColors.systemGrey.withValues(alpha: 0.5)
                      : AppColors.accent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: _isSending
                  ? const CupertinoActivityIndicator(radius: 8)
                  : const Icon(
                      CupertinoIcons.arrow_up,
                      color: AppColors.accent,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }


} 
