// lib/features/home/presentation/widgets/common/futuristic_home_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/constants/route_constants.dart';

class FuturisticHomeAppBar extends StatefulWidget {
  final bool isExpanded;
  final double scrollOffset;
  final String? userName;
  final String? userImage;
  final String currentLocation;
  final int notificationCount;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const FuturisticHomeAppBar({
    super.key,
    required this.isExpanded,
    required this.scrollOffset,
    this.userName,
    this.userImage,
    this.currentLocation = 'صنعاء',
    this.notificationCount = 0,
    this.onLocationTap,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  State<FuturisticHomeAppBar> createState() => _FuturisticHomeAppBarState();
}

class _FuturisticHomeAppBarState extends State<FuturisticHomeAppBar>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _glowController;
  late AnimationController _notificationController;
  late AnimationController _particleController;
  late AnimationController _waveController;

  late Animation<double> _logoRotation;
  late Animation<double> _glowAnimation;
  late Animation<double> _notificationAnimation;
  late Animation<double> _waveAnimation;

  bool _isLocationPressed = false;
  bool _isNotificationPressed = false;
  final bool _isProfilePressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _notificationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _logoRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.linear,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _notificationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _notificationController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _glowController.dispose();
    _notificationController.dispose();
    _particleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تأثيرات انتقال خفيفة
    final opacity = 1.0 - (widget.scrollOffset / 300).clamp(0.0, 0.1); // ~0.9
    final scale = 1.0 - (widget.scrollOffset / 400).clamp(0.0, 0.05); // ~0.95
    final blur = (widget.scrollOffset / 20).clamp(0.0, 10.0);

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      stretch: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,

      // الفارق المطلوب: 90 مقابل 73
      toolbarHeight: 73,
      collapsedHeight: 73,
      expandedHeight: 90,

      flexibleSpace: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkBackground,
                  AppTheme.darkSurface,
                  AppTheme.darkCard,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated wave background
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WaveBackgroundPainter(
                      animation: _waveAnimation.value,
                      color: AppTheme.primaryBlue.withOpacity(0.03),
                    ),
                  ),
                ),

                // Grid pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridOverlayPainter(
                      animation: _logoRotation.value * 0.1,
                      opacity: 0.02,
                    ),
                  ),
                ),

                // المحتوى الرئيسي بدون حدود سفلية + Blur داخل المساحة فقط
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(child: _buildContent(opacity, scale)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(double opacity, double scale) {
    return Row(
      children: [
        _buildFuturisticLogo(scale),
        const SizedBox(width: 10),

        // اسم التطبيق دائماً ظاهر بتأثير خفيف
        AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 200),
          child: Transform.scale(
            scale: scale,
            child: _buildAppName(),
          ),
        ),

        const Spacer(),
        _buildCompactLocationSelector(),
        const SizedBox(width: 8),
        _buildCompactNotificationBell(),
        const SizedBox(width: 8),
        _buildCompactUserAvatar(),
      ],
    );
  }

  Widget _buildFuturisticLogo(double scale) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoRotation,
        _glowAnimation,
        _particleController,
      ]),
      builder: (context, child) {
        return SizedBox(
          width: 36 * scale,
          height: 36 * scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 36 * scale,
                height: 36 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryBlue
                          .withOpacity(0.2 * _glowAnimation.value),
                      AppTheme.primaryPurple
                          .withOpacity(0.1 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Rotating rings
              ...List.generate(2, (index) {
                final offset = index * math.pi / 2;
                return Transform.rotate(
                  angle: _logoRotation.value + offset,
                  child: Container(
                    width: (36 - index * 4) * scale,
                    height: (36 - index * 4) * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue
                            .withOpacity(0.2 - index * 0.05),
                        width: 0.5,
                      ),
                    ),
                  ),
                );
              }),

              // Center logo
              Container(
                width: 28 * scale,
                height: 28 * scale,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'B',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14 * scale,
                    ),
                  ),
                ),
              ),

              // Orbiting particle
              Transform.rotate(
                angle: _particleController.value * 2 * math.pi,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: 36 * scale,
                  height: 36 * scale,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.neonBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonBlue,
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
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

  Widget _buildAppName() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppTheme.primaryCyan,
                AppTheme.primaryBlue,
                AppTheme.primaryPurple,
              ],
              stops: [
                0.0,
                0.5 + 0.2 * _glowAnimation.value,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: Text(
            'bookn',
            style: AppTextStyles.heading3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactLocationSelector() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isLocationPressed = true),
      onTapUp: (_) => setState(() => _isLocationPressed = false),
      onTapCancel: () => setState(() => _isLocationPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onLocationTap?.call();
      },
      child: AnimatedScale(
        scale: _isLocationPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.6),
                AppTheme.darkCard.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.15),
              width: 0.5,
            ),
            boxShadow: _isLocationPressed
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 10,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.currentLocation.isNotEmpty
                    ? widget.currentLocation
                    : 'حدد المدينة',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: AppTheme.textMuted.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNotificationBell() {
    final hasNotifications = widget.notificationCount > 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isNotificationPressed = true),
      onTapUp: (_) => setState(() => _isNotificationPressed = false),
      onTapCancel: () => setState(() => _isNotificationPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.onNotificationTap != null) {
          widget.onNotificationTap!();
        } else {
          context.push(RouteConstants.notifications);
        }
      },
      child: AnimatedScale(
        scale: _isNotificationPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: hasNotifications
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.2),
                            AppTheme.primaryPurple.withOpacity(0.1),
                          ],
                        )
                      : null,
                  color: !hasNotifications
                      ? AppTheme.darkCard.withOpacity(0.5)
                      : null,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasNotifications
                        ? AppTheme.primaryBlue.withOpacity(0.3)
                        : AppTheme.darkBorder.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _notificationAnimation,
                  builder: (context, child) {
                    final wiggle = hasNotifications
                        ? math.sin(_notificationAnimation.value * math.pi * 4) *
                            0.05
                        : 0.0;

                    return Transform.rotate(
                      angle: wiggle,
                      child: Icon(
                        hasNotifications
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_outlined,
                        color: hasNotifications
                            ? AppTheme.primaryBlue
                            : AppTheme.textMuted,
                        size: 16,
                      ),
                    );
                  },
                ),
              ),

              // Notification badge
              if (hasNotifications)
                Positioned(
                  top: 0,
                  right: 0,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.error, AppTheme.warning],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.darkBackground,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.error.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Center(
                            child: Text(
                              widget.notificationCount > 9
                                  ? '9+'
                                  : widget.notificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Pulse effect for new notifications
              if (hasNotifications)
                AnimatedBuilder(
                  animation: _notificationAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(
                            0.3 * (1 - _notificationAnimation.value),
                          ),
                          width: 1 + _notificationAnimation.value * 2,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactUserAvatar() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.onProfileTap != null) {
          widget.onProfileTap!();
        } else {
          context.push(RouteConstants.profile);
        }
      },
      child: AnimatedScale(
        scale: _isProfilePressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(
                      0.3 + 0.2 * _glowAnimation.value,
                    ),
                    blurRadius: 8 + 4 * _glowAnimation.value,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: widget.userImage != null
                  ? ClipOval(
                      child: Image.network(
                        widget.userImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      ),
                    )
                  : _buildDefaultAvatar(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final initials = _getInitials(widget.userName ?? 'مستخدم');

    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

// Wave background painter
class _WaveBackgroundPainter extends CustomPainter {
  final double animation;
  final Color color;

  _WaveBackgroundPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.8 +
          math.sin((x / size.width * 2 * math.pi) + (animation * 2 * math.pi)) *
              5;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Grid overlay painter
class _GridOverlayPainter extends CustomPainter {
  final double animation;
  final double opacity;

  _GridOverlayPainter({
    required this.animation,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(animation);
    canvas.translate(-size.width / 2, -size.height / 2);

    const spacing = 20.0;

    for (double x = -size.width; x < size.width * 2; x += spacing) {
      canvas.drawLine(
        Offset(x, -size.height),
        Offset(x, size.height * 2),
        paint,
      );
    }

    for (double y = -size.height; y < size.height * 2; y += spacing) {
      canvas.drawLine(
        Offset(-size.width, y),
        Offset(size.width * 2, y),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
