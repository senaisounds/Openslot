import 'package:flutter/cupertino.dart';
import 'package:slotted/common/design_system.dart';

class TermsOfServiceDialog extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback? onDecline;

  const TermsOfServiceDialog({
    super.key,
    required this.onAccept,
    this.onDecline,
  });

  @override
  State<TermsOfServiceDialog> createState() => _TermsOfServiceDialogState();
}

class _TermsOfServiceDialogState extends State<TermsOfServiceDialog> {
  bool _hasAcceptedTerms = false;
  bool _hasAcceptedPrivacyPolicy = false;
  bool _hasAcceptedContentPolicy = false;

  bool get _canProceed => _hasAcceptedTerms && _hasAcceptedPrivacyPolicy && _hasAcceptedContentPolicy;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        'Terms of Service & Privacy Policy',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Welcome to OpenSlot! Please review and accept our terms before using the app.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Terms of Service
            _buildCheckboxTile(
              'I accept the Terms of Service',
              _hasAcceptedTerms,
              (value) => setState(() => _hasAcceptedTerms = value ?? false),
            ),
            
            // Privacy Policy
            _buildCheckboxTile(
              'I accept the Privacy Policy',
              _hasAcceptedPrivacyPolicy,
              (value) => setState(() => _hasAcceptedPrivacyPolicy = value ?? false),
            ),
            
            // Content Policy
            _buildCheckboxTile(
              'I agree to follow community guidelines and not post inappropriate content',
              _hasAcceptedContentPolicy,
              (value) => setState(() => _hasAcceptedContentPolicy = value ?? false),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'By accepting, you agree to:\n'
              '• Follow community guidelines\n'
              '• Not post inappropriate content\n'
              '• Report violations when you see them\n'
              '• Accept our privacy practices',
              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: widget.onDecline ?? () => Navigator.of(context).pop(),
          child: const Text('Decline'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          isDestructiveAction: false,
          onPressed: _canProceed ? () {
            Navigator.of(context).pop();
            widget.onAccept();
          } : null,
          child: Text(
            'Accept',
            style: TextStyle(
              color: _canProceed ? DesignSystem.primaryOrange : CupertinoColors.systemGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(String title, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CupertinoCheckbox(
            value: value,
            onChanged: onChanged,
            activeColor: DesignSystem.primaryOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
} 