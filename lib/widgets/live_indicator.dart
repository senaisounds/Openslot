import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

class LiveIndicator extends StatefulWidget {
  final double? randomOffset;
  
  const LiveIndicator({
    super.key, 
    this.randomOffset,
  });

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late double _effectiveRandomOffset;

  @override
  void initState() {
    super.initState();
    
    // Calculate the effective random offset once during initialization
    _effectiveRandomOffset = widget.randomOffset ?? math.Random().nextDouble();
    
    // Base animation duration
    const baseDuration = Duration(milliseconds: 1500);
    
    // Apply random offset to animation duration (±20%)
    final randomizedDuration = Duration(
      milliseconds: (baseDuration.inMilliseconds * (0.8 + (_effectiveRandomOffset * 0.4))).round()
    );
    
    _animationController = AnimationController(
      vsync: this,
      duration: randomizedDuration,
    );
    
    // Offset the starting value of the animation based on the random value
    _animationController.value = _effectiveRandomOffset;
    
    _opacityAnimation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Make the animation repeat in reverse when it completes
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemRed.withValues(alpha: _opacityAnimation.value * 0.5),
                      blurRadius: 5,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),
            ),
            // Core dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withValues(alpha: _opacityAnimation.value * 0.8),
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
} 