// lib/features/admin_services/presentation/widgets/futuristic_service_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/pricing_model.dart';
import '../utils/service_icons.dart';

/// 🎴 Ultra Premium Service Card - Fixed Version
class FuturisticServiceCard extends StatefulWidget {
  final Service service;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;

  const FuturisticServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
  });

  @override
  State<FuturisticServiceCard> createState() => _FuturisticServiceCardState();
}

class _FuturisticServiceCardState extends State<FuturisticServiceCard>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  bool _isHovered = false;
  bool _isPressed = false;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    // Device detection
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    final icon = ServiceIcons.getIconByName(widget.service.icon);

    return MouseRegion(
      onEnter: !isMobile
          ? (_) {
              setState(() => _isHovered = true);
              _animationController.forward();
            }
          : null,
      onExit: !isMobile
          ? (_) {
              setState(() => _isHovered = false);
              _animationController.reverse();
            }
          : null,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        onLongPress: isMobile
            ? () {
                setState(() => _showActions = !_showActions);
                HapticFeedback.mediumImpact();
              }
            : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _shimmerAnimation,
            _pulseAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed
                  ? 0.96
                  : (_isHovered ? _scaleAnimation.value : 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: isMobile ? 0 : 2,
                  vertical: isMobile ? 4 : 4,
                ),
                child: Stack(
                  children: [
                    // Main Card
                    _buildMainCard(
                      icon: icon,
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    ),

                    // Shimmer Effect
                    if (_isHovered && !isMobile) _buildShimmerOverlay(),

                    // Selection Indicator
                    if (widget.isSelected) _buildSelectionIndicator(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainCard({
    required IconData icon,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.isDark ? AppTheme.darkCard.withOpacity(0.9) : Colors.white,
            AppTheme.isDark
                ? AppTheme.darkCard.withOpacity(0.7)
                : Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(
          isMobile ? 16 : 20,
        ),
        border: Border.all(
          color: widget.isSelected
              ? AppTheme.primaryBlue.withOpacity(0.5)
              : _isHovered
                  ? AppTheme.primaryBlue.withOpacity(0.3)
                  : AppTheme.darkBorder.withOpacity(0.1),
          width: widget.isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isSelected
                ? AppTheme.primaryBlue.withOpacity(0.2)
                : _isHovered
                    ? AppTheme.primaryBlue.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
            blurRadius: _isHovered ? 30 : 15,
            offset: Offset(0, _isHovered ? 8 : 4),
            spreadRadius: _isHovered ? 5 : 0,
          ),
          if (_isHovered)
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(-5, -5),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              splashColor: AppTheme.primaryBlue.withOpacity(0.1),
              highlightColor: AppTheme.primaryBlue.withOpacity(0.05),
              child: _buildCardContent(
                icon: icon,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent({
    required IconData icon,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    if (isMobile) {
      return _buildMobileLayout(icon);
    } else if (isTablet) {
      return _buildTabletLayout(icon);
    } else {
      return _buildDesktopLayout(icon);
    }
  }

  Widget _buildMobileLayout(IconData icon) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use flexible layout to prevent overflow
        return Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Animated Icon Container
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue
                                    .withOpacity(0.15 * _pulseAnimation.value),
                                AppTheme.primaryPurple
                                    .withOpacity(0.08 * _pulseAnimation.value),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 10),

                    // Title and Property
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              widget.service.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.6,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.service.propertyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.primaryBlue,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // More Button
                    if (widget.onEdit != null || widget.onDelete != null)
                      _buildMobileActionButton(),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Price Section - Compact
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.success.withOpacity(0.08),
                      AppTheme.success.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.success.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${widget.service.price.amount}',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.service.price.currency,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.success.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.service.pricingModel.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.success,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Animated Actions (shown on long press)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _showActions
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            if (widget.onEdit != null)
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.edit_outlined,
                                  label: 'تعديل',
                                  color: AppTheme.primaryBlue,
                                  onTap: () {
                                    widget.onEdit?.call();
                                    setState(() => _showActions = false);
                                  },
                                ),
                              ),
                            if (widget.onEdit != null &&
                                widget.onDelete != null)
                              const SizedBox(width: 6),
                            if (widget.onDelete != null)
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.delete_outline,
                                  label: 'حذف',
                                  color: AppTheme.error,
                                  onTap: () {
                                    widget.onDelete?.call();
                                    setState(() => _showActions = false);
                                  },
                                ),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout(IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon Section
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue
                          .withOpacity(0.15 * _pulseAnimation.value),
                      AppTheme.primaryPurple
                          .withOpacity(0.08 * _pulseAnimation.value),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              );
            },
          ),

          const SizedBox(width: 14),

          // Info Section
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          widget.service.propertyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.primaryBlue,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    if (_isHovered) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Icons.${widget.service.icon}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted.withOpacity(0.5),
                            fontFamily: 'monospace',
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Price Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${widget.service.price.amount}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    widget.service.price.currency,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.success.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.service.pricingModel.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Actions
          if (widget.onEdit != null || widget.onDelete != null) ...[
            const SizedBox(width: 8),
            _buildDesktopActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Animated Icon
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _isHovered ? _rotationAnimation.value * 0.1 : 0,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.15),
                        AppTheme.primaryPurple.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.primaryBlue
                          .withOpacity(_isHovered ? 0.3 : 0.2),
                      width: _isHovered ? 1.5 : 1,
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryBlue,
                    size: 30,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 20),

          // Info Section
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.1),
                            AppTheme.primaryPurple.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 14,
                            color: AppTheme.primaryBlue.withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.service.propertyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isHovered) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Icons.${widget.service.icon}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.5),
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Price Section
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.success.withOpacity(0.08),
                  AppTheme.success.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.success.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${widget.service.price.amount}',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.service.price.currency,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.success.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.service.pricingModel.label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.success.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (widget.onEdit != null || widget.onDelete != null) ...[
            const SizedBox(width: 16),
            _buildDesktopActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  AppTheme.primaryBlue
                      .withOpacity(0.05 * _shimmerAnimation.value),
                  AppTheme.primaryPurple
                      .withOpacity(0.03 * _shimmerAnimation.value),
                  Colors.transparent,
                ],
                stops: [
                  0.0,
                  0.4 + 0.2 * _shimmerAnimation.value,
                  0.6 + 0.2 * _shimmerAnimation.value,
                  1.0,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildMobileActionButton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(
          Icons.more_vert_rounded,
          color: AppTheme.textMuted,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppTheme.isDark ? AppTheme.darkCard : Colors.white,
        elevation: 8,
        onSelected: _handleAction,
        itemBuilder: (context) => _buildMenuItems(),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopActions() {
    return Row(
      children: [
        if (widget.onEdit != null)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onEdit?.call();
            },
            icon: Icon(
              Icons.edit_outlined,
              color: AppTheme.primaryBlue.withOpacity(_isHovered ? 1 : 0.7),
              size: 20,
            ),
            tooltip: 'تعديل',
          ),
        if (widget.onDelete != null)
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onDelete?.call();
            },
            icon: Icon(
              Icons.delete_outline,
              color: AppTheme.error.withOpacity(_isHovered ? 1 : 0.7),
              size: 20,
            ),
            tooltip: 'حذف',
          ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    return [
      if (widget.onEdit != null)
        PopupMenuItem(
          value: 'edit',
          height: 36,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: AppTheme.primaryBlue,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(
                'تعديل',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textWhite,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      if (widget.onDelete != null)
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: AppTheme.error,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(
                'حذف',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.error,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  void _handleAction(String value) {
    HapticFeedback.lightImpact();
    switch (value) {
      case 'edit':
        widget.onEdit?.call();
        break;
      case 'delete':
        widget.onDelete?.call();
        break;
    }
  }
}
