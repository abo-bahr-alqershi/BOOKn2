// lib/features/home/presentation/widgets/sections/city_cards_grid/city_card.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';

class CityCardClassC extends StatelessWidget {
  final SectionPropertyItemModel city;
  final int index;
  final bool isHovered;
  final double shimmerAnimation;
  final VoidCallback? onTap;

  const CityCardClassC({
    super.key,
    required this.city,
    required this.index,
    required this.isHovered,
    required this.shimmerAnimation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark;

    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Hero(
            tag: 'city_${city.id}_$index',
            child: CachedImageWidget(
              imageUrl: city.imageUrl ?? '',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Glass morphism layer
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.02),
                        Colors.white.withOpacity(0.08),
                      ]
                    : [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.30),
                      ],
              ),
              border: Border.all(
                width: 1,
                color: isDark
                    ? Colors.white.withOpacity(isHovered ? 0.15 : 0.08)
                    : Colors.white.withOpacity(isHovered ? 0.5 : 0.3),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // Shimmer effect (light mode only)
        if (!isDark)
          Positioned.fill(
            child: CustomPaint(
              painter: _ShimmerPainter(shimmerValue: shimmerAnimation),
            ),
          ),

        // Hover glow effect
        if (isHovered)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppTheme.primaryCyan.withOpacity(isDark ? 0.15 : 0.10),
                    AppTheme.primaryBlue.withOpacity(isDark ? 0.10 : 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

        // Content
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge indicator
                _buildCityBadge(),

                const Spacer(),

                // City info
                _buildCityInfo(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryCyan.withOpacity(0.25),
            AppTheme.primaryBlue.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryCyan.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryCyan, AppTheme.primaryBlue],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryCyan.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'وجهة',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withOpacity(0.6),
                AppTheme.darkCard.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primaryCyan.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // City name
              Text(
                city.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Location
              if (city.location != null && city.location!.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: AppTheme.primaryCyan.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        city.location!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textLight.withOpacity(0.85),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Properties count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryCyan.withOpacity(0.25),
                      AppTheme.primaryPurple.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryCyan.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home_work_rounded,
                      size: 11,
                      color: AppTheme.primaryCyan,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${city.propertiesCount} عقار',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
    );
  }
}

// Shimmer Painter for light mode
class _ShimmerPainter extends CustomPainter {
  final double shimmerValue;

  _ShimmerPainter({required this.shimmerValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.03),
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.03),
          Colors.transparent,
        ],
        stops: [
          0.0,
          math.max(0.0, shimmerValue - 0.3),
          shimmerValue,
          math.min(1.0, shimmerValue + 0.3),
          1.0,
        ].map((e) => e.clamp(0.0, 1.0)).toList(),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
