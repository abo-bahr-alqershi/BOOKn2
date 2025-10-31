// lib/features/admin_properties/presentation/widgets/property_amenities_grid.dart

import 'package:bookn_cp_app/features/admin_amenities/presentation/utils/amenity_icons.dart'
    as icon;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/amenity.dart' as domain;
import '../../../../core/widgets/amenity_identity_card_tooltip.dart';

class PropertyAmenitiesGrid extends StatefulWidget {
  final List<domain.Amenity> amenities;
  final bool isCompact;

  const PropertyAmenitiesGrid({
    super.key,
    required this.amenities,
    this.isCompact = false,
  });

  @override
  State<PropertyAmenitiesGrid> createState() => _PropertyAmenitiesGridState();
}

class _PropertyAmenitiesGridState extends State<PropertyAmenitiesGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _hoveredIndex;
  String? _pressedAmenityId;
  final Map<String, GlobalKey> _amenityKeys = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  GlobalKey _getAmenityKey(String amenityId) {
    if (!_amenityKeys.containsKey(amenityId)) {
      _amenityKeys[amenityId] = GlobalKey();
    }
    return _amenityKeys[amenityId]!;
  }

  void _showAmenityCard(domain.Amenity amenity) {
    setState(() => _pressedAmenityId = amenity.id);
    
    HapticFeedback.mediumImpact();
    
    AmenityIdentityCardTooltip.show(
      context: context,
      targetKey: _getAmenityKey(amenity.id),
      amenityId: amenity.id,
      name: amenity.name,
      description: amenity.description,
      icon: amenity.icon,
      isAvailable: amenity.isAvailable,
      extraCost: amenity.extraCost,
      currency: amenity.currency,
    );
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _pressedAmenityId = null);
    });
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

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(4),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: widget.isCompact ? 3.5 : 2.8,
              ),
              itemCount: widget.amenities.length,
              itemBuilder: (context, index) {
                final amenity = widget.amenities[index];
                final delay = index * 0.1;

                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        delay,
                        delay + 0.5,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(
                      begin: 0,
                      end: 1,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          delay,
                          delay + 0.5,
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: _buildAmenityCard(amenity, index),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.square_grid_2x2,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد مرافق مضافة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'سيتم إضافة المرافق قريباً',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityCard(domain.Amenity amenity, int index) {
    final isHovered = _hoveredIndex == index;
    final iconData = _getAmenityIcon(amenity.icon);
    final gradient = _getAmenityGradient('general');

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        key: _getAmenityKey(amenity.id),
        onLongPress: () => _showAmenityCard(amenity),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(isHovered ? 0.98 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHovered
                  ? gradient.map((c) => c.withValues(alpha: 0.15)).toList()
                  : [
                      AppTheme.darkCard.withValues(alpha: 0.3),
                      AppTheme.darkCard.withValues(alpha: 0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressedAmenityId == amenity.id
                  ? gradient.first.withValues(alpha: 0.6)
                  : isHovered
                      ? gradient.first.withValues(alpha: 0.3)
                      : AppTheme.darkBorder.withValues(alpha: 0.2),
              width: _pressedAmenityId == amenity.id ? 2 : 1,
            ),
            boxShadow: isHovered
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
                padding: EdgeInsets.all(widget.isCompact ? 10 : 12),
                child: Row(
                  children: [
                    // Icon Container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: widget.isCompact ? 32 : 36,
                      height: widget.isCompact ? 32 : 36,
                      decoration: BoxDecoration(
                        gradient:
                            isHovered ? LinearGradient(colors: gradient) : null,
                        color: isHovered
                            ? null
                            : gradient.first.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: gradient.first.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        iconData,
                        size: widget.isCompact ? 16 : 18,
                        color: isHovered ? Colors.white : gradient.first,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            amenity.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: isHovered
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: widget.isCompact ? 12 : 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (amenity.description != null &&
                              !widget.isCompact) ...[
                            const SizedBox(height: 2),
                            Text(
                              amenity.description!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted.withValues(
                                  alpha: isHovered ? 0.9 : 0.7,
                                ),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Premium Badge removed (domain model has no premium flag)
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

  IconData _getAmenityIcon(String iconName) {
    return icon.AmenityIcons.getIconByName(iconName)?.icon ??
        Icons.star_rounded;
  }

  List<Color> _getAmenityGradient(String category) {
    final Map<String, List<Color>> gradientMap = {
      'essentials': [AppTheme.primaryBlue, AppTheme.primaryCyan],
      'comfort': [AppTheme.primaryPurple, AppTheme.primaryViolet],
      'entertainment': [AppTheme.neonPurple, AppTheme.neonBlue],
      'wellness': [AppTheme.success, AppTheme.neonGreen],
      'dining': [AppTheme.warning, AppTheme.neonPurple],
      'business': [AppTheme.info, AppTheme.primaryBlue],
      'security': [AppTheme.error, AppTheme.primaryViolet],
      'general': [AppTheme.primaryBlue, AppTheme.primaryPurple],
    };

    return gradientMap[category.toLowerCase()] ??
        [AppTheme.primaryBlue, AppTheme.primaryPurple];
  }
}

// Amenity Entity Model (للمرجع)
class Amenity {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? category;
  final bool? isPremium;

  const Amenity({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.category,
    this.isPremium,
  });
}
