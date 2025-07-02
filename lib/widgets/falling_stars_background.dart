import 'dart:math' as math;
import 'package:flutter/material.dart';


enum StarType { star, dot, sparkle }

class FallingStar {
  Offset position;
  double size;
  double speed;
  double opacity;
  double twinklePhase;
  double trail;
  StarType type;
  double rotation;
  double rotationSpeed;
  Color color;
  
  // Physics properties for realistic movement
  double velocityX = 0.0;
  double velocityY = 0.0;
  double accelerationX = 0.0;
  double accelerationY = 0.0;
  double mass = 1.0;
  double drag = 0.99; // Air resistance (very minimal)

  FallingStar({
    required this.position,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.twinklePhase,
    required this.trail,
    required this.type,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
  }) {
    // Initialize physics with realistic values
    final random = math.Random();
    mass = 0.5 + random.nextDouble() * 1.5; // Varied mass (0.5-2.0)
    velocityY = speed * 0.5; // Initial downward velocity
    velocityX = (random.nextDouble() - 0.5) * speed * 0.1; // Small horizontal drift
    accelerationY = 9.8 * 0.01; // Gravity (scaled down for smooth effect)
    accelerationX = 0.0;
  }

  void update(Size screenSize, double deltaTime) {
    // Ultra-simple movement for maximum performance
    position = Offset(
      position.dx + speed * 0.001 * deltaTime, // Minimal horizontal drift
      position.dy + speed * 0.05 * deltaTime,  // Slow vertical fall
    );
    
    // Simple twinkle
    twinklePhase += deltaTime * 0.1;
    
    // Simple rotation
    rotation += rotationSpeed * 0.02 * deltaTime;
    
    // Reset when off screen
    if (position.dy > screenSize.height + 100) {
      _resetPosition(screenSize);
    }
  }

  void _resetPosition(Size screenSize) {
    final random = math.Random();
    position = Offset(
      -100 + random.nextDouble() * (screenSize.width * 1.2),
      -100 - random.nextDouble() * screenSize.height * 0.3,
    );
    size = 1.2 + random.nextDouble() * 2.5; // More visible particles
    speed = 2.5 + random.nextDouble() * 3.0; // Noticeable movement
    opacity = 0.25 + random.nextDouble() * 0.35; // More visible but still atmospheric
    twinklePhase = random.nextDouble() * math.pi * 2;
    trail = 8.0 + random.nextDouble() * 12.0;
    rotation = random.nextDouble() * math.pi * 2;
    rotationSpeed = (random.nextDouble() - 0.5) * 0.4; // Slower rotation
    
    // Reset physics properties
    mass = 0.5 + random.nextDouble() * 1.5;
    velocityY = speed * 0.3; // Initial gentle downward velocity
    velocityX = (random.nextDouble() - 0.5) * speed * 0.05; // Minimal horizontal drift
    accelerationY = 9.8 * 0.005; // Gentle gravity
    accelerationX = 0.0;
    
    // Live performance atmosphere colors - stage lighting inspired
    final colors = [
      const Color(0x80FFB74D), // Warm stage orange
      const Color(0x70FFFFFF), // Bright white spotlight
      const Color(0x75E1BEE7), // Purple stage lighting
      const Color(0x60FFD700), // Golden spotlight
      const Color(0x65F0F0F0), // Cool white light
      const Color(0x70FFE4B5), // Warm amber lighting
      const Color(0x55E6E6FA), // Lavender mood lighting
      const Color(0x75C0C0C0), // Silver spotlight
      const Color(0x60FFF8DC), // Cream stage light
      const Color(0x65DCDCDC), // Soft gray light
    ];
    color = colors[random.nextInt(colors.length)];
    
    // Randomly assign star type
    final typeRandom = random.nextDouble();
    if (typeRandom < 0.5) {
      type = StarType.star;
    } else if (typeRandom < 0.75) {
      type = StarType.dot;
    } else {
      type = StarType.sparkle;
    }
  }
}

class FallingStarsBackground extends StatefulWidget {
  const FallingStarsBackground({super.key});

  @override
  State<FallingStarsBackground> createState() => _FallingStarsBackgroundState();
}

class _FallingStarsBackgroundState extends State<FallingStarsBackground>
    with SingleTickerProviderStateMixin {
  
  final List<FallingStar> _stars = [];
  late AnimationController _animationController;
  late DateTime _lastFrameTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    _lastFrameTime = DateTime.now();
    
    // Initialize stars
    _initializeStars();
  }

  void _initializeStars() {
    final random = math.Random();
    
    // Reduced to 10 particles for maximum performance
    for (int i = 0; i < 10; i++) {
      // Randomly assign star type
      final typeRandom = random.nextDouble();
      StarType starType;
      if (typeRandom < 0.5) {
        starType = StarType.star;
      } else if (typeRandom < 0.75) {
        starType = StarType.dot;
      } else {
        starType = StarType.sparkle;
      }
      
      // Live performance atmosphere colors - more visible but still atmospheric
      final colors = [
        const Color(0x80FFB74D), // Warm stage orange
        const Color(0x70FFFFFF), // Bright white spotlight
        const Color(0x75E1BEE7), // Purple stage lighting
        const Color(0x60FFD700), // Golden spotlight
        const Color(0x65F0F0F0), // Cool white light
        const Color(0x70FFE4B5), // Warm amber lighting
        const Color(0x55E6E6FA), // Lavender mood lighting
        const Color(0x75C0C0C0), // Silver spotlight
        const Color(0x60FFF8DC), // Cream stage light
        const Color(0x65DCDCDC), // Soft gray light
      ];
      
      _stars.add(FallingStar(
        position: Offset(
          random.nextDouble() * 400, // Will be adjusted when size is known
          random.nextDouble() * 800, // Will be adjusted when size is known
        ),
        size: 1.2 + random.nextDouble() * 2.5,
        speed: 2.5 + random.nextDouble() * 3.0, // Noticeable movement for live atmosphere
        opacity: 0.25 + random.nextDouble() * 0.35,
        twinklePhase: random.nextDouble() * math.pi * 2,
        trail: 8.0 + random.nextDouble() * 12.0,
        type: starType,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.4,
        color: colors[random.nextInt(colors.length)],
      ));
    }
  }

  @override
  void didUpdateWidget(FallingStarsBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure animation continues smoothly after hot reload
    if (!_animationController.isAnimating) {
      _animationController.repeat();
    }
    
    // Force repaint to ensure animation is visible
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final now = DateTime.now();
          var deltaTime = now.difference(_lastFrameTime).inMilliseconds / 1000.0;
          _lastFrameTime = now;
          
          // Cap delta time to prevent jumps during hot reload
          deltaTime = deltaTime.clamp(0.0, 0.05); // Max 50ms delta for smoothness
          
          return CustomPaint(
            painter: FallingStarsPainter(
              stars: _stars,
              deltaTime: deltaTime,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class FallingStarsPainter extends CustomPainter {
  final List<FallingStar> stars;
  final double deltaTime;

  FallingStarsPainter({
    required this.stars,
    required this.deltaTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update all stars
    for (final star in stars) {
      star.update(size, deltaTime);
    }
    
    // Draw stars
    for (final star in stars) {
      _drawStar(canvas, star);
    }
  }

  void _drawStar(Canvas canvas, FallingStar star) {
    // Gentle twinkle effect
    final twinkleIntensity = (math.sin(star.twinklePhase) + 1) / 2;
    final smoothTwinkle = twinkleIntensity * twinkleIntensity * (3.0 - 2.0 * twinkleIntensity);
    final currentOpacity = star.opacity * (0.5 + smoothTwinkle * 0.3);
    
    // Draw based on star type
    switch (star.type) {
      case StarType.star:
        _drawFivePointedStar(canvas, star, currentOpacity);
        break;
      case StarType.dot:
        _drawDot(canvas, star, currentOpacity);
        break;
      case StarType.sparkle:
        _drawSparkle(canvas, star, currentOpacity, smoothTwinkle);
        break;
    }
  }
  
  void _drawFivePointedStar(Canvas canvas, FallingStar star, double opacity) {
    final paint = Paint()
      ..color = star.color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    
    // Create 5-pointed star path
    final path = Path();
    final radius = star.size;
    final innerRadius = radius * 0.4;
    
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) + star.rotation;
      final r = i.isEven ? radius : innerRadius;
      final x = star.position.dx + r * math.cos(angle);
      final y = star.position.dy + r * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    // Soft glow with the same color
    final glowPaint = Paint()
      ..color = star.color.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(star.position, radius * 1.8, glowPaint);
    
    // Draw the star
    canvas.drawPath(path, paint);
  }
  
  void _drawDot(Canvas canvas, FallingStar star, double opacity) {
    // Soft dot with gentle glow
    final glowPaint = Paint()
      ..color = star.color.withValues(alpha: opacity * 0.25)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(star.position, star.size * 1.6, glowPaint);
    
    final dotPaint = Paint()
      ..color = star.color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(star.position, star.size * 0.7, dotPaint);
  }
  
  void _drawSparkle(Canvas canvas, FallingStar star, double opacity, double twinkle) {
    // Gentle 4-pointed sparkle
    final sparklePaint = Paint()
      ..color = star.color.withValues(alpha: opacity * 0.9)
      ..strokeWidth = star.size * 0.3
      ..strokeCap = StrokeCap.round;
    
    final sparkleSize = star.size * (0.8 + twinkle * 0.4);
    
    // Rotate the sparkle
    canvas.save();
    canvas.translate(star.position.dx, star.position.dy);
    canvas.rotate(star.rotation);
    
    // Vertical line
    canvas.drawLine(
      Offset(0, -sparkleSize),
      Offset(0, sparkleSize),
      sparklePaint,
    );
    
    // Horizontal line
    canvas.drawLine(
      Offset(-sparkleSize, 0),
      Offset(sparkleSize, 0),
      sparklePaint,
    );
    
    canvas.restore();
    
    // Soft glow
    final glowPaint = Paint()
      ..color = star.color.withValues(alpha: opacity * 0.2)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(star.position, sparkleSize * 1.3, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 