// lib/features/home/presentation/widgets/sections/premium_flash_deals.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/models/section_display_item.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/section_empty_widget.dart';

const double _kPremiumListHeight = 260;
const double _kPremiumSectionExtras = 72 + 20 + 20 + 20;

class QuantumFlashDealsSectionWidget extends StatelessWidget {
  final List<dynamic> items;
  final Function(String)? onItemTap;
  final bool isUnitView;

  const QuantumFlashDealsSectionWidget({
    super.key,
    required this.items,
    this.onItemTap,
    this.isUnitView = false,
  });

  List<SectionDisplayItem> _convertItems() {
    final List<SectionDisplayItem> convertedItems = [];
    for (var item in items) {
      try {
        if (item is SectionPropertyItemModel) {
          convertedItems.add(SectionDisplayItem.fromProperty(item));
        } else if (item is SectionUnitItemModel) {
          convertedItems.add(SectionDisplayItem.fromUnit(item));
        }
      } catch (_) {}
    }
    return convertedItems;
  }

  @override
  Widget build(BuildContext context) {
    final deals = _convertItems();

    if (deals.isEmpty) {
      return const SectionEmptyWidget(
        message: 'لا توجد عروض متاحة',
        icon: Icons.local_offer_outlined,
      );
    }

    const double sectionHeight = _kPremiumListHeight + _kPremiumSectionExtras;

    return Container(
      height: sectionHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground2.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        children: [
          // Premium Header
          _buildPremiumHeader(deals.length),

          const SizedBox(height: 20),

          // Deals List
          SizedBox(
            height: _kPremiumListHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: deals.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 16,
                  ),
                  child: _PremiumDealCard(
                    deal: deals[index],
                    index: index,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onItemTap?.call(deals[index].id);
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Stack(
        children: [
          // Background with gradient
          Container(
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.error.withOpacity(0.15),
                  AppTheme.error.withOpacity(0.08),
                  AppTheme.primaryPurple.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),

          // Glass overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Icon with pulse effect
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.error.withOpacity(0.3),
                                AppTheme.error.withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Icon(
                          Icons.bolt_rounded,
                          color: AppTheme.error,
                          size: 24,
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'عروض حصرية',
                                  style: AppTextStyles.heading2.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.error,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'HOT',
                                  style: AppTextStyles.overline.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'خصومات تصل إلى 50%',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Counter badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.error,
                            AppTheme.error.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.error.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$count',
                            style: AppTextStyles.heading3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'عرض',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumDealCard extends StatelessWidget {
  final SectionDisplayItem deal;
  final int index;
  final VoidCallback onTap;

  const _PremiumDealCard({
    required this.deal,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discount = deal.discount ?? 0;
    final discountedPrice = deal.discountedPrice ?? deal.price;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        height: _kPremiumListHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppTheme.error.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background container
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
                          if (deal.imageUrl != null &&
                              deal.imageUrl!.isNotEmpty)
                            Hero(
                              tag: 'deal_image_$index',
                              child: CachedImageWidget(
                                imageUrl: deal.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.darkBackground2,
                                    AppTheme.darkBackground3,
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.home_rounded,
                                size: 40,
                                color: AppTheme.textMuted.withOpacity(0.3),
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
                                  AppTheme.darkBackground.withOpacity(0.8),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),

                          // Discount Badge with animation hint
                          if (discount > 0)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
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
                                      color: AppTheme.error.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.trending_down_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$discount%',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Timer badge
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
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
                                    Icons.schedule_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'محدود',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
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
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.error.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Name
                            Text(
                              deal.name,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Location
                            if (deal.location != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.near_me_rounded,
                                    size: 12,
                                    color: AppTheme.primaryCyan,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      deal.location!,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.textLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                            // Price Section
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (discount > 0)
                                        Text(
                                          '${deal.price.toStringAsFixed(0)} ريال',
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
                                            discountedPrice.toStringAsFixed(0),
                                            style:
                                                AppTextStyles.heading2.copyWith(
                                              color: AppTheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 2,
                                            ),
                                            child: Text(
                                              'ريال',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                color: AppTheme.error
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Action Button
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
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
                                        color: AppTheme.error.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
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
      ),
    );
  }
}
