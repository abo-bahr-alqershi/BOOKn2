// lib/features/search/presentation/widgets/ultra_futuristic_search_result_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/image_utils.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/search_result.dart';
import 'package:yemen_booking_app/injection_container.dart';
import 'package:yemen_booking_app/services/local_storage_service.dart';
import 'package:yemen_booking_app/core/constants/storage_constants.dart';
import '../../../favorites/domain/repositories/favorites_repository.dart';

class FuturisticSearchResultCard extends StatefulWidget {
  final SearchResult result;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showDistance;
  final Duration animationDelay;

  const FuturisticSearchResultCard({
    super.key,
    required this.result,
    this.onTap,
    this.onFavoriteToggle,
    this.showDistance = true,
    this.animationDelay = Duration.zero,
  });

  @override
  State<FuturisticSearchResultCard> createState() => 
      _FuturisticSearchResultCardState();
}

class _FuturisticSearchResultCardState 
    extends State<FuturisticSearchResultCard>
    with TickerProviderStateMixin {
  
  late AnimationController _entranceController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _floatingController;
  late AnimationController _particleController;
  late AnimationController _heartBeatController;
  
  late Animation<double> _entranceAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _heartBeatAnimation;
  
  bool _isPressed = false;
  bool _isFavorite = false;
  bool _isHovering = false;
  
  final List<_FloatingOrb> _orbs = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateOrbs();
    _startEntrance();
  }

  void _initializeAnimations() {
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _heartBeatController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutExpo,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: -3,
      end: 3,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    _heartBeatAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(
      parent: _heartBeatController,
      curve: Curves.elasticOut,
    ));
  }

  void _generateOrbs() {
    for (int i = 0; i < 3; i++) {
      _orbs.add(_FloatingOrb());
    }
  }
  
  void _startEntrance() {
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _floatingController.dispose();
    _particleController.dispose();
    _heartBeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _entranceAnimation,
        _scaleAnimation,
        _glowAnimation,
        _floatingAnimation,
        _particleController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Transform.scale(
            scale: _entranceAnimation.value * (_isPressed ? _scaleAnimation.value : 1.0),
            child: Opacity(
              opacity: _entranceAnimation.value,
              child: GestureDetector(
                onTapDown: (_) => _onTapDown(),
                onTapUp: (_) => _onTapUp(),
                onTapCancel: _onTapCancel,
                onTap: _onTap,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovering = true),
                  onExit: (_) => setState(() => _isHovering = false),
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    final imageWidth = 140.0;
    
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Stack(
        children: [
          // Background with glassmorphism
          _buildGlassBackground(),
          
          // Floating particles
          if (_isHovering || widget.result.isFeatured)
            CustomPaint(
              painter: _ParticlePainter(
                orbs: _orbs,
                animationValue: _particleController.value,
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
              size: Size.infinite,
            ),
          
          // Main content
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                // Fixed width image section
                _buildImageSection(width: imageWidth),
                
                // Flexible content section
                Expanded(
                  child: _buildContentSection(),
                ),
              ],
            ),
          ),
          
          // Hover/Press overlay effect
          if (_isHovering || _isPressed)
            Positioned.fill(
              child: _buildInteractionOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassBackground() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _isPressed ? 25 : 20,
            sigmaY: _isPressed ? 25 : 20,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkCard.withOpacity(0.85),
                  AppTheme.darkCard.withOpacity(0.75),
                  AppTheme.darkSurface.withOpacity(0.70),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isPressed
                    ? AppTheme.primaryBlue.withOpacity(0.4)
                    : _isHovering
                        ? AppTheme.primaryPurple.withOpacity(0.3)
                        : Colors.white.withOpacity(0.08),
                width: _isPressed ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isPressed
                      ? AppTheme.primaryBlue.withOpacity(0.15)
                      : AppTheme.shadowDark.withOpacity(0.2),
                  blurRadius: _isPressed ? 25 : 20,
                  spreadRadius: _isPressed ? 2 : 0,
                  offset: const Offset(0, 8),
                ),
                if (widget.result.isFeatured)
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(
                      0.1 * _glowAnimation.value,
                    ),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection({required double width}) {
    return Container(
      width: width,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image with clipping
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Main image
                CachedImageWidget(
                  imageUrl: widget.result.mainImageUrl ?? '',
                  fit: BoxFit.cover,
                ),
                
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        AppTheme.darkBackground.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                
                // Featured shimmer effect
                if (widget.result.isFeatured)
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.transparent,
                              AppTheme.primaryBlue.withOpacity(
                                0.05 * _glowAnimation.value,
                              ),
                              AppTheme.primaryPurple.withOpacity(
                                0.05 * _glowAnimation.value,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          // Favorite button
          Positioned(
            top: 12,
            left: 12,
            child: _buildFavoriteButton(),
          ),
          
          // Discount badge
          if (widget.result.minPrice != widget.result.discountedPrice)
            Positioned(
              bottom: 12,
              left: 12,
              child: _buildDiscountBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPropertyTypeBadge(),
                  const SizedBox(width: 8),
                  if (widget.result.isFeatured)
                    _buildSpecialBadge('مميز', AppTheme.primaryViolet),
                  if (widget.result.isRecommended) ...[
                    const SizedBox(width: 6),
                    _buildSpecialBadge('موصى به', AppTheme.success),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.result.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          
          // Middle section
          Column(
            children: [
              _buildLocationRow(),
              const SizedBox(height: 8),
              _buildRatingRow(),
            ],
          ),
          
          // Bottom section with price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceSection(),
              _buildViewButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        widget.result.propertyType,
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.primaryBlue.withOpacity(0.9),
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildSpecialBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on_rounded,
            size: 14,
            color: AppTheme.info.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${widget.result.city}',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textLight.withOpacity(0.8),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.showDistance && widget.result.distanceKm != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.near_me_rounded,
                  size: 10,
                  color: AppTheme.info.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.result.distanceKm!.toStringAsFixed(1)} كم',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.info.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        // Rating stars
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.warning.withOpacity(0.15),
                AppTheme.warning.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: AppTheme.warning,
                shadows: [
                  Shadow(
                    color: AppTheme.warning.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Text(
                widget.result.averageRating.toStringAsFixed(1),
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${widget.result.reviewsCount})',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Availability status
        _buildAvailabilityStatus(),
      ],
    );
  }

  Widget _buildAvailabilityStatus() {
    final isAvailable = widget.result.isAvailable;
    final color = isAvailable ? AppTheme.success : AppTheme.error;
    final label = isAvailable ? 'متاح' : 'محجوز';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    final hasDiscount = widget.result.minPrice != widget.result.discountedPrice;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDiscount)
          Text(
            '${widget.result.minPrice.toStringAsFixed(0)} ${widget.result.currency}',
            style: AppTextStyles.caption.copyWith(
              decoration: TextDecoration.lineThrough,
              color: AppTheme.textMuted.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => 
                  AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                widget.result.discountedPrice.toStringAsFixed(0),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.result.currency,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '/ الليلة',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewButton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 16,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return AnimatedBuilder(
      animation: _heartBeatAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggleFavorite,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowDark.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Transform.scale(
              scale: _heartBeatAnimation.value,
              child: Icon(
                _isFavorite 
                    ? Icons.favorite_rounded 
                    : Icons.favorite_outline_rounded,
                color: _isFavorite ? AppTheme.error : AppTheme.textDark,
                size: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscountBadge() {
    final discountPercent = ((1 - widget.result.discountedPrice / 
                            widget.result.minPrice) * 100).toStringAsFixed(0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.error, AppTheme.warning],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.error.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_offer_rounded,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$discountPercent%',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionOverlay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.02),
                AppTheme.primaryPurple.withOpacity(0.01),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTap() {
    HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _heartBeatController.forward().then((_) {
      _heartBeatController.reverse();
    });
    HapticFeedback.lightImpact();
    if (widget.onFavoriteToggle != null) {
      widget.onFavoriteToggle!.call();
    } else {
      // Backend fallback when page doesn't pass a handler
      _toggleFavoriteBackend();
    }
  }

  Future<void> _toggleFavoriteBackend() async {
    try {
      final uid = (sl<LocalStorageService>().getData(StorageConstants.userId) ?? '').toString();
      if (uid.isEmpty) return;
      final repo = sl<FavoritesRepository>();
      final status = await repo.checkFavoriteStatus(propertyId: widget.result.id, userId: uid);
      await status.fold(
        (_) async {
          await repo.addToFavorites(propertyId: widget.result.id, userId: uid);
        },
        (isFav) async {
          if (isFav) {
            await repo.removeFromFavorites(propertyId: widget.result.id, userId: uid);
          } else {
            await repo.addToFavorites(propertyId: widget.result.id, userId: uid);
          }
        },
      );
    } catch (_) {}
  }
}

// Floating orb model
class _FloatingOrb {
  late double x;
  late double y;
  late double radius;
  late double speed;
  
  _FloatingOrb() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    radius = math.Random().nextDouble() * 2 + 1;
    speed = math.Random().nextDouble() * 0.5 + 0.5;
  }
  
  void update(double delta) {
    y -= speed * delta;
    if (y < -0.1) {
      y = 1.1;
      x = math.Random().nextDouble();
    }
  }
}

// Particle painter
class _ParticlePainter extends CustomPainter {
  final List<_FloatingOrb> orbs;
  final double animationValue;
  final Color color;
  
  _ParticlePainter({
    required this.orbs,
    required this.animationValue,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (var orb in orbs) {
      orb.update(0.016);
      
      paint.shader = RadialGradient(
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(orb.x * size.width, orb.y * size.height),
          radius: orb.radius * 3,
        ),
      );
      
      canvas.drawCircle(
        Offset(orb.x * size.width, orb.y * size.height),
        orb.radius,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}