import 'package:flutter/cupertino.dart';
import 'package:slotted/common/design_system.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Privacy Policy'),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.black,
                ),
              ),
              const SizedBox(height: DesignSystem.spacingM),
              Text(
                'Last updated: ${DateTime.now().year}',
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: DesignSystem.spacingXL),
              
              _buildSection(
                'Information We Collect',
                'We collect information you provide directly to us, such as when you create an account, create or join events, or contact us for support.',
              ),
              
              _buildSection(
                'How We Use Your Information',
                'We use the information we collect to provide, maintain, and improve our services, communicate with you, and ensure the security of our platform.',
              ),
              
              _buildSection(
                'Information Sharing',
                'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.',
              ),
              
              _buildSection(
                'Data Security',
                'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
              ),
              
              _buildSection(
                'Your Rights',
                'You have the right to access, update, or delete your personal information. You can manage your privacy settings in the app.',
              ),
              
              _buildSection(
                'Contact Us',
                'If you have any questions about this Privacy Policy, please contact us at privacy@openslot.app',
              ),
              
              const SizedBox(height: DesignSystem.spacingXL),
              
              Container(
                padding: const EdgeInsets.all(DesignSystem.spacingM),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                ),
                child: const Text(
                  'By using OpenSlot, you agree to this Privacy Policy. We may update this policy from time to time, and we will notify you of any changes.',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignSystem.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: DesignSystem.spacingS),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.black,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 