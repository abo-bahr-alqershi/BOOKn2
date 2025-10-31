import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../domain/entities/property_detail.dart';

class PropertyHeaderWidget extends StatefulWidget {
  final PropertyDetail property;
  final bool isFavorite;
  final bool isFavoritePending;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;

  const PropertyHeaderWidget({
    super.key,
    required this.property,
    required this.isFavorite,
    required this.isFavoritePending,
    required this.onFavoriteToggle,
    required this.onShare,
  });

  @override
  State<PropertyHeaderWidget> createState() => _PropertyHeaderWidgetState();
}

class _PropertyHeaderWidgetState extends State<PropertyHeaderWidget>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _shimmerController;
  late AnimationController _statsController;
  late AnimationController _glowController;
  
  late Animation<double> _heartAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }
  
  void _initializeAnimations() {
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_shimmerController);
    
    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutBack,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _statsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    _shimmerController.dispose();
    _statsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.9),
            AppTheme.darkCard.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              Positioned.fill(child: _buildAnimatedBackground()),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFuturisticHeader(),
                    const SizedBox(height: 12),
                    _buildFuturisticLocation(),
                    const SizedBox(height: 12),
                    _buildFuturisticStats(),
                    if (widget.property.averageRating > 0) ...[
                      const SizedBox(height: 12),
                      _buildFuturisticRating(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPatternPainter(
            shimmerPosition: _shimmerAnimation.value,
            glowIntensity: _glowAnimation.value,
          ),
        );
      },
    );
  }
  
  Widget _buildFuturisticHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => 
                    AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  widget.property.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFuturisticTag(
                    label: widget.property.typeName,
                    icon: Icons.home_work,
                    gradient: AppTheme.primaryGradient,
                  ),
                  const SizedBox(width: 6),
                  if (widget.property.starRating > 0)
                    _buildStarRating(),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.share_outlined,
              onPressed: () {
                widget.onShare();
                HapticFeedback.lightImpact();
              },
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPurple,
                  AppTheme.primaryViolet,
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildFavoriteButton(),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFuturisticTag({
    required String label,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStarRating() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warning.withOpacity(0.2),
            AppTheme.warning.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.property.starRating,
          (index) => Padding(
            padding: EdgeInsets.only(right: 1),
            child: Icon(
              Icons.star,
              size: 10,
              color: AppTheme.warning,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Gradient gradient,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradient.colors[0].withOpacity(0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
  
  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: () {
        if (widget.isFavoritePending) {
          HapticFeedback.selectionClick();
          return;
        }
        widget.onFavoriteToggle();
        if (!widget.isFavorite) {
          _heartController.forward().then((_) {
            _heartController.reverse();
          });
        }
        HapticFeedback.mediumImpact();
      },
      child: AnimatedBuilder(
        animation: _heartAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isFavorite ? _heartAnimation.value : 1.0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: widget.isFavorite
                    ? LinearGradient(
                        colors: [
                          AppTheme.error,
                          AppTheme.error.withOpacity(0.7),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppTheme.darkCard.withOpacity(0.7),
                          AppTheme.darkCard.withOpacity(0.5),
                        ],
                      ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isFavorite
                      ? Colors.transparent
                      : AppTheme.textMuted.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: widget.isFavorite ? Colors.white : AppTheme.textMuted,
                size: 16,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFuturisticLocation() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryCyan.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الموقع',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.property.address}, ${widget.property.city}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticStats() {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statsAnimation.value,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility_outlined,
                  value: widget.property.viewCount.toString(),
                  label: 'مشاهدة',
                  color: AppTheme.primaryBlue,
                  delay: 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.bookmark_outline,
                  value: widget.property.bookingCount.toString(),
                  label: 'حجز',
                  color: AppTheme.primaryPurple,
                  delay: 50,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.home_outlined,
                  value: widget.property.units.length.toString(),
                  label: 'وحدة',
                  color: AppTheme.primaryCyan,
                  delay: 100,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required int delay,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ).createShader(bounds),
                child: Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticRating() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warning.withOpacity(0.15),
            AppTheme.warning.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warning,
                  AppTheme.warning.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 18,
                  ),
                  Text(
                    widget.property.averageRating.toStringAsFixed(1),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingWidget(
                  rating: widget.property.averageRating,
                  starSize: 16,
                  showLabel: false,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.property.reviewsCount} تقييم',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getRatingColor(widget.property.averageRating).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getRatingLabel(widget.property.averageRating),
              style: AppTextStyles.caption.copyWith(
                color: _getRatingColor(widget.property.averageRating),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return AppTheme.success;
    if (rating >= 3.5) return AppTheme.warning;
    if (rating >= 2.5) return Colors.orange;
    return AppTheme.error;
  }
  
  String _getRatingLabel(double rating) {
    if (rating >= 4.5) return 'ممتاز';
    if (rating >= 3.5) return 'جيد جداً';
    if (rating >= 2.5) return 'جيد';
    return 'مقبول';
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final double shimmerPosition;
  final double glowIntensity;
  
  _BackgroundPatternPainter({
    required this.shimmerPosition,
    required this.glowIntensity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3
      ..color = AppTheme.primaryBlue.withOpacity(0.03);
    
    const gridSize = 20.0;
    
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    final shimmerRect = Rect.fromLTWH(
      shimmerPosition * size.width - 80,
      0,
      160,
      size.height,
    );
    
    final shimmerGradient = LinearGradient(
      colors: [
        Colors.transparent,
        AppTheme.primaryBlue.withOpacity(0.05 * glowIntensity),
        Colors.transparent,
      ],
    );
    
    final shimmerPaint = Paint()
      ..shader = shimmerGradient.createShader(shimmerRect)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(shimmerRect, shimmerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}