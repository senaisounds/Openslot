import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@openslot.me',
      query: 'subject=OpenSlot Support Request',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback - copy email to clipboard
        await Clipboard.setData(const ClipboardData(text: 'support@openslot.me'));
      }
    } catch (e) {
      Logger.e('Failed to launch email: $e', tag: 'SupportPage');
      // Copy email to clipboard as fallback
      await Clipboard.setData(const ClipboardData(text: 'support@openslot.me'));
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Logger.e('Failed to launch URL: $url, error: $e', tag: 'SupportPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppColors.backgroundDark,
        border: null,
        middle: Text(
          'Support',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Center(
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.chat_bubble_2,
                      size: 60,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'OpenSlot Support',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We\'re here to help you with any questions or issues',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Contact Information Section
              _buildSection(
                title: 'Contact Information',
                children: [
                  _buildContactCard(
                    icon: CupertinoIcons.mail,
                    title: 'Email Support',
                    description: 'Get help with technical issues, account problems, or general questions',
                    actionText: 'support@openslot.me',
                    onTap: _launchEmail,
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    icon: CupertinoIcons.globe,
                    title: 'Website',
                    description: 'Visit our website for more information',
                    actionText: 'openslot.me',
                    onTap: () => _launchUrl('https://openslot.me'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // FAQ Section
              _buildSection(
                title: 'Frequently Asked Questions',
                children: [
                  _buildFAQItem(
                    question: 'How do I create an event?',
                    answer: 'Tap the "+" button on the home screen, fill in your event details, set your location and time, then publish your event.',
                  ),
                  _buildFAQItem(
                    question: 'How do I reserve a spot at an event?',
                    answer: 'Find an event you\'re interested in, tap on it to view details, then tap "Reserve" to secure your spot.',
                  ),
                  _buildFAQItem(
                    question: 'What if I need to cancel my reservation?',
                    answer: 'Go to your profile, find the event in "My Events", and tap "Cancel Reservation". Cancellation policies vary by event.',
                  ),
                  _buildFAQItem(
                    question: 'How do payments work?',
                    answer: 'OpenSlot uses secure payment processing. Payments are processed when you reserve a spot for paid events. Refunds depend on the event\'s cancellation policy.',
                  ),
                  _buildFAQItem(
                    question: 'How do I report inappropriate content or users?',
                    answer: 'Tap the menu icon on any event or user profile and select "Report". We review all reports and take appropriate action.',
                  ),
                  _buildFAQItem(
                    question: 'I\'m having technical issues with the app',
                    answer: 'Try restarting the app first. If the issue persists, contact our support team at support@openslot.me with details about the problem.',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // App Information Section
              _buildSection(
                title: 'App Information',
                children: [
                  _buildInfoCard(
                    icon: CupertinoIcons.doc_text,
                    title: 'Privacy Policy',
                    description: 'Learn how we protect and use your data',
                    onTap: () => _launchUrl('https://openslot.me/privacy'),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: CupertinoIcons.doc_checkmark,
                    title: 'Terms of Service',
                    description: 'Review our terms and conditions',
                    onTap: () => _launchUrl('https://openslot.me/terms'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Support Guidelines
              _buildSection(
                title: 'Getting the Best Support',
                children: [
                  _buildGuidelineItem(
                    icon: CupertinoIcons.info_circle,
                    text: 'Include your device model and iOS version when reporting technical issues',
                  ),
                  _buildGuidelineItem(
                    icon: CupertinoIcons.camera,
                    text: 'Screenshots help us understand your issue better',
                  ),
                  _buildGuidelineItem(
                    icon: CupertinoIcons.clock,
                    text: 'We typically respond to support requests within 24 hours',
                  ),
                  _buildGuidelineItem(
                    icon: CupertinoIcons.star,
                    text: 'Be specific about the steps that led to your issue',
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Footer
              const Center(
                child: Column(
                  children: [
                    Text(
                      'OpenSlot - Connect, Perform, Thrive',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Version 1.0 • © 2024 OpenSlot',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
