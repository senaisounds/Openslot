import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:slotted/common/design_system.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _hasAgreed = false;
  bool _showDetails = false;

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        'Welcome to OpenSlot! 🎤',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'To get started, please agree to our terms.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            
            // Simple single checkbox
            GestureDetector(
              onTap: () => setState(() => _hasAgreed = !_hasAgreed),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoCheckbox(
                    value: _hasAgreed,
                    onChanged: (value) => setState(() => _hasAgreed = value ?? false),
                    activeColor: DesignSystem.primaryOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.label,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: DesignSystem.primaryOrange,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchURL('https://openslot.me/terms'),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: DesignSystem.primaryOrange,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchURL('https://openslot.me/privacy'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Show more/less button
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () => setState(() => _showDetails = !_showDetails),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showDetails ? 'Show less' : 'What am I agreeing to?',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showDetails ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    size: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ],
              ),
            ),
            
            // Expandable details
            if (_showDetails) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'By using OpenSlot, you agree to:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '✓ Follow community guidelines\n'
                      '✓ Be respectful to performers and hosts\n'
                      '✓ Not post inappropriate content\n'
                      '✓ Report violations when you see them\n'
                      '✓ Our data and privacy practices',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: widget.onDecline ?? () => Navigator.of(context).pop(),
          child: const Text(
            'Not Now',
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _hasAgreed ? () {
            Navigator.of(context).pop();
            widget.onAccept();
          } : null,
          child: Text(
            'Continue',
            style: TextStyle(
              color: _hasAgreed ? DesignSystem.primaryOrange : CupertinoColors.systemGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
} 