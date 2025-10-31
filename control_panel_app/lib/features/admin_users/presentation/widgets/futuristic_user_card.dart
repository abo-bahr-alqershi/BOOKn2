// lib/features/admin_users/presentation/widgets/futuristic_user_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/entities/user.dart';

class FuturisticUserCard extends StatefulWidget {
  final User user;
  final VoidCallback onTap;
  final Function(bool) onStatusToggle;
  final VoidCallback? onDelete;
  final Duration animationDelay;
  final bool isCompact; // للتحكم في حجم البطاقة

  const FuturisticUserCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onStatusToggle,
    this.onDelete,
    this.animationDelay = Duration.zero,
    this.isCompact = false,
  });

  @override
  State<FuturisticUserCard> createState() => _FuturisticUserCardState();
}

class _FuturisticUserCardState extends State<FuturisticUserCard>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _hoverController;
  late AnimationController _glowController;
  
  late Animation<double> _entranceAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );
    
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    );
    
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    
    if (widget.user.isActive) {
      _glowController.repeat(reverse: true);
    }
  }

  void _startAnimations() {
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _hoverController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // تحديد الحجم بناءً على عرض الشاشة
        final isSmallScreen = constraints.maxWidth < 400;
        final cardHeight = widget.isCompact 
            ? 180.0 
            : (isSmallScreen ? 220.0 : 240.0);
        
        return AnimatedBuilder(
          animation: Listenable.merge([
            _entranceAnimation,
            _hoverAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _entranceAnimation.value,
              child: Transform.translate(
                offset: Offset(0, -5 * _hoverAnimation.value),
                child: MouseRegion(
                  onEnter: (_) => _onHover(true),
                  onExit: (_) => _onHover(false),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isPressed = true),
                    onTapUp: (_) => setState(() => _isPressed = false),
                    onTapCancel: () => setState(() => _isPressed = false),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onTap();
                    },
                    child: AnimatedScale(
                      scale: _isPressed ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        height: cardHeight,
                        child: _buildCard(isSmallScreen),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCard(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: widget.user.isActive
                ? AppTheme.primaryBlue.withValues(alpha: 0.1 + 0.1 * _glowAnimation.value)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 20 + 10 * _hoverAnimation.value,
            offset: Offset(0, 8 + 4 * _hoverAnimation.value),
          ),
          if (widget.user.isActive)
            BoxShadow(
              color: AppTheme.success.withValues(alpha: 0.2 * _glowAnimation.value),
              blurRadius: 30,
              spreadRadius: -10,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkCard.withValues(alpha: 0.8),
                  AppTheme.darkCard.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(
                color: widget.user.isActive
                    ? AppTheme.success.withValues(alpha: 0.3 + 0.2 * _glowAnimation.value)
                    : AppTheme.darkBorder.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                if (_isHovered)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CardPatternPainter(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.03),
                      ),
                    ),
                  ),
                
                // Content
                Padding(
                  padding: EdgeInsets.all(
                    widget.isCompact 
                        ? AppDimensions.paddingSmall 
                        : AppDimensions.paddingMedium
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isSmallScreen),
                      const SizedBox(height: AppDimensions.spaceSmall),
                      _buildUserInfo(isSmallScreen),
                      const Spacer(),
                      _buildFooter(isSmallScreen),
                    ],
                  ),
                ),
                
                // Status indicator
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusIndicator(),
                ),
                
                // Delete button (if provided)
                if (widget.onDelete != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildDeleteButton(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    final avatarSize = widget.isCompact ? 40.0 : (isSmallScreen ? 45.0 : 50.0);
    
    return Row(
      children: [
        // Avatar
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.user.profileImage != null
                ? null
                : AppTheme.primaryGradient,
            border: Border.all(
              color: widget.user.isActive
                  ? AppTheme.success.withValues(alpha: 0.5)
                  : AppTheme.darkBorder,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.user.isActive
                    ? AppTheme.success.withValues(alpha: 0.3)
                    : Colors.transparent,
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: widget.user.profileImage != null
              ? ClipOval(
                  child: Image.network(
                    widget.user.profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar(isSmallScreen);
                    },
                  ),
                )
              : _buildDefaultAvatar(isSmallScreen),
        ),
        
        const SizedBox(width: AppDimensions.spaceSmall),
        
        // Role badge
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 8 : 10,
              vertical: widget.isCompact ? 3 : 4,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getRoleGradient(widget.user.role),
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getRoleGradient(widget.user.role)[0].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _getRoleText(widget.user.role),
              style: (widget.isCompact 
                  ? AppTextStyles.caption 
                  : AppTextStyles.bodySmall).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(bool isSmallScreen) {
    final initials = widget.user.name.isNotEmpty
        ? widget.user.name[0].toUpperCase()
        : 'U';
    
    return Center(
      child: Text(
        initials,
        style: (isSmallScreen 
            ? AppTextStyles.bodyMedium 
            : AppTextStyles.heading3).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserInfo(bool isSmallScreen) {
    final nameStyle = widget.isCompact
        ? AppTextStyles.bodyMedium
        : (isSmallScreen ? AppTextStyles.bodyLarge : AppTextStyles.heading3);
    
    final detailStyle = widget.isCompact
        ? AppTextStyles.caption
        : AppTextStyles.bodySmall;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          widget.user.name,
          style: nameStyle.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: widget.isCompact ? 14 : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: AppDimensions.spaceXSmall),
        
        // Email
        Row(
          children: [
            Icon(
              Icons.email_outlined,
              size: widget.isCompact ? 12 : 14,
              color: AppTheme.textMuted.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.user.email,
                style: detailStyle.copyWith(
                  color: AppTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        if (!widget.isCompact && widget.user.phone.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spaceXSmall),
          // Phone
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 14,
                color: AppTheme.textMuted.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.user.phone,
                  style: detailStyle.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Created date
        Expanded(
          child: Text(
            _formatDate(widget.user.createdAt),
            style: (widget.isCompact 
                ? AppTextStyles.caption 
                : AppTextStyles.bodySmall).copyWith(
              color: AppTheme.textMuted.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Status toggle
        _buildStatusToggle(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.isCompact ? 8 : 10,
          height: widget.isCompact ? 8 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.user.isActive
                ? AppTheme.success
                : AppTheme.textMuted,
            boxShadow: widget.user.isActive
                ? [
                    BoxShadow(
                      color: AppTheme.success.withValues(alpha: 0.8),
                      blurRadius: 6 + 4 * _glowAnimation.value,
                      spreadRadius: 1 + _glowAnimation.value,
                    ),
                  ]
                : [],
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onDelete?.call();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.delete_rounded,
          size: 14,
          color: AppTheme.error,
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    final width = widget.isCompact ? 36.0 : 40.0;
    final height = widget.isCompact ? 20.0 : 22.0;
    final circleSize = widget.isCompact ? 16.0 : 18.0;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onStatusToggle(!widget.user.isActive);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: widget.user.isActive
              ? LinearGradient(
                  colors: [AppTheme.success, AppTheme.neonGreen],
                )
              : null,
          color: !widget.user.isActive
              ? AppTheme.darkBorder.withValues(alpha: 0.5)
              : null,
          boxShadow: widget.user.isActive
              ? [
                  BoxShadow(
                    color: AppTheme.success.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          alignment: widget.user.isActive
              ? Alignment.centerRight
              : Alignment.centerLeft,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: circleSize,
            height: circleSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  void _onHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  List<Color> _getRoleGradient(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return [AppTheme.error, AppTheme.primaryViolet];
      case 'owner':
        return [AppTheme.primaryBlue, AppTheme.primaryPurple];
      case 'staff':
        return [AppTheme.warning, AppTheme.neonBlue];
      default:
        return [AppTheme.primaryCyan, AppTheme.neonGreen];
    }
  }

  String _getRoleText(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'مدير';
      case 'owner':
        return 'مالك';
      case 'staff':
        return 'موظف';
      case 'customer':
        return 'عميل';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CardPatternPainter extends CustomPainter {
  final Color color;

  _CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 20.0;
    
    for (double i = spacing; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    
    for (double i = spacing; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}