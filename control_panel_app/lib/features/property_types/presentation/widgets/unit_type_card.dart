import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../../domain/entities/unit_type.dart';

class UnitTypeCard extends StatefulWidget {
  final UnitType unitType;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UnitTypeCard({
    super.key,
    required this.unitType,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<UnitTypeCard> createState() => _UnitTypeCardState();
}

class _UnitTypeCardState extends State<UnitTypeCard>
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
      'apartment': Icons.apartment_rounded,
      'bed': Icons.bed_rounded,
      'king_bed': Icons.king_bed_rounded,
      'single_bed': Icons.single_bed_rounded,
      'bedroom_parent': Icons.bedroom_parent_rounded,
      'bedroom_child': Icons.bedroom_child_rounded,
      'living_room': Icons.living_rounded,
      'meeting_room': Icons.meeting_room_rounded,
      'house': Icons.house_rounded,
      'cottage': Icons.cottage_rounded,
      'villa': Icons.villa_rounded,
      'cabin': Icons.cabin_rounded,
      'pool': Icons.pool_rounded,
      'hot_tub': Icons.hot_tub_rounded,
      'spa': Icons.spa_rounded,
      'kitchen': Icons.kitchen_rounded,
      'bathroom': Icons.bathroom_rounded,
      'balcony': Icons.balcony_rounded,
      'deck': Icons.deck_rounded,
      'yard': Icons.yard_rounded,
    };
    return iconMap[iconName] ?? Icons.apartment_rounded;
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
                            AppTheme.neonGreen.withOpacity(0.2),
                            AppTheme.primaryBlue.withOpacity(0.1),
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
                        ? AppTheme.neonGreen.withOpacity(0.5)
                        : _isHovered
                            ? AppTheme.darkBorder.withOpacity(0.5)
                            : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.neonGreen.withOpacity(0.2),
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
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.neonGreen,
                                  AppTheme.neonGreen.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getIconFromString(widget.unitType.icon),
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
                                  widget.unitType.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (widget.unitType.isHasAdults)
                                      _buildFeatureBadge(
                                        Icons.person_rounded,
                                        'بالغين',
                                        AppTheme.primaryBlue,
                                      ),
                                    if (widget.unitType.isHasChildren)
                                      _buildFeatureBadge(
                                        Icons.child_care_rounded,
                                        'أطفال',
                                        AppTheme.neonGreen,
                                      ),
                                    if (widget.unitType.isMultiDays)
                                      _buildFeatureBadge(
                                        Icons.calendar_month_rounded,
                                        'متعدد',
                                        AppTheme.warning,
                                      ),
                                    if (widget.unitType.isRequiredToDetermineTheHour)
                                      _buildFeatureBadge(
                                        Icons.access_time_rounded,
                                        'بالساعة',
                                        AppTheme.primaryPurple,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'السعة القصوى: ${widget.unitType.maxCapacity}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
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
                                color: AppTheme.neonGreen,
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
                                      Icon(Icons.edit_rounded, color: AppTheme.neonGreen, size: 18),
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

  Widget _buildFeatureBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTextStyles.overline.copyWith(
              color: color,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}