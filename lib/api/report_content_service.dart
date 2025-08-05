import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:slotted/utils/logger.dart';

/// Service to handle content reporting functionality
class ReportContentService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  /// Report types for different content
  static const List<String> reportTypes = [
    'Inappropriate Content',
    'Harassment or Bullying',
    'Spam or Scam',
    'Fake Event',
    'Violence or Threats',
    'Hate Speech',
    'Copyright Violation',
    'Other',
  ];
  
  /// Report content (event, user, or comment)
  static Future<bool> reportContent({
    required String contentType, // 'event', 'user', 'comment'
    required String contentId,
    required String reportType,
    String? description,
    String? reporterId,
  }) async {
    try {
      Logger.d('Reporting content: $contentType/$contentId', tag: 'ReportContent');
      
      final result = await _functions.httpsCallable('reportContent').call({
        'contentType': contentType,
        'contentId': contentId,
        'reportType': reportType,
        'description': description ?? '',
        'reporterId': reporterId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      final data = result.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      
      if (success) {
        Logger.d('Content reported successfully', tag: 'ReportContent');
        return true;
      } else {
        Logger.e('Failed to report content', tag: 'ReportContent');
        return false;
      }
    } catch (e) {
      Logger.e('Error reporting content: $e', tag: 'ReportContent');
      rethrow;
    }
  }
  
  /// Get report status for a user
  static Future<List<Map<String, dynamic>>> getUserReports() async {
    try {
      Logger.d('Getting user reports', tag: 'ReportContent');
      
      final result = await _functions.httpsCallable('getUserReports').call({});
      
      final data = result.data as Map<String, dynamic>;
      final reports = data['reports'] as List<dynamic>? ?? [];
      
      Logger.d('Retrieved ${reports.length} reports', tag: 'ReportContent');
      return reports.map((report) => report as Map<String, dynamic>).toList();
    } catch (e) {
      Logger.e('Error getting user reports: $e', tag: 'ReportContent');
      return [];
    }
  }
  
  /// Show report content dialog
  static Future<bool> showReportDialog(
    BuildContext context, {
    required String contentType,
    required String contentId,
    String? contentTitle,
  }) async {
    String? selectedReportType;
    final descriptionController = TextEditingController();
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report ${contentType == 'event' ? 'Event' : contentType == 'user' ? 'User' : 'Content'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contentTitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Reporting: $contentTitle',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            DropdownButtonFormField<String>(
              value: selectedReportType,
              decoration: const InputDecoration(
                labelText: 'Reason for Report',
                border: OutlineInputBorder(),
              ),
              items: reportTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              )).toList(),
              onChanged: (value) => selectedReportType = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Additional Details (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Please provide any additional context...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: selectedReportType == null ? null : () async {
              Navigator.of(context).pop(true);
              
              // Store context reference for later use
              final dialogContext = context;
              
              // Show loading dialog
              if (dialogContext.mounted) {
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Submitting report...'),
                      ],
                    ),
                  ),
                );
              }
              
              try {
                final success = await reportContent(
                  contentType: contentType,
                  contentId: contentId,
                  reportType: selectedReportType!,
                  description: descriptionController.text.trim(),
                );
                
                // Check if context is still mounted before closing dialog
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(); // Close loading dialog
                }
                
                // Check if context is still mounted before showing snackbar
                if (dialogContext.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted successfully. We will review it within 24 hours.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to submit report. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                // Check if context is still mounted before closing dialog
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(); // Close loading dialog
                }
                
                // Check if context is still mounted before showing snackbar
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Show report button for content
  static Widget buildReportButton({
    required String contentType,
    required String contentId,
    String? contentTitle,
    Widget? child,
  }) {
    return Builder(
      builder: (context) => CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minSize: 0,
        onPressed: () => showReportDialog(
          context,
          contentType: contentType,
          contentId: contentId,
          contentTitle: contentTitle,
        ),
        child: child ?? const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.flag, size: 16),
            SizedBox(width: 4),
            Text('Report', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
} 