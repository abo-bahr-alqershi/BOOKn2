// lib/features/home/presentation/widgets/sections/premium_property_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';

class VerticalPropertyGridWidget extends StatelessWidget {
  final List<dynamic> items;
  final Function(String)? onItemTap;
  final bool isUnitView;

  const VerticalPropertyGridWidget({
    super.key,
    required this.items,
    this.onItemTap,
    this.isUnitView = false,
  });

  // Safe getters
  String _getItemId(dynamic item) {
    if (item is SectionPropertyItemModel) return item.id;
    if (item is SectionUnitItemModel) return item.id;
    return '';
  }

  String _getItemName(dynamic item) {
    if (item is SectionPropertyItemModel) return item.name;
    if (item is SectionUnitItemModel) return item.name;
    return '';
  }

  String? _getItemImage(dynamic item) {
    if (item is SectionPropertyItemModel) return item.imageUrl;
    if (item is SectionUnitItemModel) return item.imageUrl;
    return null;
  }

  String? _getItemLocation(dynamic item) {
    if (item is SectionPropertyItemModel) return item.location;
    return null;
  }

  double _getItemPrice(dynamic item) {
    if (item is SectionPropertyItemModel) return item.price ?? item.minPrice;
    if (item is SectionUnitItemModel) return item.price ?? item.minPrice;
    return 0.0;
  }

  double? _getItemRating(dynamic item) {
    if (item is SectionPropertyItemModel) return item.rating;
    return null;
  }

  int? _getItemDiscount(dynamic item) {
    if (item is SectionPropertyItemModel) return item.discount;
    if (item is SectionUnitItemModel) return item.discount;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground2.withOpacity(0.5),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Header with Glass Effect
          _buildPremiumHeader(),

          const SizedBox(height: 28),

          // Premium Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.73,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length > 20 ? 20 : items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _PremiumPropertyCard(
                  name: _getItemName(item),
                  imageUrl: _getItemImage(item),
                  location: _getItemLocation(item),
                  price: _getItemPrice(item),
                  rating: _getItemRating(item),
                  discount: _getItemDiscount(item),
                  index: index,
                  onTap: () {
                    final id = _getItemId(item);
                    if (id.isNotEmpty) {
                      HapticFeedback.lightImpact();
                      onItemTap?.call(id);
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      height: 88,
      child: Stack(
        children: [
          // Glass background
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkCard.withOpacity(0.6),
                      AppTheme.darkCard.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Premium Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.2),
                        AppTheme.primaryPurple.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.dashboard_customize_rounded,
                        color: AppTheme.primaryBlue,
                        size: 26,
                      ),
                      // Small badge
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonGreen,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'العقارات المميزة',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue.withOpacity(0.2),
                                  AppTheme.primaryPurple.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${items.length} عقار',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• محدث اليوم',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppTheme.primaryBlue,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPropertyCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? location;
  final double price;
  final double? rating;
  final int? discount;
  final int index;
  final VoidCallback onTap;

  const _PremiumPropertyCard({
    required this.name,
    required this.imageUrl,
    required this.location,
    required this.price,
    required this.rating,
    required this.discount,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowDark.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.03),
              blurRadius: 30,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Container
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkCard,
                      AppTheme.darkCard.withOpacity(0.95),
                    ],
                  ),
                ),
              ),

              Column(
                children: [
                  // Image Section with Overlay
                  Expanded(
                    flex: 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image
                        if (imageUrl != null && imageUrl!.isNotEmpty)
                          Hero(
                            tag: 'property_image_$index',
                            child: CachedImageWidget(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.darkBackground2,
                                  AppTheme.darkBackground3.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.home_work_rounded,
                                size: 40,
                                color: AppTheme.textMuted.withOpacity(0.3),
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
                                AppTheme.darkBackground.withOpacity(0.7),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                        ),

                        // Top Badges
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Discount Badge
                              if (discount != null && discount! > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.error,
                                        AppTheme.error.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.error.withOpacity(0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$discount%',
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Favorite Button
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.darkCard.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.favorite_border_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Section with Glass Effect
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.darkCard.withOpacity(0.95),
                            AppTheme.darkCard,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Name
                          Text(
                            name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Location Row
                          if (location != null && location!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.darkBackground.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 12,
                                      color: AppTheme.primaryCyan,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        location!,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.textLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const Spacer(),

                          // Bottom Row - Price and Rating
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'السعر ',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: price.toStringAsFixed(0),
                                        style: AppTextStyles.heading3.copyWith(
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' ريال',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (discount != null && discount! > 0)
                                        TextSpan(
                                          text: '  •  خصم ${discount!}%',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppTheme.error,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (rating != null && rating! > 0) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.warning.withOpacity(0.18),
                                        AppTheme.warning.withOpacity(0.12),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.warning.withOpacity(0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: AppTheme.warning,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        rating!.toStringAsFixed(1),
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.warning,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
