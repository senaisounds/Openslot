import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slotted/api/block_user_service.dart';
import 'package:slotted/utils/logger.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final blockedUsers = await BlockUserService.getBlockedUsers();
      setState(() {
        _blockedUsers = blockedUsers;
        _isLoading = false;
      });
    } catch (e) {
      Logger.e('Error loading blocked users: $e', tag: 'BlockedUsersPage');
      setState(() {
        _error = 'Failed to load blocked users';
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(String userId, String username) async {
    final confirmed = await BlockUserService.showUnblockConfirmation(context, username);
    if (!confirmed) return;

    try {
      final success = await BlockUserService.unblockUser(userId);
      if (success) {
        // Remove from local list
        setState(() {
          _blockedUsers.removeWhere((user) => user['id'] == userId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unblocked $username')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to unblock user')),
          );
        }
      }
    } catch (e) {
      Logger.e('Error unblocking user: $e', tag: 'BlockedUsersPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Blocked Users'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildBlockedUsersList(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: CupertinoColors.systemOrange,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _loadBlockedUsers,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersList() {
    if (_blockedUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_badge_minus,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            SizedBox(height: 16),
            Text(
              'No blocked users',
              style: TextStyle(
                fontSize: 18,
                color: CupertinoColors.systemGrey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Users you block will appear here',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey2,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final user = _blockedUsers[index];
        final username = user['username'] as String? ?? 'Unknown User';
        final photoUrl = user['photoUrl'] as String?;
        final userId = user['id'] as String;

        return CupertinoListTile(
          leading: CircleAvatar(
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?')
                : null,
          ),
          title: Text(username),
          subtitle: const Text('Blocked user'),
          trailing: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minSize: 0,
            onPressed: () => _unblockUser(userId, username),
            child: const Text('Unblock'),
          ),
        );
      },
    );
  }
} 