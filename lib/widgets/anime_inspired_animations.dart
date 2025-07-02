import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Anime.js inspired animation utilities for Flutter
/// Provides staggered, spring, morphing, and timeline animations

class AnimeAnimations {
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 400);
  static const Duration longDuration = Duration(milliseconds: 600);
  
  static const Curve easeInOutExpo = Curves.easeInOutExpo;
  static const Curve easeInOutQuad = Curves.easeInOutQuad;
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
}

/// Staggered Animation Container - inspired by anime.js stagger function
class StaggeredAnimationContainer extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Curve curve;
  final Axis direction;
  final bool autoStart;
  
  const StaggeredAnimationContainer({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOutQuad,
    this.direction = Axis.vertical,
    this.autoStart = true,
  });

  @override
  State<StaggeredAnimationContainer> createState() => _StaggeredAnimationContainerState();
}

class _StaggeredAnimationContainerState extends State<StaggeredAnimationContainer> 
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.autoStart) {
      _startStaggeredAnimation();
    }
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _slideAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 50.0, end: 0.0).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();
  }

  void _startStaggeredAnimation() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.direction == Axis.vertical
        ? Column(
            children: _buildAnimatedChildren(),
          )
        : Row(
            children: _buildAnimatedChildren(),
          );
  }

  List<Widget> _buildAnimatedChildren() {
    return List.generate(widget.children.length, (index) {
      return AnimatedBuilder(
        animation: _controllers[index],
        builder: (context, child) {
          return Transform.translate(
            offset: widget.direction == Axis.vertical
                ? Offset(0, _slideAnimations[index].value)
                : Offset(_slideAnimations[index].value, 0),
            child: Opacity(
              opacity: _fadeAnimations[index].value,
              child: widget.children[index],
            ),
          );
        },
      );
    });
  }
}

/// Spring Animation Button - inspired by anime.js spring physics
class SpringAnimationButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final double springTension;
  final double springFriction;
  
  const SpringAnimationButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.padding,
    this.borderRadius,
    this.springTension = 400.0,
    this.springFriction = 8.0,
  });

  @override
  State<SpringAnimationButton> createState() => _SpringAnimationButtonState();
}

class _SpringAnimationButtonState extends State<SpringAnimationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp() {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.color ?? Theme.of(context).primaryColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Morphing Icon - smooth transitions between different icons
class MorphingIcon extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final double? size;
  final Duration duration;
  
  const MorphingIcon({
    super.key,
    required this.icon,
    this.color,
    this.size,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<MorphingIcon> createState() => _MorphingIconState();
}

class _MorphingIconState extends State<MorphingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  IconData? _previousIcon;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    
    _previousIcon = widget.icon;
  }

  @override
  void didUpdateWidget(MorphingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.icon != widget.icon) {
      _previousIcon = oldWidget.icon;
      _controller.forward().then((_) {
        setState(() {
          _previousIcon = widget.icon;
        });
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * math.pi,
          child: Transform.scale(
            scale: 1.0 - _scaleAnimation.value,
            child: Icon(
              _controller.value < 0.5 ? _previousIcon : widget.icon,
              color: widget.color,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

/// Scroll-triggered animation container
class ScrollTriggeredAnimation extends StatefulWidget {
  final Widget child;
  final double triggerOffset;
  final Duration duration;
  final Curve curve;
  final bool slideFromBottom;
  final bool fadeIn;
  
  const ScrollTriggeredAnimation({
    super.key,
    required this.child,
    this.triggerOffset = 100.0,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeInOutQuad,
    this.slideFromBottom = true,
    this.fadeIn = true,
  });

  @override
  State<ScrollTriggeredAnimation> createState() => _ScrollTriggeredAnimationState();
}

class _ScrollTriggeredAnimationState extends State<ScrollTriggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: widget.slideFromBottom ? 50.0 : -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility(BuildContext context) {
    if (_hasTriggered) return;
    
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (position.dy < screenHeight - widget.triggerOffset) {
      _hasTriggered = true;
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility(context);
    });
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: widget.fadeIn ? _fadeAnimation.value : 1.0,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Pulsing indicator - similar to anime.js loop animations
class PulsingIndicator extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final Color? glowColor;
  
  const PulsingIndicator({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.9,
    this.maxScale = 1.1,
    this.glowColor,
  });

  @override
  State<PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.glowColor != null)
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor!.withValues(alpha: _opacityAnimation.value),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}

/// Loading dots animation - inspired by anime.js stagger
class LoadingDots extends StatefulWidget {
  final int dotCount;
  final Color color;
  final double size;
  final Duration duration;
  
  const LoadingDots({
    super.key,
    this.dotCount = 3,
    this.color = Colors.blue,
    this.size = 8.0,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animations = List.generate(widget.dotCount, (index) {
      final start = index / widget.dotCount;
      final end = (index + 1) / widget.dotCount;
      
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: _animations[index].value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
} 