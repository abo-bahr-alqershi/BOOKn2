import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/section_type.dart';

class SectionTypeSelector extends StatelessWidget {
  final SectionTypeEnum? selectedType;
  final Function(SectionTypeEnum) onTypeSelected;

  const SectionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع القسم',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: SectionTypeEnum.values.map((type) {
            return _buildTypeCard(type);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeCard(SectionTypeEnum type) {
    final isSelected = selectedType == type;
    final typeInfo = _getTypeInfo(type);

    return GestureDetector(
      onTap: () => onTypeSelected(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(12),
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
                    color: typeInfo['color'].withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : typeInfo['color'].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                typeInfo['icon'],
                color: isSelected ? Colors.white : typeInfo['color'],
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              typeInfo['label'],
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppTheme.textWhite,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(SectionTypeEnum type) {
    switch (type) {
      case SectionTypeEnum.singlePropertyAd:
        return {
          'icon': CupertinoIcons.star_fill,
          'label': 'مميز',
          'color': AppTheme.warning,
        };
      case SectionTypeEnum.multiPropertyAd:
        return {
          'icon': CupertinoIcons.flame_fill,
          'label': 'الأكثر شعبية',
          'color': AppTheme.error,
        };
      case SectionTypeEnum.unitShowcaseAd:
        return {
          'icon': CupertinoIcons.sparkles,
          'label': 'جديد',
          'color': AppTheme.success,
        };
      case SectionTypeEnum.singlePropertyOffer:
        return {
          'icon': CupertinoIcons.chart_bar_alt_fill,
          'label': 'الأعلى تقييماً',
          'color': AppTheme.primaryPurple,
        };
      case SectionTypeEnum.flashDeals:
        return {
          'icon': CupertinoIcons.tag_fill,
          'label': 'عروض وخصومات',
          'color': AppTheme.warning,
        };
      case SectionTypeEnum.cityCardsGrid:
        return {
          'icon': CupertinoIcons.location_fill,
          'label': 'قريب منك',
          'color': AppTheme.info,
        };
      case SectionTypeEnum.premiumCarousel:
        return {
          'icon': CupertinoIcons.hand_thumbsup_fill,
          'label': 'موصى به',
          'color': AppTheme.primaryBlue,
        };
      case SectionTypeEnum.verticalPropertyGrid:
        return {
          'icon': CupertinoIcons.square_grid_2x2_fill,
          'label': 'فئة',
          'color': AppTheme.primaryViolet,
        };
      case SectionTypeEnum.horizontalPropertyList:
        return {
          'icon': CupertinoIcons.wrench_fill,
          'label': 'مخصص',
          'color': AppTheme.textMuted,
        };
      default:
        return {
          'icon': CupertinoIcons.square_fill,
          'label': 'افتراضي',
          'color': AppTheme.textMuted,
        };
    }
  }
}
