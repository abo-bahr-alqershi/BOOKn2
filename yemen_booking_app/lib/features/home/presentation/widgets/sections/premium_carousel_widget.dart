// lib/features/home/presentation/widgets/sections/premium_carousel/tesla_carousel_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';

class PremiumCarouselWidget extends StatefulWidget {
  final List<dynamic> items;
  final Function(String)? onItemTap;
  final bool isUnitView;

  const PremiumCarouselWidget({
    super.key,
    required this.items,
    this.onItemTap,
    this.isUnitView = false,
  });

  @override
  State<PremiumCarouselWidget> createState() => _PremiumCarouselWidgetState();
}

class _PremiumCarouselWidgetState extends State<PremiumCarouselWidget> {
  late PageController _pageController;
  int _currentIndex = 0;
  double _pageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88)
      ..addListener(() {
        setState(() {
          _pageValue = _pageController.page ?? 0.0;
        });
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 460,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground2.withOpacity(0.3),
            AppTheme.darkBackground,
          ],
        ),
      ),
      child: Column(
        children: [
          // Tesla-style Header
          _buildTeslaHeader(),

          const SizedBox(height: 24),

          // Carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                HapticFeedback.selectionClick();
              },
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                return _buildTeslaCard(widget.items[index], index);
              },
            ),
          ),

          const SizedBox(height: 20),

          // Modern Indicators
          _buildModernIndicators(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTeslaHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREMIUM COLLECTION',
                style: AppTextStyles.overline.copyWith(
                  color: AppTheme.primaryBlue.withOpacity(0.8),
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'عقارات حصرية',
                style: AppTextStyles.heading1.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
            ],
          ),

          // Right Section - Modern Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonGreen,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'متاح الآن',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeslaCard(dynamic item, int index) {
    if (item is! SectionPropertyItemModel) return const SizedBox.shrink();

    final property = item;
    final difference = (_pageValue - index).abs();
    final scale = 1.0 - (difference * 0.1).clamp(0.0, 0.15);
    final opacity = 1.0 - (difference * 0.3).clamp(0.0, 0.7);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onItemTap?.call(property.id);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowDark.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  if (property.imageUrl != null &&
                      property.imageUrl!.isNotEmpty)
                    Hero(
                      tag: 'tesla_property_$index',
                      child: CachedImageWidget(
                        imageUrl: property.imageUrl!,
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
                            AppTheme.darkCard,
                            AppTheme.darkBackground2,
                          ],
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
                          AppTheme.darkBackground.withOpacity(0.4),
                          AppTheme.darkBackground.withOpacity(0.9),
                        ],
                        stops: const [0.3, 0.6, 1.0],
                      ),
                    ),
                  ),

                  // Content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.darkCard.withOpacity(0.4),
                                AppTheme.darkCard.withOpacity(0.8),
                              ],
                            ),
                            border: Border(
                              top: BorderSide(
                                color: AppTheme.primaryBlue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Premium Label
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue.withOpacity(0.3),
                                      AppTheme.primaryPurple.withOpacity(0.3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        AppTheme.primaryBlue.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'EXCLUSIVE',
                                  style: AppTextStyles.overline.copyWith(
                                    color: AppTheme.primaryBlue,
                                    fontSize: 9,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Property Name
                              Text(
                                property.name,
                                style: AppTextStyles.heading1.copyWith(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 12),

                              // Location with modern icon
                              if (property.location != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkBackground
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.explore_rounded,
                                        size: 16,
                                        color: AppTheme.primaryCyan,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          property.location!,
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: AppTheme.textLight,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Features Row
                              Row(
                                children: [
                                  if (property.bedrooms != null)
                                    _buildModernFeature(
                                      Icons.king_bed_rounded,
                                      '${property.bedrooms}',
                                      'غرف',
                                    ),
                                  if (property.bathrooms != null)
                                    _buildModernFeature(
                                      Icons.shower_rounded,
                                      '${property.bathrooms}',
                                      'حمام',
                                    ),
                                  if (property.area != null)
                                    _buildModernFeature(
                                      Icons.square_foot_rounded,
                                      '${property.area}',
                                      'م²',
                                    ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Price and CTA
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'يبدأ من',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            property.price
                                                    ?.toStringAsFixed(0) ??
                                                property.minPrice
                                                    .toStringAsFixed(0),
                                            style:
                                                AppTextStyles.heading1.copyWith(
                                              color: AppTheme.primaryBlue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Text(
                                              'ريال',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppTheme.primaryBlue
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // CTA Button
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryBlue,
                                          AppTheme.primaryPurple,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue
                                              .withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'استكشف',
                                          style: AppTextStyles.buttonMedium
                                              .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top Badge
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.9),
                            AppTheme.primaryPurple.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            Text(
                              'VIP',
                              style: AppTextStyles.overline.copyWith(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildModernFeature(IconData icon, String value, String label) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryBlue.withOpacity(0.8),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
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

  Widget _buildModernIndicators() {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(
          widget.items.length,
          (index) {
            final isActive = index == _currentIndex;
            final isPassed = index < _currentIndex;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryBlue
                      : isPassed
                          ? AppTheme.primaryBlue.withOpacity(0.3)
                          : AppTheme.darkBorder.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
