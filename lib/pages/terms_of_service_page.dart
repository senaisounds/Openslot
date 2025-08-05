import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsOfServicePage extends StatefulWidget {
  final bool isOnboarding;
  
  const TermsOfServicePage({
    super.key,
    this.isOnboarding = false,
  });

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  bool _hasAgreed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAgreementStatus();
  }

  Future<void> _checkAgreementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasAgreed = prefs.getBool('terms_accepted') ?? false;
    });
  }

  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('terms_accepted', true);
      
      setState(() {
        _hasAgreed = true;
        _isLoading = false;
      });
      
      if (mounted) {
        // Show success dialog
        await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Terms of Service accepted successfully!'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  if (widget.isOnboarding) {
                    Navigator.of(context).pop(true); // Return to onboarding with success
                  }
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        // Show error dialog
        await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to accept terms: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Terms of Service'),
        leading: widget.isOnboarding ? CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Back'),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
        trailing: widget.isOnboarding ? null : CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Done'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OpenSlot Terms of Service',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Last Updated: March 2, 2025',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Zero Tolerance Section
                      _buildSection(
                        'Zero Tolerance for Objectionable Content',
                        'OpenSlot maintains a zero-tolerance policy for objectionable content and abusive behavior. By using our service, you agree to:',
                        [
                          'Not post, share, or create content that is offensive, harmful, or inappropriate',
                          'Not engage in harassment, bullying, or abusive behavior towards other users',
                          'Not create events that promote illegal activities or harmful content',
                          'Not impersonate others or create fake accounts',
                          'Report any objectionable content or abusive users immediately',
                        ],
                      ),
                      
                      _buildSection(
                        'Content Guidelines',
                        'All user-generated content must comply with our community standards:',
                        [
                          'Events must be legitimate and accurately described',
                          'User profiles must contain truthful information',
                          'No hate speech, discrimination, or harmful content',
                          'No spam, scams, or misleading information',
                          'No content that violates intellectual property rights',
                        ],
                      ),
                      
                      _buildSection(
                        'Moderation and Enforcement',
                        'OpenSlot actively moderates content and enforces these terms:',
                        [
                          'We review reported content within 24 hours',
                          'Violating content will be removed immediately',
                          'Users who violate terms may be suspended or banned',
                          'Repeated violations result in permanent account termination',
                          'We cooperate with law enforcement when required',
                        ],
                      ),
                      
                      _buildSection(
                        'User Responsibilities',
                        'As a user of OpenSlot, you are responsible for:',
                        [
                          'Maintaining the security of your account',
                          'Providing accurate and truthful information',
                          'Respecting the privacy and rights of other users',
                          'Following all applicable laws and regulations',
                          'Reporting violations when you encounter them',
                        ],
                      ),
                      
                      _buildSection(
                        'Privacy and Data',
                        'Your privacy is important to us:',
                        [
                          'We collect and use data as described in our Privacy Policy',
                          'You can control your privacy settings in the app',
                          'We do not sell your personal information',
                          'You can request deletion of your data at any time',
                          'We implement security measures to protect your information',
                        ],
                      ),
                      
                      _buildSection(
                        'Limitation of Liability',
                        'OpenSlot provides this service "as is":',
                        [
                          'We are not liable for any damages arising from app use',
                          'We do not guarantee uninterrupted service',
                          'We may modify or discontinue features at any time',
                          'You use the app at your own risk',
                          'We are not responsible for third-party content or services',
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Show agreement status
                      if (_hasAgreed)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: CupertinoColors.systemGreen.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: CupertinoColors.systemGreen,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Terms of Service accepted',
                                style: TextStyle(
                                  color: CupertinoColors.systemGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Action buttons
                      if (widget.isOnboarding) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: CupertinoColors.systemGrey.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Skip',
                                    style: TextStyle(
                                      color: CupertinoColors.systemGrey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF8C00), Color(0xFFFF6B35)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  onPressed: _isLoading ? null : _acceptTerms,
                                  child: _isLoading
                                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                      : Text(
                                          _hasAgreed ? 'Already Agreed' : 'I Agree',
                                          style: const TextStyle(
                                            color: CupertinoColors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8C00), Color(0xFFFF6B35)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              onPressed: _isLoading ? null : _acceptTerms,
                              child: _isLoading
                                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                  : Text(
                                      _hasAgreed ? 'Already Agreed' : 'I Agree',
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      const Text(
                        'By using OpenSlot, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
} 