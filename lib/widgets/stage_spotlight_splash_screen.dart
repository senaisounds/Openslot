import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:slotted/utils/logger.dart';

class StageSpotlightSplashScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const StageSpotlightSplashScreen({
    super.key,
    this.onFinished,
  });

  @override
  State<StageSpotlightSplashScreen> createState() => _StageSpotlightSplashScreenState();
}

class _StageSpotlightSplashScreenState extends State<StageSpotlightSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _spotlightController;
  late AnimationController _curtainController;
  late AnimationController _marqueeController;
  late AnimationController _microphoneController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _spotlightAnimation;
  late Animation<double> _curtainAnimation;
  late Animation<double> _marqueeAnimation;
  late Animation<double> _microphoneAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    _spotlightController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _curtainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _marqueeController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _microphoneController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    _spotlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _spotlightController,
      curve: Curves.easeInOut,
    ));

    _curtainAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _curtainController,
      curve: Curves.easeOutCubic,
    ));

    _marqueeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _marqueeController,
      curve: Curves.easeInOut,
    ));

    _microphoneAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _microphoneController,
      curve: Curves.elasticOut,
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
      // Start main fade animation immediately
      _mainController.forward();
      
      // Start with curtain opening
      await _curtainController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Spotlight appears
      await _spotlightController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Microphone appears
      await _microphoneController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Marquee text appears
      await _marqueeController.forward();
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        widget.onFinished?.call();
      }
    } catch (e, stackTrace) {
      Logger.e('Error in async operation', 
              tag: 'StageSpotlightSplashScreen', 
              error: e, 
              stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _spotlightController.dispose();
    _curtainController.dispose();
    _marqueeController.dispose();
    _microphoneController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F1A), // Deep purple-black background
      body: Stack(
        children: [
          // Theater stage background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [
                  Color(0xFF2C1810), // Dark brown stage
                  Color(0xFF1A0F0A), // Deeper brown
                  Color(0xFF0D0805), // Almost black
                  Colors.black,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Stage floor lines
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.brown.withValues(alpha: 0.3),
                          Colors.brown.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Stage lighting from above
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 0.8,
                        colors: [
                          Colors.amber.withValues(alpha: 0.1),
                          Colors.orange.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Realistic stage curtains
          AnimatedBuilder(
            animation: _curtainAnimation,
            builder: (context, child) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF8B0000), // Dark red top
                        Color(0xFFDC143C), // Crimson middle
                        Color(0xFFB22222), // Fire brick bottom
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Curtain folds - multiple layers for depth
                      for (int i = 0; i < 8; i++)
                        Positioned(
                          left: (MediaQuery.of(context).size.width / 8) * i,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: MediaQuery.of(context).size.width / 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                                stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),
                      
                      // Curtain tassels at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                                                         gradient: LinearGradient(
                               colors: [
                                 Colors.amber.withValues(alpha: 0.8),
                                 Colors.yellow.withValues(alpha: 0.6),
                                 Colors.amber.withValues(alpha: 0.8),
                               ],
                             ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Curtain pull ropes
                      Positioned(
                        top: 20,
                        right: 30,
                        child: Container(
                          width: 4,
                          height: 100,
                                                     decoration: BoxDecoration(
                             color: Colors.amber.withValues(alpha: 0.8),
                             borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Curtain opening animation
                      AnimatedBuilder(
                        animation: _curtainAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              -MediaQuery.of(context).size.width * (1 - _curtainAnimation.value),
                              0,
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height * 0.4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF8B0000),
                                    Color(0xFFDC143C),
                                    Color(0xFFB22222),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Spotlight effect
          AnimatedBuilder(
            animation: _spotlightAnimation,
            builder: (context, child) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.6,
                      colors: [
                        Colors.amber.withValues(alpha: _spotlightAnimation.value * 0.5),
                        Colors.orange.withValues(alpha: _spotlightAnimation.value * 0.3),
                        Colors.yellow.withValues(alpha: _spotlightAnimation.value * 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Main content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _fadeAnimation,
                _microphoneAnimation,
                _marqueeAnimation,
                _pulseAnimation
              ]),
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stage microphone with spotlight
                    Transform.scale(
                      scale: _microphoneAnimation.value * _pulseAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(70),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.8),
                              blurRadius: 50,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.6),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.yellow.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(70),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.9),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.6),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.mic_fill,
                              size: 60,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Marquee-style "OPEN SLOT" text
                    Opacity(
                      opacity: _marqueeAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.withValues(alpha: 0.95),
                              Colors.orange.withValues(alpha: 0.95),
                              Colors.amber.withValues(alpha: 0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.7),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Text(
                          'OPEN SLOT',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Colors.white,
                                blurRadius: 3,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Stage tagline
                    Opacity(
                      opacity: _marqueeAnimation.value * 0.9,
                      child: Text(
                        'Your stage awaits',
                        style: TextStyle(
                          color: Colors.amber.withValues(alpha: 0.95),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 4,
                              offset: const Offset(1, 1),
                            ),
                            Shadow(
                              color: Colors.amber.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 80),
                    
                    // Stage loading indicator
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.9),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 3,
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
                                  size: 28,
                                  color: Colors.amber,
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
                      opacity: _fadeAnimation.value * 0.8,
                      child: Text(
                        'Preparing the stage...',
                        style: TextStyle(
                          color: Colors.amber.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 3,
                              offset: const Offset(1, 1),
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