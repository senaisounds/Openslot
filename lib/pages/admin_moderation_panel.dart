import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/utils/logger.dart';

class AdminModerationPanel extends StatefulWidget {
  const AdminModerationPanel({super.key});

  @override
  State<AdminModerationPanel> createState() => _AdminModerationPanelState();
}

class _AdminModerationPanelState extends State<AdminModerationPanel> {
  List<Map<String, dynamic>> _pendingReports = [];
  List<Map<String, dynamic>> _reviewedReports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadReports();
  }

  Future<void> _checkAuthAndLoadReports() async {
    if (!mounted) return;
    
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      if (mounted) {
        setState(() {
          _error = 'Authentication required. Please sign in to access admin panel.';
          _isLoading = false;
        });
      }
      return;
    }
    
    Logger.d('User authenticated: ${auth.currentUser?.uid}', tag: 'AdminModeration');
    await _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final functions = FirebaseFunctions.instance;
      
      // Check if user is authenticated
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        if (mounted) {
          setState(() {
            _error = 'Authentication required. Please sign in to access admin panel.';
            _isLoading = false;
          });
        }
        return;
      }
      
      // Get pending reports with error handling
      List<dynamic> pendingReports = [];
      try {
        final pendingResult = await functions.httpsCallable('getPendingReports').call({});
        final pendingData = pendingResult.data as Map<String, dynamic>;
        pendingReports = pendingData['reports'] as List<dynamic>? ?? [];
      } catch (e) {
        Logger.w('Failed to load pending reports: $e', tag: 'AdminModeration');
        // Continue with empty list instead of crashing
      }
      
      // Get reviewed reports with error handling
      List<dynamic> reviewedReports = [];
      try {
        final reviewedResult = await functions.httpsCallable('getReviewedReports').call({});
        final reviewedData = reviewedResult.data as Map<String, dynamic>;
        reviewedReports = reviewedData['reports'] as List<dynamic>? ?? [];
      } catch (e) {
        Logger.w('Failed to load reviewed reports: $e', tag: 'AdminModeration');
        // Continue with empty list instead of crashing
      }
      
      if (mounted) {
        setState(() {
          _pendingReports = pendingReports.map((r) => r as Map<String, dynamic>).toList();
          _reviewedReports = reviewedReports.map((r) => r as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.e('Error loading reports: $e', tag: 'AdminModeration');
      
      String errorMessage = 'Failed to load reports';
      if (e.toString().contains('unauthenticated')) {
        errorMessage = 'Authentication required. Please sign in to access admin panel.';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = 'Access denied. Admin privileges required.';
      } else if (e.toString().contains('internal')) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.toString().contains('not-found')) {
        errorMessage = 'Admin functions not configured. Contact system administrator.';
      }
      
      if (mounted) {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reviewReport(String reportId, String action, String? notes) async {
    try {
      // Check if user is authenticated
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please sign in to access admin panel.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final functions = FirebaseFunctions.instance;
      
      await functions.httpsCallable('reviewReport').call({
        'reportId': reportId,
        'action': action,
        'notes': notes ?? '',
      });
      
      // Reload reports after review
      await _loadReports();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report reviewed: $action'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.e('Error reviewing report: $e', tag: 'AdminModeration');
      
      String errorMessage = 'Error reviewing report';
      if (e.toString().contains('unauthenticated')) {
        errorMessage = 'Authentication required. Please sign in to access admin panel.';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = 'Access denied. Admin privileges required.';
      } else if (e.toString().contains('internal')) {
        errorMessage = 'Server error. Please try again later.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showReviewDialog(Map<String, dynamic> report) async {
    String? selectedAction;
    final notesController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review Report: ${report['reportType']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Content Type: ${report['contentType']}'),
            Text('Content ID: ${report['contentId']}'),
            Text('Reported by: ${report['reporterId']}'),
            Text('Description: ${report['description']}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedAction,
              decoration: const InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'no_action', child: Text('No Action')),
                DropdownMenuItem(value: 'warning', child: Text('Send Warning')),
                DropdownMenuItem(value: 'removed', child: Text('Remove Content')),
              ],
              onChanged: (value) => selectedAction = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Review Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: selectedAction == null ? null : () async {
              Navigator.of(context).pop();
              await _reviewReport(report['id'], selectedAction!, notesController.text.trim());
            },
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Content Moderation'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildReportsList(),
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
            onPressed: _loadReports,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          CupertinoSlidingSegmentedControl<int>(
            groupValue: 0,
            onValueChanged: (value) {
              // Handle tab changes if needed
            },
            children: {
              0: Text('Pending (${_pendingReports.length})'),
              1: Text('Reviewed (${_reviewedReports.length})'),
            },
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingReports(),
                _buildReviewedReports(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReports() {
    if (_pendingReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle,
              size: 64,
              color: CupertinoColors.systemGreen,
            ),
            SizedBox(height: 16),
            Text(
              'No pending reports',
              style: TextStyle(
                fontSize: 18,
                color: CupertinoColors.systemGrey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All reports have been reviewed within 24 hours',
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
      itemCount: _pendingReports.length,
      itemBuilder: (context, index) {
        final report = _pendingReports[index];
        final timestamp = DateTime.parse(report['timestamp']);
        final hoursAgo = DateTime.now().difference(timestamp).inHours;
        
        return CupertinoListTile(
          title: Text('${report['reportType']} - ${report['contentType']}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reported ${hoursAgo}h ago'),
              Text('Description: ${report['description']}'),
            ],
          ),
          trailing: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minSize: 0,
            onPressed: () => _showReviewDialog(report),
            child: const Text('Review'),
          ),
        );
      },
    );
  }

  Widget _buildReviewedReports() {
    if (_reviewedReports.isEmpty) {
      return const Center(
        child: Text(
          'No reviewed reports',
          style: TextStyle(
            fontSize: 18,
            color: CupertinoColors.systemGrey,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _reviewedReports.length,
      itemBuilder: (context, index) {
        final report = _reviewedReports[index];
        final action = report['action'] as String? ?? 'unknown';
        Color actionColor;
        
        switch (action) {
          case 'removed':
            actionColor = CupertinoColors.systemRed;
            break;
          case 'warning':
            actionColor = CupertinoColors.systemOrange;
            break;
          default:
            actionColor = CupertinoColors.systemGrey;
        }
        
        return CupertinoListTile(
          title: Text('${report['reportType']} - ${report['contentType']}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Action: $action'),
              if (report['notes'] != null && report['notes'].isNotEmpty)
                Text('Notes: ${report['notes']}'),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: actionColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              action.toUpperCase(),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
} 