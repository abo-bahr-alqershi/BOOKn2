// lib/features/home/presentation/widgets/units/futuristic_unit_type_card.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class FuturisticUnitTypeCard extends StatefulWidget {
  final String id;
  final String name;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDelay;

  const FuturisticUnitTypeCard({
    super.key,
    required this.id,
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.animationDelay = Duration.zero,
  });

  @override
  State<FuturisticUnitTypeCard> createState() => _FuturisticUnitTypeCardState();
}

class _FuturisticUnitTypeCardState extends State<FuturisticUnitTypeCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _entranceController;
  late AnimationController _rippleController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _entranceAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));
  }

  void _startAnimations() {
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _entranceController.forward();
        if (widget.isSelected) {
          _glowController.repeat(reverse: true);
          _rippleController.repeat(reverse: true);
          _rotationController.repeat();
        }
        if (Theme.of(context).brightness != Brightness.dark) {
          _shimmerController.repeat();
        }
      }
    });
  }

  @override
  void didUpdateWidget(FuturisticUnitTypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _glowController.repeat(reverse: true);
        _rippleController.repeat(reverse: true);
        _rotationController.repeat();
      } else {
        _glowController.stop();
        _glowController.reset();
        _rippleController.stop();
        _rippleController.reset();
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _entranceController.dispose();
    _rippleController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _glowAnimation,
          _entranceAnimation,
          _rippleAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _entranceAnimation.value *
                (_isPressed ? _scaleAnimation.value : 1.0),
            child: Opacity(
              opacity: _entranceAnimation.value.clamp(0.0, 1.0),
              child: Container(
                width: 75,
                height: 95,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // الطبقة الأساسية - Glass Morphism احترافي
                    _buildGlassMorphismLayer(isDarkMode),

                    // تأثير التوهج للكارد المحدد
                    if (widget.isSelected) _buildSelectionGlow(isDarkMode),

                    // المحتوى الرئيسي
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // حاوي الأيقونة
                        _buildUnitIconContainer(isDarkMode),

                        const SizedBox(height: 8),

                        // النص مع تأثير احترافي
                        _buildTextWithEffect(isDarkMode),
                      ],
                    ),

                    // مؤشر التحديد المحسّن
                    if (widget.isSelected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildSelectionBadge(),
                      ),

                    // تأثير Shimmer للوضع الفاتح
                    if (!isDarkMode && !widget.isSelected)
                      _buildShimmerEffect(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassMorphismLayer(bool isDarkMode) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isDarkMode ? 10 : 15,
            sigmaY: isDarkMode ? 10 : 15,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Colors.white.withOpacity(0.03),
                        Colors.white.withOpacity(0.01),
                      ]
                    : [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.3),
                      ],
                stops: isDarkMode ? null : const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                width: 1,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.6),
                          Colors.white.withOpacity(0.2),
                        ],
                      ).colors.first,
              ),
              boxShadow: [
                // Inner shadow للعمق
                BoxShadow(
                  color: isDarkMode
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.25),
                  offset: const Offset(-1, -1),
                  blurRadius: 3,
                  spreadRadius: -1,
                ),
                // Outer shadow للطفو
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  offset: const Offset(2, 3),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionGlow(bool isDarkMode) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _rippleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _rippleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(
                      isDarkMode ? 0.1 : 0.08,
                    ),
                    AppTheme.primaryCyan.withOpacity(
                      isDarkMode ? 0.05 : 0.04,
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: _ShimmerPainter(
                shimmerValue: _shimmerAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextWithEffect(bool isDarkMode) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Shadow/Glow خلف النص للوضع الفاتح
        if (!isDarkMode && !widget.isSelected)
          Text(
            widget.name,
            style: AppTextStyles.caption.copyWith(
              color: widget.isSelected
                  ? AppTheme.primaryPurple
                  : isDarkMode
                      ? AppTheme.textWhite.withOpacity(0.8)
                      : AppTheme.textDark
                          .withOpacity(0.85), // نص داكن للوضع الفاتح
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 11,
              shadows: !isDarkMode
                  ? [
                      Shadow(
                        color: Colors.white.withOpacity(0.6),
                        offset: const Offset(0.5, 0.5),
                        blurRadius: 1,
                      ),
                    ]
                  : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

        // النص الأساسي
        ShaderMask(
          shaderCallback: (bounds) {
            if (widget.isSelected) {
              return LinearGradient(
                colors: [
                  AppTheme.primaryPurple,
                  AppTheme.primaryCyan,
                ],
              ).createShader(bounds);
            }
            return LinearGradient(
              colors: isDarkMode
                  ? [
                      AppTheme.textMuted.withOpacity(0.8),
                      AppTheme.textMuted.withOpacity(0.8),
                    ]
                  : [
                      AppTheme.textDark.withOpacity(0.9),
                      AppTheme.textDark.withOpacity(0.7),
                    ],
            ).createShader(bounds);
          },
          child: Text(
            widget.name,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitIconContainer(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // خلفية متحركة للأيقونة المحددة
              if (widget.isSelected)
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: SweepGradient(
                            colors: [
                              AppTheme.primaryPurple.withOpacity(0.0),
                              AppTheme.primaryPurple.withOpacity(0.3),
                              AppTheme.primaryCyan.withOpacity(0.3),
                              AppTheme.primaryPurple.withOpacity(0.0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  },
                ),

              // الحاوي الرئيسي للأيقونة - Glass effect احترافي
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryPurple.withOpacity(
                              isDarkMode ? 0.15 : 0.12,
                            ),
                            AppTheme.primaryCyan.withOpacity(
                              isDarkMode ? 0.10 : 0.08,
                            ),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.04),
                                ]
                              : [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.25),
                                ],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.primaryPurple.withOpacity(
                            0.3 + _glowAnimation.value * 0.2,
                          )
                        : isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.4),
                    width: widget.isSelected ? 1.5 : 0.8,
                  ),
                  boxShadow: [
                    // Inner glow للوضع الفاتح
                    if (!isDarkMode)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        offset: const Offset(-1, -1),
                        blurRadius: 3,
                        spreadRadius: -2,
                      ),
                    // Shadow للعمق
                    BoxShadow(
                      color: widget.isSelected
                          ? AppTheme.primaryPurple.withOpacity(
                              0.2 * _glowAnimation.value,
                            )
                          : Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
                      blurRadius: widget.isSelected ? 12 : 4,
                      spreadRadius: widget.isSelected ? 2 : -1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Icon(
                      _getIconForType(widget.icon),
                      size: 22,
                      color: widget.isSelected
                          ? widget.isSelected
                              ? AppTheme.primaryPurple
                              : AppTheme.primaryCyan
                          : isDarkMode
                              ? AppTheme.textWhite.withOpacity(0.6)
                              : AppTheme.textDark.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionBadge() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple,
                AppTheme.primaryCyan,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withOpacity(
                  0.4 + _glowAnimation.value * 0.2,
                ),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 10,
          ),
        );
      },
    );
  }

  IconData _getIconForType(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.bed_rounded;
    }

    final iconMap = <String, IconData>{
      // أيقونات الغرف والوحدات
      'bed': Icons.bed_rounded,
      'king_bed': Icons.king_bed_rounded,
      'single_bed': Icons.single_bed_rounded,
      'bedroom_parent': Icons.bedroom_parent_rounded,
      'bedroom_child': Icons.bedroom_child_rounded,
      'living_room': Icons.living_rounded,
      'dining_room': Icons.dining_rounded,
      'kitchen': Icons.kitchen_rounded,
      'bathroom': Icons.bathroom_rounded,
      'bathtub': Icons.bathtub_rounded,
      'shower': Icons.shower_rounded,
      'garage': Icons.garage_rounded,
      'balcony': Icons.balcony_rounded,
      'deck': Icons.deck_rounded,
      'yard': Icons.yard_rounded,
      'studio': Icons.weekend_rounded,
      'suite': Icons.meeting_room_rounded,
      'pool': Icons.pool_rounded,
      'wifi': Icons.wifi_rounded,
      'ac_unit': Icons.ac_unit_rounded,
    };

    return iconMap[iconName] ?? Icons.bed_rounded;
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }
}

// Custom Painter للتأثير اللامع
class _ShimmerPainter extends CustomPainter {
  final double shimmerValue;

  _ShimmerPainter({required this.shimmerValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: [
          0.0,
          shimmerValue - 0.2,
          shimmerValue,
          shimmerValue + 0.2,
          1.0,
        ].map((e) => e.clamp(0.0, 1.0)).toList(),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
