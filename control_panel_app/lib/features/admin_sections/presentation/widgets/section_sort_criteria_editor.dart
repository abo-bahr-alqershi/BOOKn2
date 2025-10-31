import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class SectionSortCriteriaEditor extends StatefulWidget {
  final Map<String, dynamic>? initialCriteria;
  final Function(Map<String, dynamic>) onCriteriaChanged;

  const SectionSortCriteriaEditor({
    super.key,
    this.initialCriteria,
    required this.onCriteriaChanged,
  });

  @override
  State<SectionSortCriteriaEditor> createState() =>
      _SectionSortCriteriaEditorState();
}

class _SectionSortCriteriaEditorState extends State<SectionSortCriteriaEditor> {
  String _sortBy = 'createdAt';
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCriteria != null) {
      _sortBy = widget.initialCriteria!['sortBy'] ?? 'createdAt';
      _ascending = widget.initialCriteria!['ascending'] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ترتيب العناصر',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withValues(alpha: 0.5),
                AppTheme.darkCard.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildSortBySelector(),
              const SizedBox(height: 16),
              _buildSortDirectionToggle(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortBySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ترتيب حسب',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSortOption(
                'createdAt', 'تاريخ الإضافة', CupertinoIcons.calendar),
            _buildSortOption('price', 'السعر', CupertinoIcons.money_dollar),
            _buildSortOption('rating', 'التقييم', CupertinoIcons.star_fill),
            _buildSortOption(
                'popularity', 'الشعبية', CupertinoIcons.flame_fill),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        _updateCriteria();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected
              ? null
              : AppTheme.darkBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDirectionToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'الاتجاه',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        Row(
          children: [
            _buildDirectionButton(
              icon: CupertinoIcons.arrow_up,
              label: 'تصاعدي',
              isSelected: _ascending,
              onTap: () {
                setState(() {
                  _ascending = true;
                });
                _updateCriteria();
              },
            ),
            const SizedBox(width: 8),
            _buildDirectionButton(
              icon: CupertinoIcons.arrow_down,
              label: 'تنازلي',
              isSelected: !_ascending,
              onTap: () {
                setState(() {
                  _ascending = false;
                });
                _updateCriteria();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected
              ? null
              : AppTheme.darkBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCriteria() {
    widget.onCriteriaChanged({
      'sortBy': _sortBy,
      'ascending': _ascending,
    });
  }
}
