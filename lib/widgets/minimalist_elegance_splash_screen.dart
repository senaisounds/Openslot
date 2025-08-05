import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:slotted/utils/logger.dart';

class MinimalistEleganceSplashScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const MinimalistEleganceSplashScreen({
    super.key,
    this.onFinished,
  });

  @override
  State<MinimalistEleganceSplashScreen> createState() => _MinimalistEleganceSplashScreenState();
}

class _MinimalistEleganceSplashScreenState extends State<MinimalistEleganceSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
    ));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    try {
      // Start with fade in
      await _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Scale in the logo
      await _scaleController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Slide in the text
      await _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        widget.onFinished?.call();
      }
    } catch (e, stackTrace) {
      Logger.e('Error in async operation', 
              tag: 'MinimalistEleganceSplashScreen', 
              error: e, 
              stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Deep blue background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E), // Deep blue
              Color(0xFF16213E), // Slightly lighter blue
              Color(0xFF0F3460), // Dark blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _fadeAnimation, 
              _scaleAnimation, 
              _slideAnimation,
              _pulseAnimation,
              _textFadeAnimation
            ]),
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Elegant microphone logo
                  Transform.scale(
                    scale: _scaleAnimation.value * _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEE7D30).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.mic_fill,
                          size: 50,
                          color: Color(0xFFEE7D30), // Orange accent
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Elegant app name
                  Opacity(
                    opacity: _textFadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: const Text(
                        'OPEN SLOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w300, // Light weight for elegance
                          letterSpacing: 6,
                          fontFamily: 'SF Pro Display, Arial, sans-serif',
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Sophisticated tagline
                  Opacity(
                    opacity: _textFadeAnimation.value * 0.8,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 0.5),
                      child: Text(
                        'Find your next open slot',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1,
                          fontFamily: 'SF Pro Text, Arial, sans-serif',
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Minimalist loading indicator
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 1,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFFEE7D30).withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Loading text
                  Opacity(
                    opacity: _fadeAnimation.value * 0.6,
                    child: Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1,
                        fontFamily: 'SF Pro Text, Arial, sans-serif',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
} 