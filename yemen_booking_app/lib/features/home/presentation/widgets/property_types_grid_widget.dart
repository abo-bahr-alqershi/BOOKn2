// lib/features/home/presentation/widgets/categories/property_types_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yemen_booking_app/features/home/domain/entities/property_type.dart';
import 'dart:math' as math;
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'property_type_card_widget.dart';

class PropertyTypesGrid extends StatefulWidget {
  final List<PropertyType> propertyTypes;
  final String? selectedTypeId;
  final Function(String?) onTypeSelected;

  const PropertyTypesGrid({
    super.key,
    required this.propertyTypes,
    this.selectedTypeId,
    required this.onTypeSelected,
  });

  @override
  State<PropertyTypesGrid> createState() => _PropertyTypesGridState();
}

class _PropertyTypesGridState extends State<PropertyTypesGrid>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _shimmerController;

  bool _isExpanded = false;
  final int _initialDisplayCount = 6;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayCount = _isExpanded
        ? widget.propertyTypes.length
        : math.min(_initialDisplayCount, widget.propertyTypes.length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            height: _calculateGridHeight(displayCount),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.80,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: displayCount,
              itemBuilder: (context, index) {
                final type = widget.propertyTypes[index];
                return PropertyTypeCard(
                  propertyType: type,
                  isSelected: widget.selectedTypeId == type.id,
                  onTap: () => _handleTypeSelection(type),
                  animationDelay: Duration(milliseconds: index * 50),
                );
              },
            ),
          ),
          if (widget.propertyTypes.length > _initialDisplayCount)
            _buildExpandButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.category,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'أنواع العقارات',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (widget.selectedTypeId != null) _buildClearButton(),
      ],
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTypeSelected(null);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear,
              size: 16,
              color: AppTheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'إلغاء التحديد',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return Center(
      child: GestureDetector(
        onTap: _toggleExpand,
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.8),
                AppTheme.darkCard.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isExpanded ? 'عرض أقل' : 'عرض المزيد',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateGridHeight(int itemCount) {
    final rows = (itemCount / 3).ceil();
    return rows * 138.0; // Height per row including spacing
  }

  void _toggleExpand() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _handleTypeSelection(PropertyType type) {
    HapticFeedback.lightImpact();
    if (widget.selectedTypeId == type.id) {
      widget.onTypeSelected(null);
    } else {
      widget.onTypeSelected(type.id);
    }
  }
}
