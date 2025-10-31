import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../../domain/entities/property_type.dart';

class PropertyTypeCard extends StatefulWidget {
  final PropertyType propertyType;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PropertyTypeCard({
    super.key,
    required this.propertyType,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<PropertyTypeCard> createState() => _PropertyTypeCardState();
}

class _PropertyTypeCardState extends State<PropertyTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getIconFromString(String iconName) {
    final iconMap = {
      'home': Icons.home_rounded,
      'apartment': Icons.apartment_rounded,
      'villa': Icons.villa_rounded,
      'business': Icons.business_rounded,
      'store': Icons.store_rounded,
      'hotel': Icons.hotel_rounded,
      'house': Icons.house_rounded,
      'cabin': Icons.cabin_rounded,
      'meeting_room': Icons.meeting_room_rounded,
      'stairs': Icons.stairs_rounded,
      'roofing': Icons.roofing_rounded,
      'warehouse': Icons.warehouse_rounded,
      'terrain': Icons.terrain_rounded,
      'grass': Icons.grass_rounded,
      'location_city': Icons.location_city_rounded,
      'cottage': Icons.cottage_rounded,
      'holiday_village': Icons.holiday_village_rounded,
      'gite': Icons.gite_rounded,
      'domain': Icons.domain_rounded,
      'foundation': Icons.foundation_rounded,
    };
    return iconMap[iconName] ?? Icons.business_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isSelected
                        ? [
                            AppTheme.primaryBlue.withOpacity(0.2),
                            AppTheme.primaryPurple.withOpacity(0.1),
                          ]
                        : _isHovered
                            ? [
                                AppTheme.darkCard.withOpacity(0.8),
                                AppTheme.darkCard.withOpacity(0.6),
                              ]
                            : [
                                AppTheme.darkCard.withOpacity(0.5),
                                AppTheme.darkCard.withOpacity(0.3),
                              ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : _isHovered
                            ? AppTheme.darkBorder.withOpacity(0.5)
                            : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getIconFromString(widget.propertyType.icon),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.propertyType.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.propertyType.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.propertyType.description,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (widget.propertyType.defaultAmenities.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: widget.propertyType.defaultAmenities
                                        .take(3)
                                        .map((amenity) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                amenity,
                                                style: AppTextStyles.overline.copyWith(
                                                  color: AppTheme.primaryBlue,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_isHovered && !isSmall) ...[
                            IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                widget.onEdit();
                              },
                              icon: Icon(
                                Icons.edit_rounded,
                                color: AppTheme.primaryBlue,
                                size: 18,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                widget.onDelete();
                              },
                              icon: Icon(
                                Icons.delete_rounded,
                                color: AppTheme.error,
                                size: 18,
                              ),
                            ),
                          ]
                          else if (isSmall) ...[
                            PopupMenuButton<String>(
                              color: AppTheme.darkCard,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  widget.onEdit();
                                } else if (value == 'delete') {
                                  widget.onDelete();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, color: AppTheme.primaryBlue, size: 18),
                                      const SizedBox(width: 8),
                                      const Text('تعديل'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_rounded, color: AppTheme.error, size: 18),
                                      const SizedBox(width: 8),
                                      const Text('حذف'),
                                    ],
                                  ),
                                ),
                              ],
                              icon: Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}