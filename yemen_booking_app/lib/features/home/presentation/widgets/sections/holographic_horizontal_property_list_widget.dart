// lib/features/home/presentation/widgets/sections/premium_horizontal_property_list.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/models/section_display_item.dart';

class HolographicHorizontalPropertyListWidget extends StatefulWidget {
  final List<dynamic> items;
  final Function(String)? onItemTap;
  final VoidCallback? onLoadMore;
  final bool isUnitView;

  const HolographicHorizontalPropertyListWidget({
    super.key,
    required this.items,
    this.onItemTap,
    this.onLoadMore,
    this.isUnitView = false,
  });

  @override
  State<HolographicHorizontalPropertyListWidget> createState() =>
      _HolographicHorizontalPropertyListWidgetState();
}

class _HolographicHorizontalPropertyListWidgetState
    extends State<HolographicHorizontalPropertyListWidget> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  bool _showScrollIndicator = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    // Hide scroll indicator when scrolling
    if (_showScrollIndicator && _scrollController.offset > 50) {
      setState(() => _showScrollIndicator = false);
    }

    // Load more logic
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && widget.onLoadMore != null) {
        setState(() => _isLoadingMore = true);
        widget.onLoadMore!();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground.withOpacity(0.95),
            AppTheme.darkBackground2.withOpacity(0.5),
          ],
        ),
      ),
      child: Column(
        children: [
          // Premium Header
          _buildPremiumHeader(),

          const SizedBox(height: 20),

          // Main Content
          Expanded(
            child: Stack(
              children: [
                // List View
                ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 8),
                  itemCount: widget.items.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == widget.items.length) {
                      return _buildLoadingIndicator();
                    }

                    final rawItem = widget.items[index];
                    final item = rawItem is SectionPropertyItemModel
                        ? SectionDisplayItem.fromProperty(rawItem)
                        : SectionDisplayItem.fromUnit(
                            rawItem as SectionUnitItemModel);

                    return Padding(
                      padding: EdgeInsets.only(
                        left: index > 0 ? 16 : 0,
                      ),
                      child: _PremiumPropertyCard(
                        item: item,
                        index: index,
                        onTap: () => _handlePropertyTap(item),
                      ),
                    );
                  },
                ),

                // Scroll Indicator
                if (_showScrollIndicator && widget.items.length > 2)
                  Positioned(
                    right: 30,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.2),
                  AppTheme.primaryPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.view_carousel_rounded,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'استكشف المجموعة',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.items.length} عقار مميز',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // View All Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'عرض الكل',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: AppTheme.primaryBlue,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryBlue.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePropertyTap(SectionDisplayItem item) {
    HapticFeedback.lightImpact();
    widget.onItemTap?.call(item.id);
  }
}

// Premium Property Card
class _PremiumPropertyCard extends StatefulWidget {
  final SectionDisplayItem item;
  final int index;
  final VoidCallback onTap;

  const _PremiumPropertyCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  State<_PremiumPropertyCard> createState() => _PremiumPropertyCardState();
}

class _PremiumPropertyCardState extends State<_PremiumPropertyCard> {
  bool _isFavorite = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.item.hasDiscount;
    final displayPrice = widget.item.discountedPrice ?? widget.item.price;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _isPressed ? 0.98 : 1.0,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.03),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.darkCard,
                        AppTheme.darkCard.withOpacity(0.98),
                      ],
                    ),
                  ),
                ),

                Column(
                  children: [
                    // Image Section
                    Expanded(
                      flex: 5,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Main Image
                          Hero(
                            tag: 'property_${widget.item.id}_${widget.index}',
                            child: widget.item.imageUrl != null &&
                                    widget.item.imageUrl!.isNotEmpty
                                ? CachedImageWidget(
                                    imageUrl: widget.item.imageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.darkBackground2,
                                          AppTheme.darkBackground3,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.home_work_rounded,
                                        size: 48,
                                        color:
                                            AppTheme.textMuted.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                          ),

                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  AppTheme.darkBackground.withOpacity(0.7),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),

                          // Top Controls
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Category Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkCard.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.home_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.item.category ?? 'عقار',
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Favorite Button
                                _buildFavoriteButton(),
                              ],
                            ),
                          ),

                          // Discount Badge
                          if (hasDiscount && widget.item.discount != null)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.error,
                                      AppTheme.error.withOpacity(0.9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.error.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_offer_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.item.discount}% خصم',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Content Section
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.darkBorder.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title Section
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item.name,
                                    style: AppTextStyles.heading3.copyWith(
                                      color: AppTheme.textWhite,
                                      fontWeight: FontWeight.w600,
                                      height: 1.15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 6),

                                  // Location
                                  if (widget.item.location != null ||
                                      widget.item.city != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.darkBackground
                                            .withOpacity(0.45),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 13,
                                            color: AppTheme.primaryCyan,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              widget.item.location ??
                                                  widget.item.city ??
                                                  '',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                color: AppTheme.textLight,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Bottom Section
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (hasDiscount)
                                        Text(
                                          '${widget.item.price.toStringAsFixed(0)} ريال',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppTheme.textMuted,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor: AppTheme.textMuted,
                                          ),
                                        ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            displayPrice.toStringAsFixed(0),
                                            style:
                                                AppTextStyles.heading2.copyWith(
                                              color: hasDiscount
                                                  ? AppTheme.error
                                                  : AppTheme.primaryBlue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 2),
                                            child: Text(
                                              'ريال',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Rating or CTA
                                widget.item.averageRating != null
                                    ? _buildRatingBadge()
                                    : _buildCTAButton(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Premium Indicator Line
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue,
                          AppTheme.primaryPurple,
                          AppTheme.primaryCyan,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isFavorite
              ? AppTheme.error.withOpacity(0.9)
              : AppTheme.darkCard.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isFavorite ? AppTheme.error : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warning.withOpacity(0.15),
            AppTheme.warning.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_rounded,
            size: 16,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 6),
          Text(
            widget.item.averageRating!.toStringAsFixed(1),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${widget.item.reviewsCount ?? 0})',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.warning.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'عرض',
            style: AppTextStyles.buttonSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 14,
          ),
        ],
      ),
    );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    HapticFeedback.lightImpact();
  }
}
