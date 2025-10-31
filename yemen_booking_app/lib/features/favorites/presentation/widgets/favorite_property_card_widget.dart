import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/favorite.dart';

class FavoritePropertyCardWidget extends StatefulWidget {
  final Favorite favorite;
  final bool isGridView;
  final Duration animationDelay;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const FavoritePropertyCardWidget({
    super.key,
    required this.favorite,
    required this.isGridView,
    required this.animationDelay,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<FavoritePropertyCardWidget> createState() => 
      _FavoritePropertyCardWidgetState();
}

class _FavoritePropertyCardWidgetState extends State<FavoritePropertyCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isHovered = false;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.isGridView
              ? _buildGridCard()
              : _buildListCard(),
        ),
      ),
    );
  }

  Widget _buildGridCard() {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -1.5 : 0.0),
        child: Stack(
          children: [
            // Card background
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowDark.withOpacity(0.06),
                    blurRadius: _isHovered ? 10 : 6,
                    offset: Offset(0, _isHovered ? 3 : 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.darkCard.withOpacity(0.5),
                          AppTheme.darkCard.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.darkBorder.withOpacity(0.06),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image section
                        _buildImageSection(height: 110),
                        
                        // Content section
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTitle(maxLines: 1, fontSize: 11),
                                const SizedBox(height: 2),
                                _buildLocation(fontSize: 9),
                                const SizedBox(height: 3),
                                _buildRating(isCompact: true),
                                const Spacer(),
                                _buildBottomInfo(isCompact: true),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Actions overlay
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTypeBadge(compact: true),
                  _buildRemoveButton(size: 26),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard() {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        transform: Matrix4.identity()
          ..translate(_isHovered ? 1.5 : 0.0, 0.0),
        child: Container(
          height: 95,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withOpacity(0.05),
                blurRadius: _isHovered ? 8 : 5,
                offset: Offset(_isHovered ? 1.5 : 0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkCard.withOpacity(0.45),
                      AppTheme.darkCard.withOpacity(0.25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.darkBorder.withOpacity(0.06),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Image section
                    _buildImageSection(width: 95),
                    
                    // Content section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTitle(maxLines: 1, fontSize: 12),
                                ),
                                _buildRemoveButton(size: 22),
                              ],
                            ),
                            const SizedBox(height: 3),
                            _buildLocation(fontSize: 10),
                            const SizedBox(height: 4),
                            _buildRating(isCompact: false),
                            const Spacer(),
                            _buildBottomInfo(isCompact: false),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection({double? width, double? height}) {
    // Get main image or first image
    String? imageUrl = widget.favorite.propertyImage;
    if ((imageUrl.isEmpty || imageUrl == 'null') && widget.favorite.images.isNotEmpty) {
      // Try to find main image first
      final mainImage = widget.favorite.images.firstWhere(
        (img) => img.isMain,
        orElse: () => widget.favorite.images.first,
      );
      imageUrl = mainImage.url;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: widget.isGridView
            ? const BorderRadius.vertical(top: Radius.circular(10))
            : const BorderRadius.horizontal(left: Radius.circular(10)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Property image
          imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null'
              ? ClipRRect(
                  borderRadius: widget.isGridView
                      ? const BorderRadius.vertical(top: Radius.circular(10))
                      : const BorderRadius.horizontal(left: Radius.circular(10)),
                  child: CachedImageWidget(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.2),
                        AppTheme.primaryPurple.withOpacity(0.15),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    size: 28,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.25),
                ],
              ),
            ),
          ),
          
          // Star rating badge
          if (!widget.isGridView && widget.favorite.starRating > 0)
            Positioned(
              bottom: 6,
              left: 6,
              child: _buildStarRatingBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle({required int maxLines, required double fontSize}) {
    return Text(
      widget.favorite.propertyName,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: AppTheme.textWhite.withOpacity(0.85),
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLocation({required double fontSize}) {
    final location = widget.favorite.propertyLocation.isNotEmpty 
        ? widget.favorite.propertyLocation 
        : '${widget.favorite.city}, ${widget.favorite.address}';

    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: fontSize + 1,
          color: AppTheme.textMuted.withOpacity(0.45),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            location,
            style: AppTextStyles.caption.copyWith(
              fontSize: fontSize,
              color: AppTheme.textMuted.withOpacity(0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRating({required bool isCompact}) {
    return Row(
      children: [
        // Stars
        ...List.generate(5, (index) {
          final isFilled = index < widget.favorite.starRating;
          return Icon(
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: isCompact ? 10 : 11,
            color: isFilled 
                ? AppTheme.warning.withOpacity(0.8)
                : AppTheme.textMuted.withOpacity(0.3),
          );
        }),
        
        const SizedBox(width: 4),
        
        // Average rating
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.warning.withOpacity(0.08),
                AppTheme.warning.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.favorite.averageRating.toStringAsFixed(1),
            style: AppTextStyles.caption.copyWith(
              fontSize: isCompact ? 9 : 10,
              color: AppTheme.warning.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(width: 3),
        
        // Reviews count
        Text(
          '(${widget.favorite.reviewsCount})',
          style: AppTextStyles.caption.copyWith(
            fontSize: isCompact ? 8 : 9,
            color: AppTheme.textMuted.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfo({required bool isCompact}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Owner name
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: isCompact ? 10 : 11,
                color: AppTheme.textMuted.withOpacity(0.4),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  widget.favorite.ownerName,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: isCompact ? 9 : 10,
                    color: AppTheme.textMuted.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        // Amenities count
        if (widget.favorite.amenities.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: isCompact ? 9 : 10,
                  color: AppTheme.success.withOpacity(0.6),
                ),
                const SizedBox(width: 2),
                Text(
                  '${widget.favorite.amenities.length}',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: isCompact ? 8 : 9,
                    color: AppTheme.textWhite.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTypeBadge({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.8),
            AppTheme.primaryPurple.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        widget.favorite.typeName,
        style: AppTextStyles.caption.copyWith(
          fontSize: compact ? 9 : 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStarRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_rounded,
            size: 11,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 2),
          Text(
            widget.favorite.starRating.toString(),
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton({required double size}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _animateRemoval();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isRemoving
                ? [
                    AppTheme.error.withOpacity(0.7),
                    AppTheme.error.withOpacity(0.5),
                  ]
                : [
                    AppTheme.darkCard.withOpacity(0.6),
                    AppTheme.darkCard.withOpacity(0.4),
                  ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isRemoving
                ? Colors.transparent
                : Colors.white.withOpacity(0.08),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isRemoving
                  ? AppTheme.error.withOpacity(0.25)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 3,
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          size: size * 0.5,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }

  Widget _buildAmenityIcon(Amenity amenity) {
    return Tooltip(
      message: amenity.name,
      child: Container(
        width: 24,
        height: 24,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkSurface.withOpacity(0.3),
              AppTheme.darkSurface.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.08),
            width: 0.5,
          ),
        ),
        child: amenity.iconUrl.isNotEmpty
            ? CachedImageWidget(
                imageUrl: amenity.iconUrl,
                fit: BoxFit.contain,
              )
            : Icon(
                Icons.check_rounded,
                size: 12,
                color: AppTheme.success.withOpacity(0.6),
              ),
      ),
    );
  }

  void _animateRemoval() {
    setState(() {
      _isRemoving = true;
    });
    
    _animationController.reverse().then((_) {
      widget.onRemove();
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'منذ $weeks ${weeks == 1 ? 'أسبوع' : 'أسابيع'}';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? 'شهر' : 'أشهر'}';
    }
  }
}