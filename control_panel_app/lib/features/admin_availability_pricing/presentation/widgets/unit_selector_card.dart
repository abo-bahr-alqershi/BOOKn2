// lib/features/admin_availability_pricing/presentation/widgets/unit_selector_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../../features/helpers/presentation/pages/unit_search_page.dart';

class UnitSelectorCard extends StatefulWidget {
  final String? selectedUnitId;
  final String? selectedUnitName;
  final String? selectedPropertyId;
  final Function(String id, String name) onUnitSelected;
  final bool isCompact;

  const UnitSelectorCard({
    super.key,
    required this.selectedUnitId,
    this.selectedUnitName,
    this.selectedPropertyId,
    required this.onUnitSelected,
    this.isCompact = false,
  });

  @override
  State<UnitSelectorCard> createState() => _UnitSelectorCardState();
}

class _UnitSelectorCardState extends State<UnitSelectorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          height: widget.isCompact ? 60 : null,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.7),
                AppTheme.darkCard.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue
                  .withOpacity(0.2 + 0.1 * _glowAnimation.value),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue
                    .withOpacity(0.1 * _glowAnimation.value),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child:
                  widget.isCompact ? _buildCompactView() : _buildExpandedView(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildUnitIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildDropdown(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildUnitIcon(),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر الوحدة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitIcon() {
    return Container(
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
    );
  }

  Widget _buildDropdown() {
    final displayName = widget.selectedUnitName ??
        (widget.selectedUnitId != null
            ? 'وحدة ${widget.selectedUnitId}'
            : 'اختر وحدة');
    return GestureDetector(
      onTap: _openUnitSearch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getUnitIcon('suite'),
              size: 16,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
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

  Future<void> _openUnitSearch() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnitSearchPage(
          propertyId: widget.selectedPropertyId,
          allowMultiSelect: false,
          onUnitSelected: (unit) {
            widget.onUnitSelected(unit.id, unit.name);
            setState(() {});
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // Removed demo list rendering; unit selection is done via UnitSearchPage only

  IconData _getUnitIcon(String type) {
    switch (type) {
      case 'suite':
        return Icons.king_bed_rounded;
      case 'double':
        return Icons.bed_rounded;
      case 'villa':
        return Icons.villa_rounded;
      case 'studio':
        return Icons.weekend_rounded;
      default:
        return Icons.door_front_door_rounded;
    }
  }

  String _getUnitTypeLabel(String type) {
    switch (type) {
      case 'suite':
        return 'جناح';
      case 'double':
        return 'غرفة مزدوجة';
      case 'villa':
        return 'فيلا';
      case 'studio':
        return 'استوديو';
      default:
        return 'وحدة';
    }
  }
}
