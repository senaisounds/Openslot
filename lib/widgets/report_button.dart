import 'package:flutter/cupertino.dart';
import 'package:slotted/common/design_system.dart';
import 'package:slotted/utils/logger.dart';

class ReportButton extends StatelessWidget {
  final String contentType; // 'post', 'comment', 'user', etc.
  final String contentId;
  final String? contentText;
  final String? userId;
  final VoidCallback? onReport;

  const ReportButton({
    super.key,
    required this.contentType,
    required this.contentId,
    this.contentText,
    this.userId,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minSize: 0,
      onPressed: () => _showReportDialog(context),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 14,
            color: CupertinoColors.systemGrey,
          ),
          SizedBox(width: 4),
          Text(
            'Report',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _ReportDialog(
        contentType: contentType,
        contentId: contentId,
        contentText: contentText,
        userId: userId,
        onReport: onReport,
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final String contentType;
  final String contentId;
  final String? contentText;
  final String? userId;
  final VoidCallback? onReport;

  const _ReportDialog({
    required this.contentType,
    required this.contentId,
    this.contentText,
    this.userId,
    this.onReport,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _reportReasons = [
    'Inappropriate content',
    'Harassment or bullying',
    'Spam or misleading information',
    'Violence or threats',
    'Hate speech',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Report Content'),
      message: const Text('Help us keep the community safe by reporting inappropriate content.'),
      actions: [
        ..._reportReasons.map((reason) => CupertinoActionSheetAction(
          onPressed: () => setState(() => _selectedReason = reason),
          child: Row(
            children: [
              Expanded(child: Text(reason)),
              if (_selectedReason == reason)
                const Icon(
                  CupertinoIcons.check_mark,
                  color: DesignSystem.primaryOrange,
                ),
            ],
          ),
        )),
        if (_selectedReason != null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoTextField(
              controller: _detailsController,
              placeholder: 'Additional details (optional)',
              maxLines: 3,
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
                 CupertinoActionSheetAction(
           isDestructiveAction: true,
           onPressed: _selectedReason != null ? () => _submitReport(context) : () {},
           child: const Text('Submit Report'),
         ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: const Text('Cancel'),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _submitReport(BuildContext context) {
    // Here you would typically send the report to your backend
    // For now, we'll just show a confirmation and call the callback
    
    Navigator.of(context).pop();
    
    // Show confirmation
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Report Submitted'),
        content: const Text('Thank you for your report. We will review it within 24 hours.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    // Call the onReport callback if provided
    widget.onReport?.call();
    
    // Log the report (in a real app, this would go to your backend)
    Logger.i('Report submitted: ${widget.contentType} - ${widget.contentId} - $_selectedReason', tag: 'ReportButton');
  }
} 