import 'package:flutter/material.dart';

/// A collection of animated widgets for the ArguMentor app
class AnimatedWidgets {
  /// A card that animates when tapped
  static Widget animatedCard({
    required Widget child,
    required VoidCallback onTap,
    Color? color,
    double elevation = 2.0,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            onTap();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..scale(isPressed ? 0.98 : 1.0)
              ..translate(0.0, isPressed ? 2.0 : 0.0),
            decoration: BoxDecoration(
              color: color ?? Theme.of(context).cardColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isPressed ? 0.1 : 0.2),
                  blurRadius: isPressed ? 3.0 : 5.0,
                  offset: Offset(0, isPressed ? 1.0 : 2.0),
                ),
              ],
            ),
            padding: padding,
            child: child,
          ),
        );
      },
    );
  }

  /// A button with a ripple effect
  static Widget rippleButton({
    required Widget child,
    required VoidCallback onTap,
    Color? color,
    Color? splashColor,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8)),
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  }) {
    return Material(
      color: color ?? Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: splashColor,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }

  /// A widget that animates when it first appears
  static Widget fadeInFromBottom({
    required Widget child,
    required int index,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeOutCubic,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: duration.inMilliseconds + (index * 100)),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// A widget that pulses to draw attention
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.97, end: 1.03),
          duration: duration,
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }

  /// A widget that animates its size when expanded or collapsed
  static Widget expandableContainer({
    required Widget child,
    required bool isExpanded,
    double collapsedHeight = 0.0,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      height: isExpanded ? null : collapsedHeight,
      constraints: isExpanded 
          ? const BoxConstraints() 
          : BoxConstraints(maxHeight: collapsedHeight),
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: isExpanded ? 1.0 : null,
          child: child,
        ),
      ),
    );
  }
}
