// lib/features/home/presentation/widgets/sections/futuristic_explore_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class ExploreButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool enabled;
  final bool isCompact;
  final String? customText;
  final IconData? customIcon;

  const ExploreButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.isCompact = true,
    this.customText,
    this.customIcon,
  });

  @override
  State<ExploreButton> createState() => _ExploreButtonState();
}

class _ExploreButtonState extends State<ExploreButton>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _waveController;
  late AnimationController _iconController;
  late AnimationController _particleController;

  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _particleAnimation;

  // State
  bool _isPressed = false;
  bool _isHovered = false;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Pulse Animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Shimmer Animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));

    // Rotation Animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    // Scale Animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Glow Animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Wave Animation
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    // Icon Animation
    _iconController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _iconAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_iconController);

    // Particle Animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _particleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_particleController);
  }

  void _generateParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(_Particle());
    }
  }

  void _startAnimations() {
    if (widget.enabled) {
      _pulseController.repeat(reverse: true);
      _shimmerController.repeat();
      _rotationController.repeat();
      _glowController.repeat(reverse: true);
      _iconController.repeat();
      _particleController.repeat();
    }
  }

  @override
  void didUpdateWidget(ExploreButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _stopAnimations() {
    _pulseController.stop();
    _shimmerController.stop();
    _rotationController.stop();
    _glowController.stop();
    _iconController.stop();
    _particleController.stop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _waveController.dispose();
    _iconController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (!widget.enabled) return;

    setState(() => _isPressed = true);
    _scaleController.forward();
    _waveController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp() {
    if (!widget.enabled) return;

    setState(() => _isPressed = false);
    _scaleController.reverse();

    // Trigger haptic and call onPressed
    HapticFeedback.mediumImpact();
    widget.onPressed();

    // Reset wave after delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _waveController.reset();
      }
    });
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    _waveController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final height = widget.isCompact ? 48.0 : 56.0;
    final borderRadius = widget.isCompact ? 16.0 : 20.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _handleTapDown(),
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseAnimation,
            _scaleAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value *
                  (widget.enabled ? _pulseAnimation.value : 1.0),
              child: SizedBox(
                height: height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow Background
                    if (widget.enabled)
                      _buildGlowBackground(borderRadius, isDarkMode),

                    // Main Button Container
                    _buildMainButton(borderRadius, isDarkMode),

                    // Shimmer Effect
                    if (widget.enabled) _buildShimmerEffect(borderRadius),

                    // Wave Effect
                    if (_isPressed) _buildWaveEffect(borderRadius),

                    // Content
                    _buildButtonContent(isDarkMode),

                    // Particle Effects
                    if (widget.enabled && _isHovered) _buildParticles(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlowBackground(double borderRadius, bool isDarkMode) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              // Primary glow
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(
                  isDarkMode
                      ? 0.3 * _glowAnimation.value
                      : 0.2 * _glowAnimation.value,
                ),
                blurRadius: 20 + (10 * _glowAnimation.value),
                spreadRadius: 2,
              ),
              // Secondary glow
              BoxShadow(
                color: AppTheme.primaryPurple.withOpacity(
                  isDarkMode
                      ? 0.2 * _glowAnimation.value
                      : 0.15 * _glowAnimation.value,
                ),
                blurRadius: 30 + (15 * _glowAnimation.value),
                spreadRadius: -5,
              ),
              // Neon effect
              if (_isHovered)
                BoxShadow(
                  color: AppTheme.neonBlue.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainButton(double borderRadius, bool isDarkMode) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              width: 1.5,
              color: Colors.transparent,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.enabled ? 10 : 5,
                sigmaY: widget.enabled ? 10 : 5,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.enabled
                      ? LinearGradient(
                          begin: Alignment(
                            math.cos(_rotationAnimation.value),
                            math.sin(_rotationAnimation.value),
                          ),
                          end: Alignment(
                            -math.cos(_rotationAnimation.value),
                            -math.sin(_rotationAnimation.value),
                          ),
                          colors: isDarkMode
                              ? [
                                  AppTheme.primaryCyan.withOpacity(0.9),
                                  AppTheme.primaryBlue.withOpacity(0.9),
                                  AppTheme.primaryPurple.withOpacity(0.9),
                                  AppTheme.primaryViolet.withOpacity(0.9),
                                ]
                              : [
                                  AppTheme.primaryCyan.withOpacity(0.95),
                                  AppTheme.primaryBlue,
                                  AppTheme.primaryPurple,
                                  AppTheme.primaryViolet.withOpacity(0.95),
                                ],
                          stops: const [0.0, 0.3, 0.6, 1.0],
                        )
                      : LinearGradient(
                          colors: isDarkMode
                              ? [
                                  Colors.grey.shade800.withOpacity(0.5),
                                  Colors.grey.shade700.withOpacity(0.5),
                                ]
                              : [
                                  Colors.grey.shade400.withOpacity(0.5),
                                  Colors.grey.shade300.withOpacity(0.5),
                                ],
                        ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    width: 1,
                    color: widget.enabled
                        ? Colors.white.withOpacity(isDarkMode ? 0.2 : 0.3)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerEffect(double borderRadius) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CustomPaint(
            size: Size.infinite,
            painter: _ShimmerPainter(
              shimmerValue: _shimmerAnimation.value,
              isEnabled: widget.enabled,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveEffect(double borderRadius) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CustomPaint(
            size: Size.infinite,
            painter: _WavePainter(
              waveValue: _waveAnimation.value,
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent(bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated Icon
        _buildAnimatedIcon(isDarkMode),

        const SizedBox(width: 10),

        // Text with gradient
        _buildGradientText(isDarkMode),
      ],
    );
  }

  Widget _buildAnimatedIcon(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _iconAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _isHovered ? _iconAnimation.value * 0.5 : 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.5),
                ],
              ),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              widget.customIcon ?? Icons.explore_rounded,
              size: 16,
              color: widget.enabled
                  ? (isDarkMode ? AppTheme.primaryBlue : AppTheme.primaryPurple)
                  : Colors.grey,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientText(bool isDarkMode) {
    final text = widget.customText ?? 'استكشف الآن';

    return ShaderMask(
      shaderCallback: (bounds) {
        if (!widget.enabled) {
          return LinearGradient(
            colors: [
              Colors.grey.shade400,
              Colors.grey.shade400,
            ],
          ).createShader(bounds);
        }

        return LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: AppTextStyles.buttonMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: widget.isCompact ? 14 : 16,
          letterSpacing: 0.5,
          shadows: widget.enabled
              ? [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            animationValue: _particleAnimation.value,
          ),
        );
      },
    );
  }
}

// Particle class
class _Particle {
  late double x, y;
  late double vx, vy;
  late double radius;
  late double opacity;
  late Color color;

  _Particle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.02;
    vy = (math.Random().nextDouble() - 0.5) * 0.02;
    radius = math.Random().nextDouble() * 2 + 1;
    opacity = math.Random().nextDouble() * 0.5 + 0.5;

    final colors = [
      AppTheme.neonBlue,
      AppTheme.neonPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update() {
    x += vx;
    y += vy;

    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;

    opacity *= 0.99;
    if (opacity < 0.1) reset();
  }
}

// Custom Painters
class _ShimmerPainter extends CustomPainter {
  final double shimmerValue;
  final bool isEnabled;

  _ShimmerPainter({
    required this.shimmerValue,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isEnabled) return;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: [
          0.0,
          shimmerValue - 0.3,
          shimmerValue,
          shimmerValue + 0.3,
          1.0,
        ].map((e) => e.clamp(0.0, 1.0)).toList(),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WavePainter extends CustomPainter {
  final double waveValue;

  _WavePainter({required this.waveValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3 * (1 - waveValue))
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * waveValue;

    path.addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
      particle.update();

      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity * 0.5)
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
