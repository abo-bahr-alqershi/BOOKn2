import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/section_type.dart';

class SectionUITypePicker extends StatelessWidget {
  final SectionTypeEnum? selectedType;
  final Function(SectionTypeEnum) onTypeSelected;
  final bool showCustomTypes;

  const SectionUITypePicker({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    this.showCustomTypes = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.widgets, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              'نوع الواجهة (UI Type)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'اختياري',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'يحدد شكل العرض في التطبيق',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 16),

        // Standard Types
        _buildSection('الأنواع القياسية', _getStandardTypes()),

        if (showCustomTypes) ...[
          const SizedBox(height: 24),
          // Custom Types
          _buildSection('الأنواع المخصصة الجديدة ✨', _getCustomTypes()),
        ],
      ],
    );
  }

  Widget _buildSection(String title, List<SectionTypeEnum> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: types.map((type) => _buildTypeCard(type)).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeCard(SectionTypeEnum type) {
    final isSelected = selectedType == type;
    final isCustom = _getCustomTypes().contains(type);

    return GestureDetector(
      onTap: () => onTypeSelected(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? isCustom
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryPurple,
                        AppTheme.primaryBlue,
                      ],
                    )
                  : AppTheme.primaryGradient
              : null,
          color: isSelected ? null : AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isCustom
                    ? AppTheme.primaryPurple.withOpacity(0.3)
                    : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isCustom
                        ? AppTheme.primaryPurple.withOpacity(0.3)
                        : AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCustom)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : AppTheme.primaryPurple,
                ),
              ),
            Text(
              type.displayName,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppTheme.textWhite,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SectionTypeEnum> _getStandardTypes() {
    return [
      SectionTypeEnum.singlePropertyAd,
      SectionTypeEnum.multiPropertyAd,
      SectionTypeEnum.unitShowcaseAd,
      SectionTypeEnum.singlePropertyOffer,
      SectionTypeEnum.offersCarousel,
      SectionTypeEnum.flashDeals,
      SectionTypeEnum.horizontalPropertyList,
      SectionTypeEnum.verticalPropertyGrid,
      SectionTypeEnum.cityCardsGrid,
      SectionTypeEnum.premiumCarousel,
    ];
  }

  List<SectionTypeEnum> _getCustomTypes() {
    return [
      SectionTypeEnum.blackHoleGravityGrid,
      SectionTypeEnum.cosmicSinglePropertyOffer,
      SectionTypeEnum.dnaHelixPropertyCarousel,
      SectionTypeEnum.holographicHorizontalPropertyList,
      SectionTypeEnum.holographicSinglePropertyAd,
      SectionTypeEnum.liquidCrystalPropertyList,
      SectionTypeEnum.neuroMorphicPropertyGrid,
      SectionTypeEnum.quantumFlashDeals,
      SectionTypeEnum.auroraQuantumPortalMatrix,
      SectionTypeEnum.crystalConstellationNetwork,
    ];
  }
}
