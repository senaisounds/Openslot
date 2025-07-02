import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:slotted/utils/dev_ui_settings.dart';

// Particle types
enum ParticleType {
  circle,
  star,
  line
}

// Particle class for the moving background
class Particle {
  Offset position;
  double size;
  double speed;
  Color color;
  ParticleType type;
  double rotation; // For stars and lines
  double rotationSpeed; // For stars and lines

  Particle({
    required this.position,
    required this.size,
    required this.speed,
    required this.color,
    required this.type,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
  });

  void update(Size size) {
    // Update position
    position = Offset(position.dx, position.dy + speed);
    
    // Update rotation for stars and lines
    if (type != ParticleType.circle) {
      rotation += rotationSpeed;
    }
    
    // Reset position when it goes off screen
    if (position.dy > size.height) {
      position = Offset(
        math.Random().nextDouble() * size.width,
        -size.height * 0.1,
      );
    }
  }
}

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
    await DevUISettings.instance.loadSettings();
    
    // Skip controller recreation to maintain smooth animation during hot reload
    // The default durations are already ultra-slow and work great
    // This prevents animation stopping during development
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
        color: Colors.black,
        // Add subtle gradient for depth without expensive animations
        gradient: RadialGradient(
          center: Alignment(0.3, -0.5),
          radius: 1.5,
          colors: [
            Color(0xFF1A1A1A), // Slightly lighter center
            Colors.black,       // Pure black edges
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

    // Pure black background - no overlays
  }

  void _drawSpotlights(Canvas canvas, Size size) {
    // Underground event aesthetic - moody, atmospheric colors
    final spotlightColors = [
      const Color(0x18FFFFFF), // Pure white spotlight (main underground feel)
      const Color(0x15F0F0F0), // Warm white
      const Color(0x14FFE4B5), // Subtle warm amber
      const Color(0x12E6E6FA), // Very pale lavender
      const Color(0x14FFF8DC), // Soft cream
      const Color(0x16C0C0C0), // Silver glow
      const Color(0x13F5F5DC), // Faint beige
      const Color(0x15DCDCDC), // Light gray
    ];

    // Random helper functions
    double randomFloat(int seed, double min, double max) {
      final random = (seed * 9301 + 49297) % 233280;
      return min + (random / 233280.0) * (max - min);
    }

    int randomInt(int seed, int min, int max) {
      final random = (seed * 9301 + 49297) % 233280;
      return min + (random % (max - min + 1));
    }

    // Generate premium lighting with strategic placement
    final spotlightCount = (settings.spotlightCount * 0.6).toInt(); // Increased for more immersive lighting
    for (int i = 0; i < spotlightCount; i++) {
      final positionSeed = i * 271 + (animationValue * 300).toInt();
      final movementSeed = i * 277;
      final sizeSeed = i * 281;
      
      final baseX = randomFloat(positionSeed, 0.1, 0.9);
      final baseY = randomFloat(positionSeed + 17, 0.1, 0.9);
      final driftSpeed = randomFloat(movementSeed, settings.spotlightSpeed * 0.2, settings.spotlightSpeed * 1.6);
      final driftRadius = randomFloat(movementSeed + 19, 8, 22);
      final pulseSpeed = randomFloat(i * 283, settings.spotlightSpeed * 0.4, settings.spotlightSpeed * 2.0);
      
      // Simple floating movement to prevent freezing
      final time = animationValue * driftSpeed * 0.02; // Slightly faster for visibility
      
      // Simple horizontal floating
      final horizontalFloat = math.sin(time + i * 1.3) * 10;
      
      // Simple vertical floating with gentle upward movement
      final verticalFloat = math.cos(time + i * 1.1) * 5;
      final upwardDrift = -time * 0.5; // Very slow upward drift
      
      final x = size.width * baseX + horizontalFloat;
      final y = size.height * baseY + verticalFloat + upwardDrift;
      
      // Dynamic radius with premium breathing effect
      final baseRadius = randomFloat(sizeSeed, settings.spotlightSize * 0.3, settings.spotlightSize * 1.8) * size.width;
      final pulse = math.sin(animationValue * 0.7 + i * 2.1) * 0.15 + 1.0; // More noticeable pulse
      final radius = baseRadius * pulse;

      final colorIndex = randomInt(i * 293, 0, spotlightColors.length - 1);
      final opacity = randomFloat(i * 307, settings.spotlightOpacity * 0.8, settings.spotlightOpacity);
      
      final gradient = RadialGradient(
        colors: [
          spotlightColors[colorIndex].withValues(alpha: opacity),
          spotlightColors[colorIndex].withValues(alpha: 0.0),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: Offset(x, y), radius: radius),
        );

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    // Underground event particle colors - atmospheric and moody
    final particleColors = [
      const Color(0x25FFFFFF), // White dust particles
      const Color(0x20F5F5F5), // Soft white
      const Color(0x18FFE4B5), // Warm amber glow
      const Color(0x15E6E6FA), // Pale lavender haze
      const Color(0x22C0C0C0), // Silver sparkles
      const Color(0x20D3D3D3), // Light gray
      const Color(0x18FFF8DC), // Cream particles
      const Color(0x16DCDCDC), // Muted gray
      const Color(0x14F0F8FF), // Very pale blue
    ];

    // Create pseudo-random values using particle index as seed
    double randomFloat(int seed, double min, double max) {
      final random = (seed * 9301 + 49297) % 233280;
      return min + (random / 233280.0) * (max - min);
    }

    int randomInt(int seed, int min, int max) {
      final random = (seed * 9301 + 49297) % 233280;
      return min + (random % (max - min + 1));
    }

    // Draw main particle layer with minimal count for 60fps
    final mainParticleCount = (settings.particleCount * 0.05).toInt(); // Reduced to 5% for maximum performance
    for (int i = 0; i < mainParticleCount; i++) {
      // Random base position with chaotic movement
      final randomSeedX = i * 7 + (particleValue * 1000).toInt();
      final randomSeedY = i * 11 + (particleValue * 1000).toInt();
      final randomSeedSpeed = i * 13;
      final randomSeedPhase = i * 17;
      
      final baseX = randomFloat(randomSeedX, 0, 1) * size.width;
      final baseY = randomFloat(randomSeedY, 0, 1) * size.height;
      final speedMultiplier = randomFloat(randomSeedSpeed, settings.particleSpeed * 0.2, settings.particleSpeed * 1.6);
      final phaseOffset = randomFloat(randomSeedPhase, 0, math.pi * 2);
      final amplitude = randomFloat(i * 19, 5, 20); // Reduced amplitude: 10-40 -> 5-20
      
      // Ultra-simple linear movement for maximum performance
      final time = particleValue * speedMultiplier * 0.01; // Ultra-slow
      final x = baseX + math.sin(time + phaseOffset) * 5; // Minimal movement
      final y = baseY + math.cos(time + phaseOffset) * 5; // Minimal movement

      final colorIndex = randomInt(i * 23, 0, particleColors.length - 1);
      final opacity = randomFloat(i * 29, settings.particleOpacity * 0.7, settings.particleOpacity);
      
      final paint = Paint()
        ..color = particleColors[colorIndex].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Randomly vary particle sizes
      final particleSize = randomFloat(i * 31, settings.particleSize * 0.3, settings.particleSize * 1.8);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
    
    // Secondary particle layer with minimal count
    final secondaryParticleCount = (settings.particleCount * 0.03).toInt(); // Reduced to 3% for maximum performance
    for (int i = 0; i < secondaryParticleCount; i++) {
      final randomSeed = i * 37 + (particleValue * 500).toInt();
      final spiralSeed = i * 41;
      
      final radius = randomFloat(randomSeed, 30, 100); // Reduced radius: 50-200 -> 30-100
      final spiralSpeed = randomFloat(spiralSeed, settings.particleSpeed * 0.4, settings.particleSpeed * 2.4);
      final centerOffsetX = randomFloat(i * 43, 0.2, 0.8) * size.width;
      final centerOffsetY = randomFloat(i * 47, 0.2, 0.8) * size.height;
      
      // Simple circular movement for performance
      final angle = particleValue * spiralSpeed * 0.01 + i * 0.8; // Ultra-slow
      final spiralRadius = radius * 0.1; // Tiny radius
      
      final x = centerOffsetX + math.cos(angle) * spiralRadius;
      final y = centerOffsetY + math.sin(angle) * spiralRadius;

      final colorIndex = randomInt(i * 53, 0, particleColors.length - 1);
      final opacity = randomFloat(i * 59, settings.particleOpacity * 0.5, settings.particleOpacity * 1.3);
      
      final paint = Paint()
        ..color = particleColors[colorIndex].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final particleSize = randomFloat(i * 61, settings.particleSize * 0.3, settings.particleSize * 1.2);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
    
    // Tertiary particles disabled for maximum performance
    const tertiaryParticleCount = 0; // Disabled for 60fps performance
    for (int i = 0; i < tertiaryParticleCount; i++) {
      final chaos1 = randomFloat(i * 67, 0, 1);
      final chaos2 = randomFloat(i * 71, 0, 1);
      final chaos3 = randomFloat(i * 73, settings.particleSpeed * 0.2, settings.particleSpeed * 2.0);
      final chaos4 = randomFloat(i * 79, 0, math.pi * 4);
      
      // Brownian motion simulation (like real particle movement)
      final time = particleValue * chaos3 * 0.01; // Ultra-slow for realism
      
      // Simulate random walk with momentum conservation
      final brownianX = math.sin(time + chaos4) * 5 * math.sqrt(time + 0.1);
      final brownianY = math.cos(time + chaos4) * 5 * math.sqrt(time + 0.1);
      
      // Add thermal motion damping (particles slow down over time)
      final thermalDamping = math.exp(-time * 0.02);
      
      final x = chaos1 * size.width + brownianX * thermalDamping;
      final y = chaos2 * size.height + brownianY * thermalDamping;

      final colorIndex = randomInt(i * 83, 0, particleColors.length - 1);
      final opacity = randomFloat(i * 89, settings.particleOpacity * 0.3, settings.particleOpacity * 1.2);
      
      final paint = Paint()
        ..color = particleColors[colorIndex].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final particleSize = randomFloat(i * 97, settings.particleSize * 0.2, settings.particleSize * 0.8);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  void _drawStreaks(Canvas canvas, Size size) {
    final streakColors = [
      const Color(0x10FFFFFF), // White light streaks
      const Color(0x0EF5F5F5), // Soft white
      const Color(0x0CFFE4B5), // Warm amber
      const Color(0x0AE6E6FA), // Pale lavender
      const Color(0x0DC0C0C0), // Silver
    ];

    // Random helper functions
    double randomFloat(int seed, double min, double max) {
      final random = (seed * 9301 + 49297) % 233280;
      return min + (random / 233280.0) * (max - min);
    }

    int randomInt(int seed, int min, int max) {
      final random = (seed * 9301 + 49297) % 233280;
      return min + (random % (max - min + 1));
    }

    // Random main streaks with chaotic positioning
    final mainStreakCount = (settings.streakCount * 0.57).toInt(); // ~57% of total streaks
    for (int i = 0; i < mainStreakCount; i++) {
      final randomSeed = i * 103 + (streakValue * 800).toInt();
      final speedSeed = i * 107;
      final angleSeed = i * 109;
      
      final baseX = randomFloat(randomSeed, 0, 1) * size.width;
      final baseY = randomFloat(randomSeed + 1, 0, 1) * size.height;
      final speed = randomFloat(speedSeed, settings.streakSpeed * 0.2, settings.streakSpeed * 1.6);
      final angle = randomFloat(angleSeed, 0, math.pi * 2);
      final length = randomFloat(i * 113, settings.streakLength * 0.5, settings.streakLength * 1.5);
      
      final startX = (baseX + streakValue * size.width * speed) % size.width;
      final startY = (baseY + math.sin(streakValue * math.pi * speed + i) * 25) % size.height; // Reduced amplitude: 50 -> 25
      final endX = startX + math.cos(angle) * length;
      final endY = startY + math.sin(angle) * length;

      final colorIndex = randomInt(i * 127, 0, streakColors.length - 1);
      final strokeWidth = randomFloat(i * 131, 0.5, 1.5);
      final opacity = randomFloat(i * 137, settings.streakOpacity * 0.8, settings.streakOpacity);

      final paint = Paint()
        ..color = streakColors[colorIndex].withValues(alpha: opacity)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
    
    // Chaotic diagonal streaks with random angles and movements
    final diagonalStreakCount = (settings.streakCount * 0.43).toInt(); // ~43% of total streaks
    for (int i = 0; i < diagonalStreakCount; i++) {
      final chaosSeed = i * 139 + (streakValue * 600).toInt();
      final rotationSeed = i * 149;
      
      final centerX = randomFloat(chaosSeed, 0.1, 0.9) * size.width;
      final centerY = randomFloat(chaosSeed + 5, 0.1, 0.9) * size.height;
      final rotationSpeed = randomFloat(rotationSeed, settings.streakSpeed * 0.2, settings.streakSpeed * 2.0);
      final radius = randomFloat(i * 151, 20, 50); // Smaller radius: 30-80 -> 20-50
      
      final rotation = streakValue * math.pi * 2 * rotationSpeed + i * 1.2;
      final wobble = math.sin(streakValue * math.pi * 0.2 + i) * 10; // Ultra slow wobble: 0.6 -> 0.2, tiny amplitude: 20 -> 10
      
      final startX = centerX + math.cos(rotation) * radius + wobble;
      final startY = centerY + math.sin(rotation) * radius * 0.5;
      final endX = centerX + math.cos(rotation + math.pi) * radius + wobble;
      final endY = centerY + math.sin(rotation + math.pi) * radius * 0.5;

      final colorIndex = randomInt(i * 157, 0, streakColors.length - 1);
      final strokeWidth = randomFloat(i * 163, 0.3, 1.0);
      final opacity = randomFloat(i * 167, settings.streakOpacity * 0.5, settings.streakOpacity * 1.0);

      final paint = Paint()
        ..color = streakColors[colorIndex].withValues(alpha: opacity)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  void _drawShapes(Canvas canvas, Size size) {
    final shapeColors = [
      const Color(0x0CFFFFFF), // White shapes
      const Color(0x0AF5F5F5), // Soft white
      const Color(0x08FFE4B5), // Warm amber
      const Color(0x06E6E6FA), // Pale lavender
      const Color(0x0AC0C0C0), // Silver
    ];

    // Random helper functions
    double randomFloat(int seed, double min, double max) {
      final random = (seed * 9301 + 49297) % 233280;
      return min + (random / 233280.0) * (max - min);
    }

    int randomInt(int seed, int min, int max) {
      final random = (seed * 9301 + 49297) % 233280;
      return min + (random % (max - min + 1));
    }

    // Randomly distributed floating shapes with chaotic movement
    final mainShapeCount = (settings.shapeCount * 0.6).toInt(); // ~60% of total shapes
    for (int i = 0; i < mainShapeCount; i++) {
      final positionSeed = i * 173 + (shapeValue * 700).toInt();
      final movementSeed = i * 179;
      final sizeSeed = i * 181;
      
      final baseX = randomFloat(positionSeed, 0.05, 0.95) * size.width;
      final baseY = randomFloat(positionSeed + 7, 0.05, 0.95) * size.height;
      final orbitalRadius = randomFloat(movementSeed, 10, 30); // Smaller radius: 20-60 -> 10-30
      final orbitalSpeed = randomFloat(movementSeed + 3, settings.shapeSpeed * 0.3, settings.shapeSpeed * 2.4);
      final wobbleAmplitude = randomFloat(i * 191, 3, 12); // Smaller wobble: 5-25 -> 3-12
      
      final angle = shapeValue * math.pi * 2 * orbitalSpeed + i * 1.7;
      final wobble = math.sin(shapeValue * math.pi * 0.2 + i * 0.8) * wobbleAmplitude; // Ultra slow wobble: 0.8 -> 0.2
      
      final x = baseX + math.cos(angle) * orbitalRadius + wobble;
      final y = baseY + math.sin(angle) * orbitalRadius * 0.7 + wobble * 0.5;

      final colorIndex = randomInt(i * 193, 0, shapeColors.length - 1);
      final opacity = randomFloat(i * 197, settings.shapeOpacity * 0.7, settings.shapeOpacity);
      final shapeSize = randomFloat(sizeSeed, settings.shapeSize * 0.5, settings.shapeSize * 1.5);
      
      final paint = Paint()
        ..color = shapeColors[colorIndex].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final shapeType = randomInt(i * 199, 0, 4);
      switch (shapeType) {
        case 0:
          // Circles with random sizes
          canvas.drawCircle(Offset(x, y), shapeSize * 0.7, paint);
          break;
        case 1:
          // Squares with random rotation
          final rotation = randomFloat(i * 211, 0, math.pi * 2);
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(rotation + shapeValue * math.pi * 0.05); // Ultra slow rotation
          final rect = Rect.fromCenter(center: Offset.zero, width: shapeSize, height: shapeSize);
          canvas.drawRect(rect, paint);
          canvas.restore();
          break;
        case 2:
          // Diamonds with random rotation
          final rotation = randomFloat(i * 223, 0, math.pi * 2);
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(rotation + shapeValue * math.pi * 0.08); // Ultra slow rotation
          final path = Path();
          path.moveTo(0, -shapeSize * 0.6);
          path.lineTo(shapeSize * 0.6, 0);
          path.lineTo(0, shapeSize * 0.6);
          path.lineTo(-shapeSize * 0.6, 0);
          path.close();
          canvas.drawPath(path, paint);
          canvas.restore();
          break;
        case 3:
          // Triangles with random rotation
          final rotation = randomFloat(i * 227, 0, math.pi * 2);
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(rotation + shapeValue * math.pi * 0.04); // Ultra slow rotation
          final path = Path();
          path.moveTo(0, -shapeSize * 0.7);
          path.lineTo(shapeSize * 0.6, shapeSize * 0.5);
          path.lineTo(-shapeSize * 0.6, shapeSize * 0.5);
          path.close();
          canvas.drawPath(path, paint);
          canvas.restore();
          break;
        case 4:
          // Stars (new shape type)
          final rotation = randomFloat(i * 229, 0, math.pi * 2);
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(rotation + shapeValue * math.pi * 0.1); // Ultra slow rotation
          final path = Path();
          for (int j = 0; j < 5; j++) {
            final angle = (j * math.pi * 2 / 5) - math.pi / 2;
            final outerRadius = shapeSize * 0.6;
            final innerRadius = shapeSize * 0.3;
            
            final outerX = math.cos(angle) * outerRadius;
            final outerY = math.sin(angle) * outerRadius;
            final innerAngle = angle + math.pi / 5;
            final innerX = math.cos(innerAngle) * innerRadius;
            final innerY = math.sin(innerAngle) * innerRadius;
            
            if (j == 0) {
              path.moveTo(outerX, outerY);
            } else {
              path.lineTo(outerX, outerY);
            }
            path.lineTo(innerX, innerY);
          }
          path.close();
          canvas.drawPath(path, paint);
          canvas.restore();
          break;
      }
    }
    
    // Chaotic accent shapes with completely random behavior
    final accentShapeCount = (settings.shapeCount * 0.4).toInt(); // ~40% of total shapes
    for (int i = 0; i < accentShapeCount; i++) {
      final chaosSeed = i * 233 + (shapeValue * 400).toInt();
      final speedSeed = i * 239;
      
      final chaosX = randomFloat(chaosSeed, 0, 1);
      final chaosY = randomFloat(chaosSeed + 11, 0, 1);
      final speedX = randomFloat(speedSeed, settings.shapeSpeed * 0.1, settings.shapeSpeed);
      final speedY = randomFloat(speedSeed + 13, settings.shapeSpeed * 0.1, settings.shapeSpeed);
      final amplitude = randomFloat(i * 241, 10, 25); // Smaller amplitude: 20-50 -> 10-25
      
      final x = (chaosX * size.width + 
                math.cos(shapeValue * math.pi * speedX + i * 1.1) * amplitude) % size.width;
      final y = (chaosY * size.height + 
                math.sin(shapeValue * math.pi * speedY + i * 0.9) * amplitude) % size.height;

      final colorIndex = randomInt(i * 251, 0, shapeColors.length - 1);
      final opacity = randomFloat(i * 257, settings.shapeOpacity * 0.4, settings.shapeOpacity * 1.1);
      final accentSize = randomFloat(i * 263, settings.shapeSize * 0.25, settings.shapeSize * 0.75);

      final paint = Paint()
        ..color = shapeColors[colorIndex].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Randomly choose between small circles and tiny shapes
      if (randomInt(i * 269, 0, 1) == 0) {
        canvas.drawCircle(Offset(x, y), accentSize, paint);
      } else {
        final rect = Rect.fromCenter(center: Offset(x, y), width: accentSize * 1.5, height: accentSize * 1.5);
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 