// lib/features/home/presentation/widgets/common/home_app_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/route_constants.dart';

class HomeAppBar extends StatefulWidget {
  final bool isExpanded;
  final double scrollOffset;

  const HomeAppBar({
    super.key,
    required this.isExpanded,
    required this.scrollOffset,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _glowController;
  late AnimationController _notificationController;

  late Animation<double> _logoRotation;
  late Animation<double> _glowAnimation;
  late Animation<double> _notificationAnimation;

  final int _notificationCount = 3;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _notificationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _logoRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_logoAnimationController);

    _glowAnimation = Tween<double>(
      begin: 0.5,
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
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _glowController.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = 1.0 - (widget.scrollOffset / 200).clamp(0.0, 1.0);
    final scale = 1.0 - (widget.scrollOffset / 500).clamp(0.0, 0.2);

    return SliverAppBar(
      expandedHeight: widget.isExpanded ? 120 : 80,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground.withOpacity(0.95),
              AppTheme.darkSurface.withOpacity(0.9),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Logo with animation
                    _buildAnimatedLogo(scale),

                    const SizedBox(width: 12),

                    // App name with fade effect
                    Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            'bookn',
                            style: AppTextStyles.heading1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Location selector
                    _buildLocationSelector(),

                    const SizedBox(width: 12),

                    // Notification bell
                    _buildNotificationBell(),

                    const SizedBox(width: 12),

                    // User avatar
                    _buildUserAvatar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(double scale) {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoRotation, _glowAnimation]),
      builder: (context, child) {
        return Container(
          width: 40 * scale,
          height: 40 * scale,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.3 * _glowAnimation.value),
                AppTheme.primaryBlue.withOpacity(0.1 * _glowAnimation.value),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring
              Transform.rotate(
                angle: _logoRotation.value,
                child: Container(
                  width: 40 * scale,
                  height: 40 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
              ),

              // Logo icon
              Container(
                width: 32 * scale,
                height: 32 * scale,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'B',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18 * scale,
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

  Widget _buildLocationSelector() {
    return GestureDetector(
      onTap: _openLocationSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 4),
            Text(
              'صنعاء',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return GestureDetector(
      onTap: _openNotifications,
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: _notificationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: math.sin(_notificationAnimation.value * math.pi) * 0.1,
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.textWhite,
                    size: 20,
                  ),
                );
              },
            ),
          ),

          // Notification badge
          if (_notificationCount > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.error, AppTheme.warning],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.darkCard,
                    width: 2,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  _notificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return GestureDetector(
      onTap: _openProfile,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _openLocationSelector() {
    HapticFeedback.lightImpact();
    // Open location selector
  }

  void _openNotifications() {
    HapticFeedback.lightImpact();
    context.push(RouteConstants.notifications);
  }

  void _openProfile() {
    HapticFeedback.lightImpact();
    context.push(RouteConstants.profile);
  }
}
