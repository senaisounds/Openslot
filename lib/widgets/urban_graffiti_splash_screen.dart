import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:slotted/utils/logger.dart';

class UrbanGraffitiSplashScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const UrbanGraffitiSplashScreen({
    super.key,
    this.onFinished,
  });

  @override
  State<UrbanGraffitiSplashScreen> createState() => _UrbanGraffitiSplashScreenState();
}

class _UrbanGraffitiSplashScreenState extends State<UrbanGraffitiSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _sprayController;
  late AnimationController _textController;
  late AnimationController _microphoneController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _sprayAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _microphoneAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    _sprayController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _microphoneController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    _sprayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sprayController,
      curve: Curves.easeOutCubic,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.elasticOut,
    ));

    _microphoneAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _microphoneController,
      curve: Curves.bounceOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    try {
      // Start spray paint effect
      await _sprayController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Text appears
      await _textController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Microphone appears
      await _microphoneController.forward();
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        widget.onFinished?.call();
      }
    } catch (e, stackTrace) {
      Logger.e('Error in async operation', 
              tag: 'UrbanGraffitiSplashScreen', 
              error: e, 
              stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _sprayController.dispose();
    _textController.dispose();
    _microphoneController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark urban background
      body: Stack(
        children: [
          // Urban background with brick texture effect
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2C2C2C), // Dark gray
                  Color(0xFF1A1A1A), // Darker gray
                  Color(0xFF0F0F0F), // Almost black
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Brick pattern overlay
          ...List.generate(20, (index) {
            return Positioned(
              left: (index * 60.0) % MediaQuery.of(context).size.width,
              top: (index * 40.0) % MediaQuery.of(context).size.height,
              child: Container(
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
            );
          }),
          
          // Spray paint particles
          ...List.generate(30, (index) {
            return Positioned(
              left: (index * 30.0) % MediaQuery.of(context).size.width,
              top: (index * 50.0) % MediaQuery.of(context).size.height,
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      math.sin(_particleAnimation.value * 2 * math.pi + index) * 20,
                      math.cos(_particleAnimation.value * 2 * math.pi + index) * 15,
                    ),
                    child: Opacity(
                      opacity: _sprayAnimation.value * (0.3 + (index % 3) * 0.2),
                      child: Container(
                        width: 3 + (index % 3) * 2,
                        height: 3 + (index % 3) * 2,
                        decoration: BoxDecoration(
                          color: [
                            const Color(0xFFFF6B35), // Orange
                            const Color(0xFF4ECDC4), // Teal
                            const Color(0xFFFFE66D), // Yellow
                            const Color(0xFF45B7D1), // Blue
                            const Color(0xFF96CEB4), // Green
                          ][index % 5],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Main content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _fadeAnimation,
                _textAnimation,
                _microphoneAnimation,
                _pulseAnimation
              ]),
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Graffiti microphone
                    Transform.scale(
                      scale: _microphoneAnimation.value * _pulseAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(70),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withValues(alpha: 0.6),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: const Color(0xFF4ECDC4).withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFFFF6B35), // Orange center
                                Color(0xFFFF8E53), // Lighter orange
                                Color(0xFF4ECDC4), // Teal edge
                              ],
                            ),
                            borderRadius: BorderRadius.circular(70),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 3,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.mic_fill,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Graffiti-style "OPEN SLOT" text
                    Opacity(
                      opacity: _textAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6B35),
                              Color(0xFFFF8E53),
                              Color(0xFFFFE66D),
                              Color(0xFF4ECDC4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Text(
                          'OPEN SLOT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900, // Bold for graffiti style
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 3,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Urban tagline
                    Opacity(
                      opacity: _textAnimation.value * 0.8,
                      child: Text(
                        'FIND YOUR VOICE',
                        style: TextStyle(
                          color: const Color(0xFF4ECDC4),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 80),
                    
                    // Urban loading indicator
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6B35),
                              Color(0xFF4ECDC4),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _pulseAnimation.value * 2 * math.pi,
                                child: const Icon(
                                  CupertinoIcons.mic_fill,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Loading text
                    Opacity(
                      opacity: _fadeAnimation.value * 0.7,
                      child: Text(
                        'SPRAYING...',
                        style: TextStyle(
                          color: const Color(0xFF4ECDC4),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 