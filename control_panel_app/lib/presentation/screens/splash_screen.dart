import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../injection_container.dart';
import '../../services/local_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late AnimationController _calendarController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _calendarAnimation;

  // Particles
  final List<_Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimationSequence();
    _navigateAfterDelay();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotate animation
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotateController);

    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_shimmerController);

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Calendar animation
    _calendarController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _calendarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_calendarController);

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textSlide = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
    ));
  }

  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      particles.add(_Particle());
    }
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    if (_logoController.status == AnimationStatus.dismissed) {
      _logoController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (_textController.status == AnimationStatus.dismissed) {
      _textController.forward();
    }
  }

  void _navigateAfterDelay() {
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    final localStorage = sl<LocalStorageService>();
    final isFirstRun = !localStorage.isOnboardingCompleted();

    if (isFirstRun) {
      context.go('/onboarding/select-city-currency');
      return;
    }

    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      context.go('/main');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkBackground,
                  AppTheme.darkBackground2,
                  AppTheme.darkBackground3,
                ],
              ),
            ),
          ),

          // Animated Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: particles,
                  animationValue: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Blur Overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Section
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _logoFade,
                    _logoScale,
                    _pulseAnimation,
                    _rotateAnimation,
                    _calendarAnimation,
                  ]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _logoFade,
                      child: Transform.scale(
                        scale: _logoScale.value * _pulseAnimation.value,
                        child: _buildBookingLogo(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // App Name
                AnimatedBuilder(
                  animation: Listenable.merge([_textFade, _textSlide]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _textFade,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: _buildAppName(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 100),

                // Loading Indicator with progress
                Column(
                  children: [
                    AnimatedBuilder(
                      animation: _textFade,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _textFade,
                          child: _buildBookingLoader(),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 200,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white12,
                      ),
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            widthFactor:
                                _shimmerController.value.clamp(0.0, 1.0),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: AppTheme.primaryGradient,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Text
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textFade,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _textFade,
                  child: _buildBottomText(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingLogo() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating Gradient Ring
          AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.primaryCyan,
                        AppTheme.primaryBlue,
                        AppTheme.primaryPurple,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),

          // Inner Circle with Glass Effect
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.cardGradient,
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 50,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: AppTheme.darkCard.withValues(alpha: 0.3),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _calendarAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _BookingIconPainter(
                            animationValue: _calendarAnimation.value,
                          ),
                          size: const Size(60, 60),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Shimmer Effect
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(75),
                  child: CustomPaint(
                    painter: _ShimmerPainter(
                      shimmerPosition: _shimmerAnimation.value,
                    ),
                  ),
                ),
              );
            },
          ),

          // Pulse Rings
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale =
                    1.0 + (index * 0.3) + (_pulseController.value * 0.2);
                final opacity =
                    (1.0 - (index * 0.3) - _pulseController.value) * 0.3;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue
                            .withValues(alpha: opacity.clamp(0.0, 1.0)),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAppName() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'bookn',
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              height: 1,
              color: AppTheme.textWhite,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'نظام إدارة الحجوزات الذكي',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight.withValues(alpha: 0.7),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingLoader() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          // Booking Calendar Loader Animation
          SizedBox(
            height: 40,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BookingLoaderPainter(
                    animationValue: _shimmerController.value,
                  ),
                  size: const Size(200, 40),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Loading text with dots
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              final dotCount = (_shimmerController.value * 3).floor() + 1;
              return Text(
                'جاري تحضير النظام${'.' * dotCount}',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  letterSpacing: 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomText() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.primaryBlue.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'حجوزات ذكية',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  letterSpacing: 2,
                  fontSize: 10,
                ),
              ),
            ),
            Container(
              width: 30,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'POWERED BY ARMA-SOFT',
          style: AppTextStyles.overline.copyWith(
            color: AppTheme.primaryBlue.withValues(alpha: 0.4),
            letterSpacing: 3,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Particle System
class _Particle {
  late double x;
  late double y;
  late double speed;
  late double radius;
  late double opacity;

  _Particle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    speed = math.Random().nextDouble() * 0.5 + 0.1;
    radius = math.Random().nextDouble() * 2 + 1;
    opacity = math.Random().nextDouble() * 0.5 + 0.1;
  }

  void update(double animationValue) {
    y -= speed * 0.01;
    if (y < 0) {
      y = 1.0;
      x = math.Random().nextDouble();
    }
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(animationValue);

      final paint = Paint()
        ..color = AppTheme.primaryBlue.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Shimmer Painter
class _ShimmerPainter extends CustomPainter {
  final double shimmerPosition;

  _ShimmerPainter({required this.shimmerPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(-1.0 + shimmerPosition * 2, -1.0 + shimmerPosition * 2),
      end: Alignment(-0.5 + shimmerPosition * 2, -0.5 + shimmerPosition * 2),
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.1),
        Colors.white.withValues(alpha: 0.2),
        Colors.white.withValues(alpha: 0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Booking Icon Painter - رسم أيقونة احترافية للحجوزات
class _BookingIconPainter extends CustomPainter {
  final double animationValue;

  _BookingIconPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Calendar Base
    final calendarPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = AppTheme.primaryGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    // Draw calendar outline
    final calendarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 5),
        width: size.width * 0.8,
        height: size.height * 0.6,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(calendarRect, calendarPaint);

    // Calendar header
    final headerPath = Path()
      ..moveTo(calendarRect.left, calendarRect.top + 12)
      ..lineTo(calendarRect.right, calendarRect.top + 12);
    canvas.drawPath(headerPath, calendarPaint);

    // Calendar rings (top)
    final ringPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = AppTheme.primaryGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawCircle(
      Offset(centerX - 10, calendarRect.top - 2),
      3,
      ringPaint,
    );
    canvas.drawCircle(
      Offset(centerX + 10, calendarRect.top - 2),
      3,
      ringPaint,
    );

    // Check mark with animation
    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.primaryCyan.withValues(
        alpha: animationValue,
      );

    final checkPath = Path();
    final progress = animationValue;

    if (progress > 0) {
      checkPath.moveTo(centerX - 8, centerY + 5);
      if (progress > 0.5) {
        checkPath.lineTo(centerX - 2, centerY + 11);
        if (progress > 0.7) {
          checkPath.lineTo(centerX + 8, centerY - 2);
        }
      }
      canvas.drawPath(checkPath, checkPaint);
    }

    // Calendar dots (dates) with animation
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.3);

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (i == 1 && j == 1) continue; // Skip center for check mark

        final dotX = centerX - 12 + (j * 12);
        final dotY = centerY + 18 + (i * 8);

        canvas.drawCircle(
          Offset(dotX, dotY),
          1.5,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Booking Loader Painter - رسم محمل احترافي للحجوزات
class _BookingLoaderPainter extends CustomPainter {
  final double animationValue;

  _BookingLoaderPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    const cardCount = 5;
    final cardWidth = size.width / (cardCount + 1);
    final cardHeight = size.height * 0.7;

    for (int i = 0; i < cardCount; i++) {
      final x = (i + 0.5) * cardWidth + cardWidth * 0.1;
      final delay = i * 0.1;
      final localAnimation = ((animationValue - delay) % 1.0).clamp(0.0, 1.0);

      // Card animation
      final y = size.height / 2 + math.sin(localAnimation * math.pi * 2) * 5;
      final scale = 0.8 + localAnimation * 0.2;

      // Draw card
      final cardRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, y),
          width: cardWidth * 0.7 * scale,
          height: cardHeight * scale,
        ),
        const Radius.circular(4),
      );

      final cardPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.3 + localAnimation * 0.3),
            AppTheme.primaryPurple
                .withValues(alpha: 0.2 + localAnimation * 0.2),
          ],
        ).createShader(cardRect.outerRect);

      canvas.drawRRect(cardRect, cardPaint);

      // Draw border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppTheme.primaryCyan.withValues(
          alpha: 0.5 + localAnimation * 0.5,
        );

      canvas.drawRRect(cardRect, borderPaint);

      // Draw check mark when animated
      if (localAnimation > 0.5) {
        final checkPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = AppTheme.primaryCyan.withValues(
            alpha: (localAnimation - 0.5) * 2,
          );

        final checkPath = Path()
          ..moveTo(x - 5, y)
          ..lineTo(x - 1, y + 4)
          ..lineTo(x + 5, y - 3);

        canvas.drawPath(checkPath, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
