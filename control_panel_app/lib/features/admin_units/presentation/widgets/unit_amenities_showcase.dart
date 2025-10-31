// lib/features/admin_units/presentation/widgets/unit_amenities_showcase.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class UnitAmenitiesShowcase extends StatefulWidget {
  final List<String> amenities;
  final bool isCompact;

  const UnitAmenitiesShowcase({
    super.key,
    required this.amenities,
    this.isCompact = false,
  });

  @override
  State<UnitAmenitiesShowcase> createState() => _UnitAmenitiesShowcaseState();
}

class _UnitAmenitiesShowcaseState extends State<UnitAmenitiesShowcase>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _hoveredIndex;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.amenities.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final crossAxisCount = isTablet ? 3 : 2;

        return AnimationLimiter(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: widget.isCompact ? 3.5 : 2.5,
            ),
            itemCount: widget.amenities.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 600),
                columnCount: crossAxisCount,
                child: ScaleAnimation(
                  scale: 0.95,
                  child: FadeInAnimation(
                    child: _buildAmenityCard(widget.amenities[index], index),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.3),
            AppTheme.darkCard.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.sparkles,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد مرافق',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityCard(String amenity, int index) {
    final isHovered = _hoveredIndex == index;
    final isSelected = _selectedIndex == index;
    final iconData = _getAmenityIcon(amenity);
    final gradient = _getAmenityGradient(amenity);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = _selectedIndex == index ? null : index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(isHovered || isSelected ? 0.98 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isHovered || isSelected
                    ? gradient.map((c) => c.withValues(alpha: 0.15)).toList()
                    : [
                        AppTheme.darkCard.withValues(alpha: 0.3),
                        AppTheme.darkCard.withValues(alpha: 0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered || isSelected
                    ? gradient.first.withValues(alpha: 0.4)
                    : AppTheme.darkBorder.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isHovered || isSelected
                  ? [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: isHovered ? 15 : 10,
                  sigmaY: isHovered ? 15 : 10,
                ),
                child: Padding(
                  padding: EdgeInsets.all(widget.isCompact ? 10 : 14),
                  child: Row(
                    children: [
                      // Icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: widget.isCompact ? 32 : 40,
                        height: widget.isCompact ? 32 : 40,
                        decoration: BoxDecoration(
                          gradient: isHovered || isSelected
                              ? LinearGradient(colors: gradient)
                              : null,
                          color: isHovered || isSelected
                              ? null
                              : gradient.first.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: gradient.first.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          iconData,
                          size: widget.isCompact ? 16 : 20,
                          color: isHovered || isSelected
                              ? Colors.white
                              : gradient.first,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Text
                      Expanded(
                        child: Text(
                          amenity,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: isHovered || isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: widget.isCompact ? 12 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Check icon when selected
                      if (isSelected)
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          size: 16,
                          color: gradient.first,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final amenityLower = amenity.toLowerCase();

    final iconMap = {
      'wifi': CupertinoIcons.wifi,
      'واي فاي': CupertinoIcons.wifi,
      'تكييف': CupertinoIcons.snow,
      'ac': CupertinoIcons.snow,
      'مطبخ': CupertinoIcons.flame_fill,
      'kitchen': CupertinoIcons.flame_fill,
      'موقف': CupertinoIcons.car_fill,
      'parking': CupertinoIcons.car_fill,
      'مسبح': CupertinoIcons.drop_fill,
      'pool': CupertinoIcons.drop_fill,
      'جيم': CupertinoIcons.bolt_fill,
      'gym': CupertinoIcons.bolt_fill,
      'تلفزيون': CupertinoIcons.tv,
      'tv': CupertinoIcons.tv,
      'غسالة': CupertinoIcons.circle_grid_3x3_fill,
      'washer': CupertinoIcons.circle_grid_3x3_fill,
      'ميكروويف': CupertinoIcons.rays,
      'microwave': CupertinoIcons.rays,
      'ثلاجة': CupertinoIcons.square_stack_3d_down_right_fill,
      'fridge': CupertinoIcons.square_stack_3d_down_right_fill,
    };

    for (final entry in iconMap.entries) {
      if (amenityLower.contains(entry.key)) {
        return entry.value;
      }
    }

    return CupertinoIcons.star_fill;
  }

  List<Color> _getAmenityGradient(String amenity) {
    final amenityLower = amenity.toLowerCase();

    if (amenityLower.contains('wifi') || amenityLower.contains('واي فاي')) {
      return [AppTheme.primaryBlue, AppTheme.primaryCyan];
    } else if (amenityLower.contains('تكييف') || amenityLower.contains('ac')) {
      return [AppTheme.info, AppTheme.neonBlue];
    } else if (amenityLower.contains('مطبخ') ||
        amenityLower.contains('kitchen')) {
      return [AppTheme.warning, AppTheme.neonPurple];
    } else if (amenityLower.contains('موقف') ||
        amenityLower.contains('parking')) {
      return [AppTheme.primaryPurple, AppTheme.primaryViolet];
    } else if (amenityLower.contains('مسبح') || amenityLower.contains('pool')) {
      return [AppTheme.primaryCyan, AppTheme.neonBlue];
    } else if (amenityLower.contains('جيم') || amenityLower.contains('gym')) {
      return [AppTheme.success, AppTheme.neonGreen];
    }

    return [AppTheme.primaryBlue, AppTheme.primaryPurple];
  }
}
