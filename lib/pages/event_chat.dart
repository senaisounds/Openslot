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
import 'dart:math' as math;

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

class _EventChatPageState extends State<EventChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  SlottedUser? _currentUser;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  final Set<String> _typingUsers = {};
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<QuerySnapshot>? _typingSubscription;
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
  
  void _setupTypingListener() {
    _typingSubscription = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('typing')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _typingUsers.clear();
          for (final doc in snapshot.docs) {
            if (doc.id != widget.user?.uid) {
              final data = doc.data();
              final isTyping = data['isTyping'] as bool? ?? false;
              final lastUpdate = data['lastUpdate'] as Timestamp?;
              
              if (isTyping && lastUpdate != null) {
                final timeDiff = DateTime.now().difference(lastUpdate.toDate());
                if (timeDiff.inSeconds < 5) {
                  _typingUsers.add(doc.id);
                }
              }
            }
          }
        });
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
    });

    if (widget.user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user!.uid)
            .get();
        
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
      } catch (e) {
        Logger.d('Error loading current user: $e', tag: 'Event_chat');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
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
    if (widget.user == null) return;
    
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
    
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _updateTypingStatus(false);
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUser == null || _isSending) {
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
      final messageRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('messages')
          .doc();
          
      await messageRef.set({
        'text': message,
        'senderId': widget.user!.uid,
        'senderName': _currentUser!.username,
        'senderPhotoUrl': _currentUser!.photoUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'messageId': messageRef.id,
        'edited': false,
        'reactions': <String, List<String>>{},
      });

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: 10, // Placeholder
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Message $index',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
  
  Widget _buildTypingIndicator() {
    if (_typingUsers.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _typingIndicatorController ?? const AlwaysStoppedAnimation(0.0),
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.3;
                        final animationValue = ((_typingIndicatorController?.value ?? 0.0) - delay).clamp(0.0, 1.0);
                        final opacity = math.sin(animationValue * math.pi);
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: Opacity(
                            opacity: 0.3 + (opacity * 0.7),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: CupertinoColors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  _typingUsers.length == 1 
                      ? 'Someone is typing...'
                      : '${_typingUsers.length} people are typing...',
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    final time = '$hour:$minute $period';

    if (messageDate == today) {
      return 'Today, $time';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}, $time';
    }
  }
} 
