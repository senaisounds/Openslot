import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:slotted/utils/logger.dart';

class SimpleSplashScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const SimpleSplashScreen({
    super.key,
    this.onFinished,
  });

  @override
  State<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    try {
      // Start scale animation
      await _scaleController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Start main fade animation
      await _controller.forward();
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        widget.onFinished?.call();
      }
    } catch (e, stackTrace) {
      Logger.e('Error in async operation', 
              tag: 'SplashScreen', 
              error: e, 
              stackTrace: stackTrace);
      // Handle error gracefully
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Animated background particles
          ...List.generate(20, (index) {
            return Positioned(
              left: (index * 50.0) % MediaQuery.of(context).size.width,
              top: (index * 30.0) % MediaQuery.of(context).size.height,
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value * 2 * math.pi,
                    child: Opacity(
                      opacity: 0.1 + (index % 3) * 0.05,
                      child: Container(
                        width: 4 + (index % 3) * 2,
                        height: 4 + (index % 3) * 2,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400,
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
              animation: Listenable.merge([_fadeAnimation, _pulseAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo container
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                              Colors.orange.shade800,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.shade400.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: const Icon(
                                CupertinoIcons.mic_fill,
                                size: 50,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Animated app name with glow effect
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.shade400.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: const Text(
                            'Open Slot',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.orange,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Animated tagline
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                        child: const Text(
                          'Find your next open slot',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Animated loading indicator
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: AnimatedBuilder(
                        animation: _rotateController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateAnimation.value * 2 * math.pi,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.shade400,
                                  width: 3,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.mic_fill,
                                  size: 20,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Loading text with pulse effect
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value * _pulseAnimation.value,
                          child: const Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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