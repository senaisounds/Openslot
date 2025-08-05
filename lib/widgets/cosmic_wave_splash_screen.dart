import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:slotted/utils/logger.dart';

class CosmicWaveSplashScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const CosmicWaveSplashScreen({
    super.key,
    this.onFinished,
  });

  @override
  State<CosmicWaveSplashScreen> createState() => _CosmicWaveSplashScreenState();
}

class _CosmicWaveSplashScreenState extends State<CosmicWaveSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _starController;
  late AnimationController _nebulaController;
  late AnimationController _microphoneController;
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _starAnimation;
  late Animation<double> _nebulaAnimation;
  late Animation<double> _microphoneAnimation;
  late Animation<double> _orbitAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    _starController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    _nebulaController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _microphoneController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _orbitController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    _starAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.linear,
    ));

    _nebulaAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _nebulaController,
      curve: Curves.easeInOut,
    ));

    _microphoneAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _microphoneController,
      curve: Curves.elasticOut,
    ));

    _orbitAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _orbitController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
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
      
      // Start nebula animation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Microphone appears
      await _microphoneController.forward();
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        widget.onFinished?.call();
      }
    } catch (e, stackTrace) {
      Logger.e('Error in async operation', 
              tag: 'CosmicWaveSplashScreen', 
              error: e, 
              stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _starController.dispose();
    _nebulaController.dispose();
    _microphoneController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A), // Deep space background
      body: Stack(
        children: [
          // Cosmic background with nebula
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF1A0B2E), // Deep purple
                  Color(0xFF0A0A1A), // Deep space
                  Color(0xFF000000), // Pure black
                ],
              ),
            ),
          ),
          
          // Animated nebula clouds
          ...List.generate(3, (index) {
            return Positioned(
              left: (index * 200.0) % MediaQuery.of(context).size.width,
              top: (index * 150.0) % MediaQuery.of(context).size.height,
              child: AnimatedBuilder(
                animation: _nebulaController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.5 + (_nebulaAnimation.value * 0.5),
                    child: Opacity(
                      opacity: 0.3 * _nebulaAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF8B5CF6).withValues(alpha: 0.6), // Purple
                              const Color(0xFFEC4899).withValues(alpha: 0.4), // Pink
                              const Color(0xFF06B6D4).withValues(alpha: 0.3), // Cyan
                              Colors.transparent,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Animated star field
          ...List.generate(100, (index) {
            return Positioned(
              left: (index * 30.0) % MediaQuery.of(context).size.width,
              top: (index * 50.0) % MediaQuery.of(context).size.height,
              child: AnimatedBuilder(
                animation: _starController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      math.sin(_starAnimation.value * 2 * math.pi + index) * 10,
                      math.cos(_starAnimation.value * 2 * math.pi + index) * 8,
                    ),
                    child: Opacity(
                      opacity: 0.3 + (index % 3) * 0.2,
                      child: Container(
                        width: 1 + (index % 3),
                        height: 1 + (index % 3),
                        decoration: BoxDecoration(
                          color: [
                            Colors.white,
                            const Color(0xFF06B6D4), // Cyan stars
                            const Color(0xFF8B5CF6), // Purple stars
                          ][index % 3],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Orbital rings around microphone
          ...List.generate(3, (index) {
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 - 100,
              top: MediaQuery.of(context).size.height / 2 - 100,
              child: AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _orbitAnimation.value * 2 * math.pi + (index * math.pi / 3),
                    child: Container(
                      width: 200 + (index * 40),
                      height: 200 + (index * 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100 + (index * 20)),
                        border: Border.all(
                          color: [
                            const Color(0xFF06B6D4), // Cyan
                            const Color(0xFF8B5CF6), // Purple
                            const Color(0xFFEC4899), // Pink
                          ][index].withValues(alpha: 0.3),
                          width: 1,
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
                _microphoneAnimation,
                _pulseAnimation
              ]),
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Floating cosmic microphone
                    Transform.scale(
                      scale: _microphoneAnimation.value * _pulseAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(70),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF06B6D4).withValues(alpha: 0.6),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                            BoxShadow(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFF06B6D4), // Cyan center
                                Color(0xFF8B5CF6), // Purple middle
                                Color(0xFFEC4899), // Pink edge
                              ],
                            ),
                            borderRadius: BorderRadius.circular(70),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
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
                    
                    const SizedBox(height: 60),
                    
                    // Cosmic tagline
                    Opacity(
                      opacity: _fadeAnimation.value.clamp(0.6, 1.0), // Ensure it's always visible
                      child: Text(
                        'Explore the cosmic waves',
                        style: TextStyle(
                          color: const Color(0xFF06B6D4),
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
                              color: const Color(0xFF06B6D4).withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 80),
                    
                    // Cosmic loading indicator
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _orbitController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _orbitAnimation.value * 2 * math.pi,
                                child: const Icon(
                                  CupertinoIcons.mic_fill,
                                  size: 24,
                                  color: Color(0xFF06B6D4),
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
                        'Initializing cosmic connection...',
                        style: TextStyle(
                          color: const Color(0xFF06B6D4),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF06B6D4).withValues(alpha: 0.8),
                              blurRadius: 3,
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