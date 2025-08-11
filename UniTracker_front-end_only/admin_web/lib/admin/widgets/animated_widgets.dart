import 'package:flutter/material.dart';

class AnimatedWidgets {
  static Widget modernCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    double? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget scaleButton({
    required VoidCallback onTap,
    required Widget child,
    double? scale,
    Duration? duration,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: duration ?? const Duration(milliseconds: 150),
        child: child,
      ),
    );
  }

  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration? period,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      child: child,
    );
  }

  static Widget fadeIn({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: duration ?? const Duration(milliseconds: 500),
      curve: curve ?? Curves.easeInOut,
      child: child,
    );
  }

  static Widget slideIn({
    required Widget child,
    Offset? begin,
    Offset? end,
    Duration? duration,
    Curve? curve,
  }) {
    return AnimatedSlide(
      offset: end ?? Offset.zero,
      duration: duration ?? const Duration(milliseconds: 500),
      curve: curve ?? Curves.easeInOut,
      child: child,
    );
  }

  static Widget bounceIn({
    required Widget child,
    Duration? duration,
  }) {
    return AnimatedScale(
      scale: 1.0,
      duration: duration ?? const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      child: child,
    );
  }

  static Widget rotateIn({
    required Widget child,
    double? turns,
    Duration? duration,
  }) {
    return AnimatedRotation(
      turns: turns ?? 0.0,
      duration: duration ?? const Duration(milliseconds: 500),
      child: child,
    );
  }

  static Widget pulseAnimation({
    required Widget child,
    Duration? duration,
  }) {
    return AnimatedScale(
      scale: 1.0,
      duration: duration ?? const Duration(milliseconds: 1000),
      child: child,
    );
  }

  static Widget gradientButton({
    required VoidCallback onTap,
    required Widget child,
    List<Color>? colors,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    List<BoxShadow>? boxShadow,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors ?? [
              const Color(0xFF6366F1),
              const Color(0xFF6366F1).withOpacity(0.8),
            ],
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          boxShadow: boxShadow ?? [
            BoxShadow(
              color: (colors?.first ?? const Color(0xFF6366F1)).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  static Widget hoverCard({
    required Widget child,
    VoidCallback? onTap,
    Color? hoverColor,
    Duration? duration,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration ?? const Duration(milliseconds: 200),
          child: child,
        ),
      ),
    );
  }

  static Widget loadingSpinner({
    Color? color,
    double? size,
    double? strokeWidth,
  }) {
    return SizedBox(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        color: color ?? const Color(0xFF6366F1),
        strokeWidth: strokeWidth ?? 2.0,
      ),
    );
  }

  static Widget progressBar({
    required double progress,
    Color? backgroundColor,
    Color? progressColor,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height ?? 8,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.withOpacity(0.2),
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: progressColor ?? const Color(0xFF10B981),
            borderRadius: borderRadius ?? BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  static Widget countUp({
    required int value,
    Duration? duration,
    TextStyle? textStyle,
  }) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration ?? const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Text(
          value.toString(),
          style: textStyle,
        );
      },
    );
  }

  static Widget typeWriter({
    required String text,
    Duration? duration,
    TextStyle? textStyle,
  }) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: text.length),
      duration: duration ?? Duration(milliseconds: text.length * 50),
      builder: (context, value, child) {
        return Text(
          text.substring(0, value),
          style: textStyle,
        );
      },
    );
  }

  static Widget rippleEffect({
    required Widget child,
    Color? rippleColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: rippleColor ?? Colors.blue.withOpacity(0.2),
        highlightColor: rippleColor ?? Colors.blue.withOpacity(0.1),
        child: child,
      ),
    );
  }

  static Widget glowingBorder({
    required Widget child,
    Color? glowColor,
    double? glowRadius,
    double? borderWidth,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? const Color(0xFF6366F1)).withOpacity(0.5),
            blurRadius: glowRadius ?? 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: glowColor ?? const Color(0xFF6366F1),
            width: borderWidth ?? 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
