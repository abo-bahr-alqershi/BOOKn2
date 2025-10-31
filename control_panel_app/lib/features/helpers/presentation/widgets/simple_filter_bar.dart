import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class SimpleFilterBar extends StatelessWidget {
  final List<FilterOption> filters;
  final VoidCallback? onClearFilters;

  const SimpleFilterBar({
    super.key,
    required this.filters,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (onClearFilters != null)
            GestureDetector(
              onTap: onClearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.clear_rounded,
                      size: 16,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'مسح',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          ...filters.map((filter) => _buildFilterChip(filter)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(FilterOption filter) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(filter.label),
        selected: filter.isSelected,
        onSelected: filter.onChanged,
        backgroundColor: AppTheme.darkSurface.withOpacity(0.3),
        selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
        labelStyle: AppTextStyles.caption.copyWith(
          color: filter.isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
        ),
        side: BorderSide(
          color: filter.isSelected
              ? AppTheme.primaryBlue.withOpacity(0.5)
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
    );
  }
}

class FilterOption {
  final String label;
  final bool isSelected;
  final Function(bool) onChanged;

  FilterOption({
    required this.label,
    required this.isSelected,
    required this.onChanged,
  });
}