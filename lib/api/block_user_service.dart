import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:slotted/utils/logger.dart';

/// Service to handle user blocking functionality
class BlockUserService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  /// Block a user
  static Future<bool> blockUser(String targetUserId) async {
    try {
      Logger.d('Attempting to block user: $targetUserId', tag: 'BlockUser');
      
      final result = await _functions.httpsCallable('blockUser').call({
        'targetUserId': targetUserId,
        'action': 'block',
      });
      
      final data = result.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      
      if (success) {
        Logger.d('Successfully blocked user: $targetUserId', tag: 'BlockUser');
        return true;
      } else {
        Logger.e('Failed to block user: $targetUserId', tag: 'BlockUser');
        return false;
      }
    } catch (e) {
      Logger.e('Error blocking user: $e', tag: 'BlockUser');
      rethrow;
    }
  }
  
  /// Unblock a user
  static Future<bool> unblockUser(String targetUserId) async {
    try {
      Logger.d('Attempting to unblock user: $targetUserId', tag: 'BlockUser');
      
      final result = await _functions.httpsCallable('blockUser').call({
        'targetUserId': targetUserId,
        'action': 'unblock',
      });
      
      final data = result.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      
      if (success) {
        Logger.d('Successfully unblocked user: $targetUserId', tag: 'BlockUser');
        return true;
      } else {
        Logger.e('Failed to unblock user: $targetUserId', tag: 'BlockUser');
        return false;
      }
    } catch (e) {
      Logger.e('Error unblocking user: $e', tag: 'BlockUser');
      rethrow;
    }
  }
  
  /// Check if a user is blocked
  static Future<bool> isUserBlocked(String targetUserId) async {
    try {
      Logger.d('Checking if user is blocked: $targetUserId', tag: 'BlockUser');
      
      final result = await _functions.httpsCallable('isUserBlocked').call({
        'targetUserId': targetUserId,
      });
      
      final data = result.data as Map<String, dynamic>;
      final isBlocked = data['isBlocked'] as bool? ?? false;
      
      Logger.d('User blocked status: $isBlocked', tag: 'BlockUser');
      return isBlocked;
    } catch (e) {
      Logger.e('Error checking block status: $e', tag: 'BlockUser');
      return false;
    }
  }
  
  /// Get list of blocked users
  static Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      Logger.d('Getting blocked users list', tag: 'BlockUser');
      
      final result = await _functions.httpsCallable('getBlockedUsers').call({});
      
      final data = result.data as Map<String, dynamic>;
      final blockedUsers = data['blockedUsers'] as List<dynamic>? ?? [];
      
      Logger.d('Retrieved ${blockedUsers.length} blocked users', tag: 'BlockUser');
      return blockedUsers.map((user) => user as Map<String, dynamic>).toList();
    } catch (e) {
      Logger.e('Error getting blocked users: $e', tag: 'BlockUser');
      return [];
    }
  }
  
  /// Show block user confirmation dialog
  static Future<bool> showBlockConfirmation(BuildContext context, String username) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block $username? You will no longer see their content or receive messages from them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Show unblock user confirmation dialog
  static Future<bool> showUnblockConfirmation(BuildContext context, String username) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock $username? You will be able to see their content again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    ) ?? false;
  }
} 