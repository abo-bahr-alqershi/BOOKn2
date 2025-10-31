import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/section_display_style.dart';

class SectionDisplayStylePicker extends StatelessWidget {
  final SectionDisplayStyle? selectedStyle;
  final Function(SectionDisplayStyle) onStyleSelected;

  const SectionDisplayStylePicker({
    super.key,
    required this.selectedStyle,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نمط العرض',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: SectionDisplayStyle.values.map((style) {
            return _buildStyleCard(style);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStyleCard(SectionDisplayStyle style) {
    final isSelected = selectedStyle == style;
    final styleInfo = _getStyleInfo(style);

    return GestureDetector(
      onTap: () => onStyleSelected(style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              styleInfo['icon'],
              color: isSelected ? Colors.white : AppTheme.textMuted,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              styleInfo['label'],
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppTheme.textWhite,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStyleInfo(SectionDisplayStyle style) {
    switch (style) {
      case SectionDisplayStyle.grid:
        return {
          'icon': CupertinoIcons.square_grid_2x2,
          'label': 'شبكة',
        };
      case SectionDisplayStyle.list:
        return {
          'icon': CupertinoIcons.list_bullet,
          'label': 'قائمة',
        };
      case SectionDisplayStyle.carousel:
        return {
          'icon': CupertinoIcons.play_rectangle_fill,
          'label': 'عرض متحرك',
        };
      case SectionDisplayStyle.map:
        return {
          'icon': CupertinoIcons.map_fill,
          'label': 'خريطة',
        };
    }
  }
}
