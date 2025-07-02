import 'package:flutter/material.dart';

// Custom painter for achievement background pattern
class AchievementPatternPainter extends CustomPainter {
  final Color color;
  
  AchievementPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Draw diagonal lines pattern
    for (double i = 0; i < size.width + size.height; i += 20) {
      final x1 = i < size.width ? i : 0.0;
      final y1 = i < size.width ? 0.0 : i - size.width;
      final x2 = i < size.height ? 0.0 : i - size.height;
      final y2 = i < size.height ? i : size.height;
      
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        paint..strokeWidth = 10,
      );
    }
    
    // Draw some circles
    for (int i = 0; i < 5; i++) {
      final radius = (i + 1) * 20.0;
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        radius,
        paint..strokeWidth = 2,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 