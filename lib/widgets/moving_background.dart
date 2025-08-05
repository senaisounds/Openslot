import 'package:flutter/material.dart';

import 'package:slotted/common/colors.dart';
import 'package:slotted/utils/dev_ui_settings.dart';
import 'package:slotted/utils/logger.dart';

// Moving background widget
class MovingBackground extends StatefulWidget {
  const MovingBackground({super.key});

  @override
  State<MovingBackground> createState() => _MovingBackgroundState();
}

class _MovingBackgroundState extends State<MovingBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late AnimationController _streakController;
  late AnimationController _shapeController;

  @override
  void initState() {
    super.initState();
    
    // Initialize with ultra-slow durations for maximum smoothness
    _controller = AnimationController(
      duration: const Duration(seconds: 2400), // 8x slower than original (300 → 2400)
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 2000), // 8x slower than original (250 → 2000)
      vsync: this,
    )..repeat();

    _streakController = AnimationController(
      duration: const Duration(seconds: 1600), // 8x slower than original (200 → 1600)
      vsync: this,
    )..repeat();

    _shapeController = AnimationController(
      duration: const Duration(seconds: 1440), // 8x slower than original (180 → 1440)
      vsync: this,
    )..repeat();
    
    // Load developer settings and update animation durations
    _loadDevSettings();
  }
  
  Future<void> _loadDevSettings() async {
    try {
      await DevUISettings.instance.loadSettings();
      
      // Skip controller recreation to maintain smooth animation during hot reload
      // The default durations are already ultra-slow and work great
      // This prevents animation stopping during development
    } catch (e, stackTrace) {
      Logger.e('Error in async operation', 
              tag: 'MovingBackground', 
              error: e, 
              stackTrace: stackTrace);
      // Handle error gracefully
    }
  }

  @override
  void didUpdateWidget(MovingBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure animations continue smoothly after hot reload
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
    if (!_particleController.isAnimating) {
      _particleController.repeat();
    }
    if (!_streakController.isAnimating) {
      _streakController.repeat();
    }
    if (!_shapeController.isAnimating) {
      _shapeController.repeat();
    }
    
    // Force repaint to ensure animation is visible
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    _streakController.dispose();
    _shapeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Performance optimization: Since the painter just draws a solid black background,
    // replace expensive 4-controller animation with simple static container
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        // Add subtle gradient for depth without expensive animations
        gradient: RadialGradient(
          center: Alignment(0.3, -0.5),
          radius: 1.5,
          colors: [
            AppColors.backgroundMedium, // Slightly lighter center
            AppColors.backgroundDark,   // Pure black edges
          ],
        ),
      ),
    );
  }
}

class MovingBackgroundPainter extends CustomPainter {
  final double animationValue;
  final double particleValue;
  final double streakValue;
  final double shapeValue;
  final DevUISettings settings;

  MovingBackgroundPainter(
    this.animationValue,
    this.particleValue,
    this.streakValue,
    this.shapeValue,
    this.settings,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Solid black background
    final backgroundPaint = Paint()
      ..color = Colors.black;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // No moving elements - just solid black background
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Static background, no repaint needed
  }
} 