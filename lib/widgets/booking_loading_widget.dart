import 'package:flutter/cupertino.dart';

class BookingLoadingWidget extends StatefulWidget {
  final String message;
  final bool isVisible;
  final VoidCallback? onCancel;

  const BookingLoadingWidget({
    super.key,
    required this.message,
    required this.isVisible,
    this.onCancel,
  });

  @override
  State<BookingLoadingWidget> createState() => _BookingLoadingWidgetState();
}

class _BookingLoadingWidgetState extends State<BookingLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(BookingLoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: CupertinoColors.black.withValues(alpha: 0.6),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CupertinoActivityIndicator(
                      radius: 16,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.onCancel != null) ...[
                      const SizedBox(height: 16),
                      CupertinoButton(
                        onPressed: widget.onCancel,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BookingSuccessWidget extends StatefulWidget {
  final String message;
  final bool isVisible;
  final VoidCallback? onDismiss;

  const BookingSuccessWidget({
    super.key,
    required this.message,
    required this.isVisible,
    this.onDismiss,
  });

  @override
  State<BookingSuccessWidget> createState() => _BookingSuccessWidgetState();
}

class _BookingSuccessWidgetState extends State<BookingSuccessWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _controller.forward().then((_) {
        _checkController.forward();
      });
    }
  }

  @override
  void didUpdateWidget(BookingSuccessWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward().then((_) {
          _checkController.forward();
        });
      } else {
        _controller.reverse();
        _checkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      color: CupertinoColors.black.withValues(alpha: 0.6),
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: CupertinoColors.systemGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Transform.scale(
                            scale: _checkAnimation.value,
                            child: const Icon(
                              CupertinoIcons.check_mark,
                              color: CupertinoColors.white,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: widget.onDismiss,
                      child: const Text('Great!'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 