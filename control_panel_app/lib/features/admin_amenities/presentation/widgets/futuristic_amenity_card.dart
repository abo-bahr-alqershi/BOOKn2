import 'package:bookn_cp_app/features/admin_amenities/presentation/utils/amenity_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amenity_identity_card_tooltip.dart';
import '../../domain/entities/amenity.dart';

class FuturisticAmenityCard extends StatefulWidget {
  final Amenity amenity;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  const FuturisticAmenityCard({
    super.key,
    required this.amenity,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
  });

  @override
  State<FuturisticAmenityCard> createState() => _FuturisticAmenityCardState();
}

class _FuturisticAmenityCardState extends State<FuturisticAmenityCard>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _hoverController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  late Animation<double> _hoverAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  bool _isHovered = false;
  bool _isPressed = false;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        key: _cardKey,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverAnimation,
            _shimmerAnimation,
            _pulseAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? 0.98 : _hoverAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isHovered
                        ? [
                            AppTheme.primaryPurple.withOpacity(0.15),
                            AppTheme.primaryBlue.withOpacity(0.08),
                            const Color(0xFF1A0E2E).withOpacity(0.1),
                          ]
                        : [
                            AppTheme.darkCard.withOpacity(0.7),
                            AppTheme.darkCard.withOpacity(0.5),
                            AppTheme.darkCard.withOpacity(0.4),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16), // زوايا حادة هادئة
                  border: Border.all(
                    color: _isHovered
                        ? AppTheme.primaryPurple.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? AppTheme.primaryPurple.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: _isHovered ? 25 : 15,
                      offset: const Offset(0, 8),
                    ),
                    if (_isHovered)
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: -5,
                        offset: const Offset(0, -5),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Stack(
                      children: [
                        // Background Pattern
                        if (_isHovered) _buildBackgroundPattern(),

                        // Main Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Section
                              _buildHeader(),

                              const SizedBox(height: 16),

                              // Description
                              _buildDescription(),

                              const Spacer(),

                              // Stats Grid
                              _buildStatsGrid(),

                              const SizedBox(height: 12),

                              // Footer with Actions
                              _buildFooter(),
                            ],
                          ),
                        ),

                        // Shimmer Effect
                        if (_isHovered) _buildShimmerOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _showAmenityTooltip();
    widget.onTap?.call();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    _showAmenityTooltip();
    widget.onLongPress?.call();
  }

  void _showAmenityTooltip() {
    AmenityIdentityCardTooltip.show(
      context: context,
      targetKey: _cardKey,
      amenityId: widget.amenity.id,
      name: widget.amenity.name,
      description: widget.amenity.description,
      icon: widget.amenity.icon,
      isAvailable: widget.amenity.isActive ?? true,
      extraCost: widget.amenity.averageExtraCost,
      currency: null,
      propertiesCount: widget.amenity.propertiesCount,
      category: null,
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _PatternPainter(
          animation: _shimmerAnimation.value,
          color: AppTheme.primaryPurple.withOpacity(0.03),
        ),
      ),
    );
  }

  Widget _buildShimmerOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  AppTheme.primaryPurple.withOpacity(0.05),
                  Colors.transparent,
                ],
                stops: [
                  _shimmerAnimation.value - 0.3,
                  _shimmerAnimation.value,
                  _shimmerAnimation.value + 0.3,
                ],
              ).createShader(rect);
            },
            blendMode: BlendMode.srcOver,
            child: Container(color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Icon Container - Premium Design
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale:
                  widget.amenity.isActive == true ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryPurple.withOpacity(0.2),
                      AppTheme.primaryBlue.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14), // زوايا حادة هادئة
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _getAmenityIcon(widget.amenity.icon),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 12),

        // Title and ID
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.amenity.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '#${widget.amenity.id.substring(0, 8).toUpperCase()}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryPurple,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status Badge
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isActive = widget.amenity.isActive == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [
                  AppTheme.success.withOpacity(0.2),
                  AppTheme.neonGreen.withOpacity(0.1),
                ]
              : [
                  AppTheme.textMuted.withOpacity(0.2),
                  AppTheme.textMuted.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppTheme.success.withOpacity(0.5)
              : AppTheme.textMuted.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.success : AppTheme.textMuted,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.success.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'نشط' : 'معطل',
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppTheme.success : AppTheme.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        widget.amenity.description,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.textMuted,
          height: 1.4,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.business_rounded,
            label: 'العقارات',
            value: '${widget.amenity.propertiesCount ?? 0}',
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            icon: Icons.attach_money_rounded,
            label: 'التكلفة',
            value: widget.amenity.averageExtraCost != null &&
                    widget.amenity.averageExtraCost! > 0
                ? '\$${widget.amenity.averageExtraCost!.toStringAsFixed(0)}'
                : 'مجاني',
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Created Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تاريخ الإنشاء',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
              Text(
                _formatDate(widget.amenity.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Action Buttons
        if (_isHovered && (widget.onEdit != null || widget.onDelete != null))
          Row(
            children: [
              if (widget.onEdit != null)
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  color: AppTheme.primaryPurple,
                  onTap: widget.onEdit!,
                ),
              const SizedBox(width: 6),
              if (widget.onDelete != null)
                _buildActionButton(
                  icon: Icons.delete_rounded,
                  color: AppTheme.error,
                  onTap: widget.onDelete!,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 16,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getAmenityIcon(String iconName) {
    return AmenityIcons.getIconByName(iconName)?.icon ?? Icons.star_rounded;
  }
}

// Custom Pattern Painter
class _PatternPainter extends CustomPainter {
  final double animation;
  final Color color;

  _PatternPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw hexagon pattern
    const spacing = 30.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        final offset = (y / spacing).floor() % 2 == 0 ? 0.0 : spacing / 2;
        _drawHexagon(
          canvas,
          Offset(x + offset + animation * spacing, y),
          10,
          paint,
        );
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
