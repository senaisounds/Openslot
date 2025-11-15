import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slotted/pages/terms_of_service_page.dart';
import 'package:slotted/utils/logger.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingPage({
    super.key,
    this.onComplete,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentStep = 0;
  
  final List<Map<String, dynamic>> _onboardingSteps = [
    {
      'title': 'Welcome to OpenSlot! 🎤',
      'description': 'Find and join open mics, open decks, and performance events near you.',
      'icon': CupertinoIcons.music_mic,
      'color': const Color(0xFFFF8C00),
    },
    {
      'title': 'Ready to Perform? 🎯',
      'description': 'Discover events, reserve your spot, and connect with the performance community.',
      'icon': CupertinoIcons.sparkles,
      'color': const Color(0xFF2DD4BF),
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _onboardingSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      _showTermsOfService();
    }
  }

  void _skipOnboarding() {
    _showTermsOfService();
  }

  Future<void> _showTermsOfService() async {
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => const TermsOfServicePage(isOnboarding: true),
      ),
    );

    if (result == true) {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', true);
      await prefs.setBool('has_agreed_to_terms', true);
      
      if (mounted) {
        widget.onComplete?.call();
      }
    } catch (e) {
      Logger.e('Error completing onboarding: $e', tag: 'Onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStepData = _onboardingSteps[_currentStep];
    
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  for (int i = 0; i < _onboardingSteps.length; i++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(right: i < _onboardingSteps.length - 1 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: i <= _currentStep 
                              ? currentStepData['color']
                              : Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                onPressed: _skipOnboarding,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                currentStepData['color'],
                                currentStepData['color'].withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(60),
                            boxShadow: [
                              BoxShadow(
                                color: currentStepData['color'].withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            currentStepData['icon'],
                            size: 60,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Title
                        Text(
                          currentStepData['title'],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Description
                        Text(
                          currentStepData['description'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(40),
              child: Row(
                children: [
                  // Back button
                  if (_currentStep > 0)
                    Expanded(
                      child: CupertinoButton(
                        onPressed: () {
                          setState(() {
                            _currentStep--;
                          });
                          _animationController.reset();
                          _animationController.forward();
                        },
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  // Next/Get Started button
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            currentStepData['color'],
                            currentStepData['color'].withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        onPressed: _nextStep,
                        child: Text(
                          _currentStep == _onboardingSteps.length - 1 
                              ? 'Get Started' 
                              : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 