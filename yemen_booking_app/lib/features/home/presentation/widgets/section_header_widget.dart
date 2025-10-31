// lib/features/home/presentation/widgets/sections/section_header_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class SectionHeaderWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onViewAll;
  final bool isGlowing;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onViewAll,
    this.isGlowing = false,
  });

  @override
  State<SectionHeaderWidget> createState() => _SectionHeaderWidgetState();
}

class _SectionHeaderWidgetState extends State<SectionHeaderWidget>
    with TickerProviderStateMixin {
  late AnimationController _iconRotationController;
  late AnimationController _glowController;
  late AnimationController _sparkleController;

  late Animation<double> _iconRotation;
  late Animation<double> _glowAnimation;

  final List<_Sparkle> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.isGlowing) {
      _generateSparkles();
    }
  }

  void _initializeAnimations() {
    _iconRotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _iconRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _iconRotationController,
      curve: Curves.linear,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateSparkles() {
    for (int i = 0; i < 5; i++) {
      _sparkles.add(_Sparkle());
    }
  }

  @override
  void dispose() {
    _iconRotationController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon with animations
        _buildAnimatedIcon(),

        const SizedBox(width: 12),

        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: widget.gradientColors,
                ).createShader(bounds),
                child: Text(
                  widget.title,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),

        // View all button
        _buildViewAllButton(),
      ],
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([_iconRotation, _glowAnimation]),
      builder: (context, child) {
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isGlowing
                ? [
                    BoxShadow(
                      color: widget.gradientColors[0].withOpacity(
                        0.4 * _glowAnimation.value,
                      ),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: widget.gradientColors[0].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sparkles for special sections
              if (widget.isGlowing)
                ...List.generate(_sparkles.length, (index) {
                  return AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, child) {
                      final sparkle = _sparkles[index];
                      sparkle.update(_sparkleController.value);

                      return Positioned(
                        left: sparkle.x * 44,
                        top: sparkle.y * 44,
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(sparkle.opacity),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                }),

              // Main icon
              Transform.rotate(
                angle: widget.isGlowing ? _iconRotation.value * 0.2 : 0,
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewAllButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onViewAll();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.6),
                AppTheme.darkCard.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.gradientColors[0].withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'عرض الكل',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: widget.gradientColors[0],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sparkle model for glowing effect
class _Sparkle {
  double x = 0;
  double y = 0;
  double opacity = 0;
  double speed = 0;

  _Sparkle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    opacity = 0;
    speed = math.Random().nextDouble() * 2 + 1;
  }

  void update(double animationValue) {
    opacity = math.sin(animationValue * math.pi * speed) * 0.8;
    if (opacity < 0) opacity = 0;
  }
}
