import 'package:flutter/material.dart';

/// Modern animated widgets for 2025 UI/UX
class AnimatedWidgets {
  
  /// Animated scale button with hover effect
  static Widget scaleButton({
    required Widget child,
    required VoidCallback onTap,
    double scaleFactor = 0.95,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return _ScaleButton(
      onTap: onTap,
      scaleFactor: scaleFactor,
      duration: duration,
      child: child,
    );
  }

  /// Animated slide transition
  static Widget slideIn({
    required Widget child,
    required AnimationController controller,
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
    Duration delay = Duration.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay.inMilliseconds / controller.duration!.inMilliseconds,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      )),
      child: child,
    );
  }

  /// Animated fade in
  static Widget fadeIn({
    required Widget child,
    required AnimationController controller,
    Duration delay = Duration.zero,
  }) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay.inMilliseconds / controller.duration!.inMilliseconds,
          1.0,
          curve: Curves.easeOut,
        ),
      )),
      child: child,
    );
  }

  /// Animated shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    return _ShimmerWidget(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }

  /// Modern card with hover animation
  static Widget modernCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets padding = const EdgeInsets.all(16),
    double borderRadius = 12,
    Color? color,
    List<BoxShadow>? boxShadow,
  }) {
    return _ModernCard(
      onTap: onTap,
      padding: padding,
      borderRadius: borderRadius,
      color: color,
      boxShadow: boxShadow,
      child: child,
    );
  }
}

class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;
  final Duration duration;

  const _ScaleButton({
    required this.child,
    required this.onTap,
    required this.scaleFactor,
    required this.duration,
  });

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerWidget({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _ModernCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? color;
  final List<BoxShadow>? boxShadow;

  const _ModernCard({
    required this.child,
    this.onTap,
    required this.padding,
    required this.borderRadius,
    this.color,
    this.boxShadow,
  });

  @override
  State<_ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<_ModernCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: widget.color ?? Colors.white,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: widget.boxShadow ?? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, _elevationAnimation.value / 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Staggered animation helper
class StaggeredAnimations {
  static List<Widget> createStaggeredList({
    required List<Widget> children,
    required AnimationController controller,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Offset slideBegin = const Offset(0, 0.3),
  }) {
    // Return children without animations to avoid FadeTransition wrapping Expanded widgets
    return children;
  }
}
