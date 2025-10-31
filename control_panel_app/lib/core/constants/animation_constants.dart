// lib/core/constants/animation_constants.dart

import 'package:flutter/animation.dart';

class AnimationConstants {
  AnimationConstants._();

  // Animation Types
  static const String fadeAnimation = 'fade';
  static const String slideAnimation = 'slide';
  static const String scaleAnimation = 'scale';
  static const String rotateAnimation = 'rotate';
  static const String parallaxAnimation = 'parallax';
  static const String shimmerAnimation = 'shimmer';
  static const String pulseAnimation = 'pulse';
  static const String bounceAnimation = 'bounce';
  static const String flipAnimation = 'flip';
  
  // Durations
  static const Duration microDuration = Duration(milliseconds: 100);
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);
  static const Duration extraLongDuration = Duration(milliseconds: 800);
  
  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve fastOutSlowInCurve = Curves.fastOutSlowIn;
  static const Curve decelerateCurve = Curves.decelerate;
  
  // Parallax Settings
  static const double parallaxOffset = 0.3;
  static const double parallaxSpeed = 0.5;
  
  // Shimmer Settings
  static const double shimmerGradientStart = -1.0;
  static const double shimmerGradientEnd = 2.0;
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  
  // Scale Values
  static const double minScale = 0.8;
  static const double maxScale = 1.0;
  static const double pressedScale = 0.95;
  static const double hoverScale = 1.05;
  
  // Slide Offsets
  static const double slideOffset = 50.0;
  static const double slideOffsetLarge = 100.0;
  
  // Rotation Values
  static const double quarterRotation = 0.25;
  static const double halfRotation = 0.5;
  static const double fullRotation = 1.0;
  
  // Opacity Values
  static const double invisibleOpacity = 0.0;
  static const double dimOpacity = 0.3;
  static const double halfOpacity = 0.5;
  static const double almostVisibleOpacity = 0.8;
  static const double visibleOpacity = 1.0;
  
  // Stagger Delays
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const Duration staggerDelayLong = Duration(milliseconds: 100);
  
  // Hero Animation Tags
  static const String propertyImageHeroTag = 'property_image_';
  static const String propertyTitleHeroTag = 'property_title_';
  static const String propertyPriceHeroTag = 'property_price_';
  static const String cityImageHeroTag = 'city_image_';
  
  // Carousel Animation
  static const double carouselScaleFactor = 0.85;
  static const Duration carouselTransitionDuration = Duration(milliseconds: 400);
  
  // Page Transition
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve pageTransitionCurve = Curves.easeInOut;
  
  // Countdown Timer
  static const Duration countdownTickDuration = Duration(seconds: 1);
  static const Duration countdownPulseDuration = Duration(milliseconds: 600);
  
  // Loading Animation
  static const Duration loadingRotationDuration = Duration(seconds: 1);
  static const double loadingRotationSpeed = 1.0;
  
  // Interactive Animations
  static const Duration tapFeedbackDuration = Duration(milliseconds: 100);
  static const Duration longPressDuration = Duration(milliseconds: 500);
  static const double dragSensitivity = 1.0;
  
  // 3D Effect Values
  static const double perspective = 0.002;
  static const double rotationFactor = 0.3;
  static const double depthFactor = 0.8;
}