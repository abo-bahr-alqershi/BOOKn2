// lib/features/admin_availability_pricing/presentation/widgets/property_selector_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../../features/helpers/presentation/pages/property_search_page.dart';

class PropertySelectorCard extends StatelessWidget {
  final String? selectedPropertyId;
  final String? selectedPropertyName;
  final Function(String id, String name) onPropertySelected;
  final bool isCompact;

  const PropertySelectorCard({
    super.key,
    required this.selectedPropertyId,
    required this.selectedPropertyName,
    required this.onPropertySelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isCompact ? 60 : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final title = selectedPropertyName ?? 'اختر العقار';
    return InkWell(
      onTap: () => _openPropertySearch(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'العقار',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.search_rounded,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPropertySearch(BuildContext context) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertySearchPage(
          allowMultiSelect: false,
          onPropertySelected: (property) {
            onPropertySelected(property.id, property.name ?? '');
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }
}
