// lib/features/home/presentation/widgets/common/futuristic_user_avatar.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class FuturisticUserAvatar extends StatefulWidget {
  final String? name;
  final String? imageUrl;
  final double size;
  final bool showOnlineStatus;
  final bool isOnline;
  final bool showBorder;
  final VoidCallback? onTap;
  final bool enableGlow;
  final bool enableAnimation;

  const FuturisticUserAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 48,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.showBorder = true,
    this.onTap,
    this.enableGlow = true,
    this.enableAnimation = true,
  });

  @override
  State<FuturisticUserAvatar> createState() => _FuturisticUserAvatarState();
}

class _FuturisticUserAvatarState extends State<FuturisticUserAvatar>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _entranceController;

  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _entranceAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );
  }

  void _startAnimations() {
    _entranceController.forward();

    if (widget.enableAnimation) {
      _glowController.repeat(reverse: true);
      _rotationController.repeat();

      if (widget.isOnline) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(FuturisticUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _glowAnimation,
            _rotationAnimation,
            _pulseAnimation,
            _entranceAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _entranceAnimation.value *
                  (_isPressed ? 0.9 : 1.0) *
                  (widget.isOnline ? _pulseAnimation.value : 1.0),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect background
                    if (widget.enableGlow) _buildGlowEffect(),

                    // Rotating border rings
                    if (widget.showBorder) _buildRotatingBorders(),

                    // Main avatar
                    _buildAvatar(),

                    // Online status indicator
                    if (widget.showOnlineStatus) _buildOnlineStatus(),

                    // Hover overlay
                    if (_isHovered && widget.onTap != null)
                      _buildHoverOverlay(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlowEffect() {
    return Container(
      width: widget.size * 1.4,
      height: widget.size * 1.4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.2 * _glowAnimation.value),
            AppTheme.primaryPurple.withOpacity(0.1 * _glowAnimation.value),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildRotatingBorders() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer rotating ring
        Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: widget.size * 1.15,
            height: widget.size * 1.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.3),
                  AppTheme.primaryPurple.withOpacity(0.1),
                  AppTheme.primaryCyan.withOpacity(0.2),
                  AppTheme.primaryBlue.withOpacity(0.3),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // Inner rotating ring (opposite direction)
        Transform.rotate(
          angle: -_rotationAnimation.value * 0.5,
          child: Container(
            width: widget.size * 1.05,
            height: widget.size * 1.05,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _isHovered
              ? AppTheme.primaryBlue.withOpacity(0.8)
              : AppTheme.primaryBlue.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(
              0.3 + (_isHovered ? 0.2 : 0),
            ),
            blurRadius: 15 + (_isHovered ? 5 : 0),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
            ? _buildImageAvatar()
            : _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildImageAvatar() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background gradient while loading
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),

        // Image with blur effect
        CachedNetworkImage(
          imageUrl: widget.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingPlaceholder(),
          errorWidget: (context, url, error) => _buildInitialsAvatar(),
        ),

        // Holographic overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryCyan.withOpacity(0.1),
                Colors.transparent,
                AppTheme.primaryPurple.withOpacity(0.1),
              ],
              transform: GradientRotation(_rotationAnimation.value * 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = _getInitials(widget.name ?? 'User');

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        backgroundBlendMode: BlendMode.luminosity,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid pattern background
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _AvatarPatternPainter(
              animation: _rotationAnimation.value * 0.1,
              color: Colors.white.withOpacity(0.1),
            ),
          ),

          // Initials with shimmer effect
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: const [
                  Colors.white,
                  Colors.white70,
                  Colors.white,
                ],
                stops: [
                  0.0,
                  0.5 + 0.3 * math.sin(_glowAnimation.value * math.pi),
                  1.0,
                ],
              ).createShader(bounds);
            },
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.size * 0.35,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.5,
          height: widget.size * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineStatus() {
    return Positioned(
      bottom: widget.size * 0.05,
      right: widget.size * 0.05,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: widget.size * 0.25,
        height: widget.size * 0.25,
        decoration: BoxDecoration(
          color: widget.isOnline ? AppTheme.success : AppTheme.textMuted,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.darkBackground,
            width: 2,
          ),
          boxShadow: widget.isOnline
              ? [
                  BoxShadow(
                    color: AppTheme.success.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: widget.isOnline
            ? AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.success.withOpacity(
                          0.5 * (1 - _pulseAnimation.value + 1),
                        ),
                        width: 2 * (_pulseAnimation.value - 0.9),
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget _buildHoverOverlay() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.darkBackground.withOpacity(0.3),
      ),
      child: Center(
        child: Icon(
          Icons.touch_app_rounded,
          color: Colors.white.withOpacity(0.7),
          size: widget.size * 0.3,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final names = name.trim().split(' ');

    if (names.isEmpty) return 'U';

    if (names.length == 1) {
      return names[0].length > 1
          ? names[0].substring(0, 2).toUpperCase()
          : names[0].toUpperCase();
    }

    return '${names[0][0]}${names[1][0]}'.toUpperCase();
  }
}

// Avatar pattern painter
class _AvatarPatternPainter extends CustomPainter {
  final double animation;
  final Color color;

  _AvatarPatternPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        size.width * 0.15 * i,
        paint,
      );
    }

    // Draw radial lines
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animation);

    for (int i = 0; i < 8; i++) {
      canvas.rotate(math.pi / 4);
      canvas.drawLine(
        const Offset(0, 0),
        Offset(size.width / 2, 0),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
