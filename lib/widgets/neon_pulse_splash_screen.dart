import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:slotted/utils/logger.dart';

class NeonPulseSplashScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const NeonPulseSplashScreen({
    super.key,
    this.onFinished,
  });

  @override
  State<NeonPulseSplashScreen> createState() => _NeonPulseSplashScreenState();
}

class _NeonPulseSplashScreenState extends State<NeonPulseSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _neonPulseController;
  late AnimationController _electricArcController;
  late AnimationController _digitalRainController;
  late AnimationController _textGlowController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _neonPulseAnimation;
  late Animation<double> _electricArcAnimation;
  late Animation<double> _digitalRainAnimation;
  late Animation<double> _textGlowAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    _neonPulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _electricArcController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _digitalRainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _textGlowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    _neonPulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _neonPulseController,
      curve: Curves.easeInOut,
    ));

    _electricArcAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _electricArcController,
      curve: Curves.linear,
    ));

    _digitalRainAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _digitalRainController,
      curve: Curves.linear,
    ));

    _textGlowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textGlowController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    try {
      // Start main fade animation
      await _mainController.forward();
      await Future.delayed(const Duration(milliseconds: 3000));
      
      if (mounted) {
        widget.onFinished?.call();
      }
    } catch (e, stackTrace) {
      Logger.e('Error in async operation', 
              tag: 'NeonPulseSplashScreen', 
              error: e, 
              stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _neonPulseController.dispose();
    _electricArcController.dispose();
    _digitalRainController.dispose();
    _textGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Deep black background
      body: Stack(
        children: [
          // Digital rain background
          ...List.generate(50, (index) {
            return Positioned(
              left: (index * 20.0) % MediaQuery.of(context).size.width,
              top: -50 + (_digitalRainAnimation.value * (MediaQuery.of(context).size.height + 100)),
              child: AnimatedBuilder(
                animation: _digitalRainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.3 + (index % 3) * 0.2,
                    child: Text(
                      String.fromCharCode(0x30A0 + (index % 10)), // Japanese katakana for digital rain
                      style: TextStyle(
                        color: const Color(0xFF00FF41), // Matrix green
                        fontSize: 12 + (index % 3) * 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Electric arc effects
          ...List.generate(8, (index) {
            return Positioned(
              left: (index * 100.0) % MediaQuery.of(context).size.width,
              top: (index * 80.0) % MediaQuery.of(context).size.height,
              child: AnimatedBuilder(
                animation: _electricArcController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _electricArcAnimation.value * 2 * math.pi + (index * 0.5),
                    child: Opacity(
                      opacity: 0.4 * _electricArcAnimation.value,
                      child: Container(
                        width: 2,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF00FFFF), // Cyan
                              Color(0xFF00FF41), // Matrix green
                              Color(0xFFFF00FF), // Magenta
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
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
                _neonPulseAnimation, 
                _textGlowAnimation
              ]),
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Neon microphone with electric arcs
                    Transform.scale(
                      scale: _neonPulseAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(70),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFFF).withValues(alpha: 0.8),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF00FF).withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Electric arc around microphone
                            ...List.generate(6, (index) {
                              return AnimatedBuilder(
                                animation: _electricArcController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _electricArcAnimation.value * 2 * math.pi + (index * math.pi / 3),
                                    child: Positioned(
                                      left: 70 - 2,
                                      top: 70 - 30,
                                      child: Container(
                                        width: 4,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Color(0xFF00FFFF),
                                              Color(0xFFFF00FF),
                                              Colors.transparent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                            
                            // Main microphone icon
                            const Center(
                              child: Icon(
                                CupertinoIcons.mic_fill,
                                size: 60,
                                color: Color(0xFF00FFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Neon "OPEN SLOT" text
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFFF).withValues(alpha: _textGlowAnimation.value * 0.8),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF00FF).withValues(alpha: _textGlowAnimation.value * 0.6),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Text(
                          'OPEN SLOT',
                          style: TextStyle(
                            color: Color(0xFF00FFFF),
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Color(0xFFFF00FF),
                                blurRadius: 10,
                              ),
                              Shadow(
                                color: Color(0xFF00FF41),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Cyberpunk tagline
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        'FIND YOUR NEXT OPEN SLOT',
                        style: TextStyle(
                          color: const Color(0xFF00FF41),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF00FF41).withValues(alpha: 0.8),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Cyberpunk loading indicator
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: AnimatedBuilder(
                        animation: _electricArcController,
                        builder: (context, child) {
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: const Color(0xFF00FFFF),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00FFFF).withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: _electricArcAnimation.value * 2 * math.pi,
                                child: const Icon(
                                  CupertinoIcons.mic_fill,
                                  size: 24,
                                  color: Color(0xFF00FFFF),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Loading text with neon effect
                    AnimatedBuilder(
                      animation: _textGlowAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value * _textGlowAnimation.value,
                          child: Text(
                            'INITIALIZING...',
                            style: TextStyle(
                              color: const Color(0xFF00FF41),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF00FF41).withValues(alpha: 0.8),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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