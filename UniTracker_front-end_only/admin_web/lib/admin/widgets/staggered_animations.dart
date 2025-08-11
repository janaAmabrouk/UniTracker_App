import 'package:flutter/material.dart';

class StaggeredAnimations {
  static List<Widget> createStaggeredList({
    required AnimationController controller,
    required List<Widget> children,
    Duration? staggerDelay,
    Duration? animationDuration,
    Curve? curve,
  }) {
    final delay = staggerDelay ?? const Duration(milliseconds: 100);
    final duration = animationDuration ?? const Duration(milliseconds: 600);
    final animationCurve = curve ?? Curves.easeOutCubic;

    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      
      final delayMilliseconds = delay.inMilliseconds * index;
      final totalDuration = duration.inMilliseconds + delayMilliseconds;
      
      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(
            delayMilliseconds / totalDuration,
            1.0,
            curve: animationCurve,
          ),
        ),
      );

      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: Opacity(
              opacity: animation.value,
              child: child,
            ),
          );
        },
        child: child,
      );
    }).toList();
  }

  static Widget staggeredFadeIn({
    required Widget child,
    required AnimationController controller,
    int index = 0,
    Duration? delay,
    Duration? duration,
    Curve? curve,
  }) {
    final delayDuration = delay ?? const Duration(milliseconds: 100);
    final animationDuration = duration ?? const Duration(milliseconds: 600);
    final animationCurve = curve ?? Curves.easeOutCubic;

    final delayMilliseconds = delayDuration.inMilliseconds * index;
    final totalDuration = animationDuration.inMilliseconds + delayMilliseconds;

    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delayMilliseconds / totalDuration,
          1.0,
          curve: animationCurve,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: child,
        );
      },
    );
  }

  static Widget staggeredSlideIn({
    required Widget child,
    required AnimationController controller,
    int index = 0,
    Offset? beginOffset,
    Duration? delay,
    Duration? duration,
    Curve? curve,
  }) {
    final delayDuration = delay ?? const Duration(milliseconds: 100);
    final animationDuration = duration ?? const Duration(milliseconds: 600);
    final animationCurve = curve ?? Curves.easeOutCubic;
    final startOffset = beginOffset ?? const Offset(0, 50);

    final delayMilliseconds = delayDuration.inMilliseconds * index;
    final totalDuration = animationDuration.inMilliseconds + delayMilliseconds;

    final animation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delayMilliseconds / totalDuration,
          1.0,
          curve: animationCurve,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.translate(
          offset: animation.value,
          child: child,
        );
      },
    );
  }

  static Widget staggeredScale({
    required Widget child,
    required AnimationController controller,
    int index = 0,
    double beginScale = 0.0,
    double endScale = 1.0,
    Duration? delay,
    Duration? duration,
    Curve? curve,
  }) {
    final delayDuration = delay ?? const Duration(milliseconds: 100);
    final animationDuration = duration ?? const Duration(milliseconds: 600);
    final animationCurve = curve ?? Curves.elasticOut;

    final delayMilliseconds = delayDuration.inMilliseconds * index;
    final totalDuration = animationDuration.inMilliseconds + delayMilliseconds;

    final animation = Tween<double>(
      begin: beginScale,
      end: endScale,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delayMilliseconds / totalDuration,
          1.0,
          curve: animationCurve,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.scale(
          scale: animation.value,
          child: child,
        );
      },
    );
  }

  static Widget staggeredRotation({
    required Widget child,
    required AnimationController controller,
    int index = 0,
    double beginRotation = 0.0,
    double endRotation = 1.0,
    Duration? delay,
    Duration? duration,
    Curve? curve,
  }) {
    final delayDuration = delay ?? const Duration(milliseconds: 100);
    final animationDuration = duration ?? const Duration(milliseconds: 600);
    final animationCurve = curve ?? Curves.easeOutCubic;

    final delayMilliseconds = delayDuration.inMilliseconds * index;
    final totalDuration = animationDuration.inMilliseconds + delayMilliseconds;

    final animation = Tween<double>(
      begin: beginRotation,
      end: endRotation,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delayMilliseconds / totalDuration,
          1.0,
          curve: animationCurve,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.rotate(
          angle: animation.value * 2 * 3.14159, // Convert to radians
          child: child,
        );
      },
    );
  }

  static Widget staggeredCombined({
    required Widget child,
    required AnimationController controller,
    int index = 0,
    Offset? slideOffset,
    double? scaleBegin,
    double? scaleEnd,
    Duration? delay,
    Duration? duration,
    Curve? curve,
  }) {
    final delayDuration = delay ?? const Duration(milliseconds: 100);
    final animationDuration = duration ?? const Duration(milliseconds: 600);
    final animationCurve = curve ?? Curves.easeOutCubic;
    final startOffset = slideOffset ?? const Offset(0, 30);
    final startScale = scaleBegin ?? 0.8;
    final finalScale = scaleEnd ?? 1.0;

    final delayMilliseconds = delayDuration.inMilliseconds * index;
    final totalDuration = animationDuration.inMilliseconds + delayMilliseconds;

    final slideAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delayMilliseconds / totalDuration,
          1.0,
          curve: animationCurve,
        ),
      ),
    );

    final scaleAnimation = Tween<double>(
      begin: startScale,
      end: finalScale,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delayMilliseconds / totalDuration,
          1.0,
          curve: animationCurve,
        ),
      ),
    );

    final opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delayMilliseconds / totalDuration,
          1.0,
          curve: animationCurve,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.translate(
          offset: slideAnimation.value,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Opacity(
              opacity: opacityAnimation.value,
              child: child,
            ),
          ),
        );
      },
    );
  }

  static Widget createStaggeredGrid({
    required AnimationController controller,
    required List<Widget> children,
    int crossAxisCount = 2,
    Duration? staggerDelay,
    Duration? animationDuration,
    Curve? curve,
  }) {
    final delay = staggerDelay ?? const Duration(milliseconds: 50);
    final duration = animationDuration ?? const Duration(milliseconds: 600);
    final animationCurve = curve ?? Curves.easeOutCubic;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        
        return staggeredCombined(
          child: child,
          controller: controller,
          index: index,
          delay: delay,
          duration: duration,
          curve: animationCurve,
        );
      },
    );
  }
}
