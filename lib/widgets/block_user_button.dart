import 'package:flutter/cupertino.dart';
import 'package:slotted/api/block_user_service.dart';
import 'package:slotted/utils/logger.dart';

class BlockUserButton extends StatefulWidget {
  final String targetUserId;
  final String? targetUsername;
  final VoidCallback? onBlock;
  final bool isBlocked;

  const BlockUserButton({
    super.key,
    required this.targetUserId,
    this.targetUsername,
    this.onBlock,
    this.isBlocked = false,
  });

  @override
  State<BlockUserButton> createState() => _BlockUserButtonState();
}

class _BlockUserButtonState extends State<BlockUserButton> {
  bool _isLoading = false;
  bool _currentBlockStatus = false;

  @override
  void initState() {
    super.initState();
    _currentBlockStatus = widget.isBlocked;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minSize: 0,
      onPressed: _isLoading ? null : () => _showBlockDialog(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CupertinoActivityIndicator(),
            )
          else
            Icon(
              _currentBlockStatus ? CupertinoIcons.person_badge_minus : CupertinoIcons.person_badge_minus,
              size: 16,
              color: _currentBlockStatus ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
            ),
          const SizedBox(width: 4),
          Text(
            _currentBlockStatus ? 'Unblock' : 'Block',
            style: TextStyle(
              fontSize: 12,
              color: _currentBlockStatus ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    final action = _currentBlockStatus ? 'Unblock' : 'Block';
    final username = widget.targetUsername ?? 'this user';
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('$action User'),
        content: Text(
          _currentBlockStatus 
            ? 'Are you sure you want to unblock $username? You will be able to see their content again.'
            : 'Are you sure you want to block $username? You will no longer see their content or receive messages from them.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: !_currentBlockStatus,
            child: Text(action),
            onPressed: () {
              Navigator.of(context).pop();
              _performBlockAction(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performBlockAction(BuildContext context) async {
    setState(() => _isLoading = true);
    
    try {
      bool success;
      if (_currentBlockStatus) {
        success = await BlockUserService.unblockUser(widget.targetUserId);
      } else {
        success = await BlockUserService.blockUser(widget.targetUserId);
      }
      
      if (success) {
        setState(() => _currentBlockStatus = !_currentBlockStatus);
        
        final action = _currentBlockStatus ? 'blocked' : 'unblocked';
        final username = widget.targetUsername ?? 'this user';
        
        // Show success confirmation
        if (mounted) {
          // Store context reference to avoid async gap issues
          final currentContext = context;
          if (currentContext.mounted) {
            showCupertinoDialog(
              context: currentContext,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Success'),
                content: Text('You have $action $username.'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }
        }
        
        // Call the onBlock callback if provided
        widget.onBlock?.call();
        
        Logger.d('User ${_currentBlockStatus ? 'blocked' : 'unblocked'}: ${widget.targetUserId}', tag: 'BlockUserButton');
      } else {
        // Show error dialog
        if (mounted) {
          // Store context reference to avoid async gap issues
          final currentContext = context;
          if (currentContext.mounted) {
            showCupertinoDialog(
              context: currentContext,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: const Text('Failed to process the block action. Please try again.'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      Logger.e('Error performing block action: $e', tag: 'BlockUserButton');
      
      // Show error dialog
      if (mounted) {
        // Store context reference to avoid async gap issues
        final currentContext = context;
        if (currentContext.mounted) {
          showCupertinoDialog(
            context: currentContext,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('An error occurred: ${e.toString()}'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 