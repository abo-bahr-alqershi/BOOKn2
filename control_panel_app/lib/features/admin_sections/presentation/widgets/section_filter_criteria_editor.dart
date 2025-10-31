import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../reference/presentation/widgets/city_selector_dialog.dart';

class SectionFilterCriteriaEditor extends StatefulWidget {
  final Map<String, dynamic>? initialCriteria;
  final Function(Map<String, dynamic>) onCriteriaChanged;

  const SectionFilterCriteriaEditor({
    super.key,
    this.initialCriteria,
    required this.onCriteriaChanged,
  });

  @override
  State<SectionFilterCriteriaEditor> createState() =>
      _SectionFilterCriteriaEditorState();
}

class _SectionFilterCriteriaEditorState
    extends State<SectionFilterCriteriaEditor> {
  final Map<String, dynamic> _criteria = {};
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _minRatingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCriteria != null) {
      _criteria.addAll(widget.initialCriteria!);
      _minPriceController.text = _criteria['minPrice']?.toString() ?? '';
      _maxPriceController.text = _criteria['maxPrice']?.toString() ?? '';
      _minRatingController.text = _criteria['minRating']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minRatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معايير التصفية',
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
              _buildPriceRange(),
              const SizedBox(height: 16),
              _buildRatingFilter(),
              const SizedBox(height: 16),
              _buildCityFilter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نطاق السعر',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _minPriceController,
                hint: 'الحد الأدنى',
                icon: CupertinoIcons.money_dollar,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null) {
                    _criteria['minPrice'] = price;
                    widget.onCriteriaChanged(_criteria);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _maxPriceController,
                hint: 'الحد الأقصى',
                icon: CupertinoIcons.money_dollar,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null) {
                    _criteria['maxPrice'] = price;
                    widget.onCriteriaChanged(_criteria);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التقييم الأدنى',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _minRatingController,
          hint: 'أدخل التقييم الأدنى (1-5)',
          icon: CupertinoIcons.star_fill,
          onChanged: (value) {
            final rating = double.tryParse(value);
            if (rating != null && rating >= 0 && rating <= 5) {
              _criteria['minRating'] = rating;
              widget.onCriteriaChanged(_criteria);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المدينة',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selected = await CitySelectorDialog.show(context);
            if (selected != null && selected.isNotEmpty) {
              setState(() {
                _criteria['cityName'] = selected;
              });
              widget.onCriteriaChanged(_criteria);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.darkBorder.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_city_rounded,
                  size: 16,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (_criteria['cityName'] as String?)?.isNotEmpty == true
                        ? _criteria['cityName'] as String
                        : 'اختر المدينة',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: (_criteria['cityName'] as String?)?.isNotEmpty == true
                          ? AppTheme.textWhite
                          : AppTheme.textMuted.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if ((_criteria['cityName'] as String?)?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _criteria.remove('cityName');
                        });
                        widget.onCriteriaChanged(_criteria);
                      },
                      child: Icon(
                        Icons.clear,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.textWhite,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            icon,
            color: AppTheme.primaryBlue.withValues(alpha: 0.7),
            size: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
