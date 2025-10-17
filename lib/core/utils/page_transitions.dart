import 'package:flutter/material.dart';

/// Custom page transitions for the ArguMentor app
class AppPageTransitions {
  /// Fade transition that smoothly fades in the new page
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = 0.0;
    const end = 1.0;
    const curve = Curves.easeInOut;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var fadeAnimation = animation.drive(tween);

    return FadeTransition(
      opacity: fadeAnimation,
      child: child,
    );
  }

  /// Slide transition that slides the new page in from the right
  static Widget slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var slideAnimation = animation.drive(tween);

    // Fade out the current page
    const beginOpacity = 0.0;
    const endOpacity = 1.0;
    var tweenOpacity = Tween(begin: beginOpacity, end: endOpacity)
        .chain(CurveTween(curve: curve));
    var fadeAnimation = animation.drive(tweenOpacity);

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }

  /// Scale transition that zooms in the new page
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = 0.9;
    const end = 1.0;
    const curve = Curves.easeOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var scaleAnimation = animation.drive(tween);

    // Fade animation
    const beginOpacity = 0.0;
    const endOpacity = 1.0;
    var tweenOpacity = Tween(begin: beginOpacity, end: endOpacity)
        .chain(CurveTween(curve: curve));
    var fadeAnimation = animation.drive(tweenOpacity);

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }

  /// Shared axis transition (vertical)
  static Widget sharedAxisTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade in animation
    const beginFade = 0.0;
    const endFade = 1.0;
    const curveFade = Curves.easeInOut;
    
    var tweenFade = Tween(begin: beginFade, end: endFade)
        .chain(CurveTween(curve: curveFade));
    var fadeAnimation = animation.drive(tweenFade);

    // Slide up animation
    const beginSlide = Offset(0.0, 0.05);
    const endSlide = Offset.zero;
    const curveSlide = Curves.easeOutCubic;
    
    var tweenSlide = Tween(begin: beginSlide, end: endSlide)
        .chain(CurveTween(curve: curveSlide));
    var slideAnimation = animation.drive(tweenSlide);

    // Secondary page animation (current page fading out)
    const secondaryBeginFade = 1.0;
    const secondaryEndFade = 0.0;
    
    var secondaryTweenFade = Tween(begin: secondaryBeginFade, end: secondaryEndFade)
        .chain(CurveTween(curve: curveFade));
    var secondaryFadeAnimation = secondaryAnimation.drive(secondaryTweenFade);

    // Scale animation for depth effect
    const beginScale = 1.0;
    const endScale = 0.95;
    
    var secondaryTweenScale = Tween(begin: beginScale, end: endScale)
        .chain(CurveTween(curve: curveSlide));
    var secondaryScaleAnimation = secondaryAnimation.drive(secondaryTweenScale);

    return FadeTransition(
      opacity: secondaryFadeAnimation,
      child: ScaleTransition(
        scale: secondaryScaleAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        ),
      ),
    );
  }
}
