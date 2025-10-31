import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'selected_property_badge.dart';

/// 🔍 Service Filters Widget
class ServiceFiltersWidget extends StatefulWidget {
  final String? selectedPropertyId;
  final String? selectedPropertyName;
  final Function(String?) onPropertyChanged;
  final VoidCallback onPropertyFieldTap;
  final VoidCallback? onClearProperty;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String? selectedPricingModel;
  final Function(String?) onPricingModelChanged;
  final double? minPrice;
  final double? maxPrice;
  final Function(double?) onMinPriceChanged;
  final Function(double?) onMaxPriceChanged;
  final bool? showOnlyFree;
  final Function(bool?) onShowOnlyFreeChanged;
  final bool hidePropertySelector;

  const ServiceFiltersWidget({
    super.key,
    required this.selectedPropertyId,
    this.selectedPropertyName,
    required this.onPropertyChanged,
    required this.onPropertyFieldTap,
    this.onClearProperty,
    required this.searchQuery,
    required this.onSearchChanged,
    this.selectedPricingModel,
    required this.onPricingModelChanged,
    this.minPrice,
    this.maxPrice,
    required this.onMinPriceChanged,
    required this.onMaxPriceChanged,
    this.showOnlyFree,
    required this.onShowOnlyFreeChanged,
    this.hidePropertySelector = false,
  });

  @override
  State<ServiceFiltersWidget> createState() => _ServiceFiltersWidgetState();
}

class _ServiceFiltersWidgetState extends State<ServiceFiltersWidget> {
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    if (widget.minPrice != null) {
      _minPriceController.text = widget.minPrice.toString();
    }
    if (widget.maxPrice != null) {
      _maxPriceController.text = widget.maxPrice.toString();
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 680;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.hidePropertySelector) _buildPropertySelector(),
                    const SizedBox(height: 12),
                    _buildSearchField(),
                    if (widget.selectedPropertyId != null && (widget.selectedPropertyName?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 12),
                      SelectedPropertyBadge(
                        propertyName: widget.selectedPropertyName!,
                        onClear: widget.onClearProperty ?? () {},
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildExpandAdvancedFilters(),
                    if (_showAdvancedFilters) ..._buildAdvancedFilters(),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: widget.hidePropertySelector ? const SizedBox.shrink() : _buildPropertySelector(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildSearchField(),
                      ),
                      if (widget.selectedPropertyId != null && (widget.selectedPropertyName?.isNotEmpty ?? false)) ...[
                        const SizedBox(width: 16),
                        SelectedPropertyBadge(
                          propertyName: widget.selectedPropertyName!,
                          onClear: widget.onClearProperty ?? () {},
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildExpandAdvancedFilters(),
                  if (_showAdvancedFilters) ..._buildAdvancedFilters(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPropertySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العقار',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: widget.onPropertyFieldTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
              width: 0.5,
            ),
          ),
            child: Row(
              children: [
                Icon(
                  Icons.home_work_outlined,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.selectedPropertyId == null
                        ? 'اختر العقار'
                        : (widget.selectedPropertyName ?? 'تم اختيار العقار'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.selectedPropertyId == null ? AppTheme.textMuted : AppTheme.textWhite,
                    ),
                  ),
                ),
                if (widget.selectedPropertyId != null && widget.onClearProperty != null)
                  GestureDetector(
                    onTap: widget.onClearProperty,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.2), width: 0.5),
                      ),
                      child: Icon(
                        Icons.clear_rounded,
                        color: AppTheme.textMuted,
                        size: 16,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.search,
                    color: AppTheme.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'البحث',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث عن خدمة...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.darkSurface.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.5),
                width: 1,
              ),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.textMuted,
            ),
            suffixIcon: widget.searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () => widget.onSearchChanged(''),
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppTheme.textMuted,
                    ),
                  )
                : null,
          ),
          onChanged: widget.onSearchChanged,
        ),
      ],
    );
  }

  Widget _buildExpandAdvancedFilters() {
    return GestureDetector(
      onTap: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showAdvancedFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _showAdvancedFilters ? 'إخفاء الفلاتر المتقدمة' : 'إظهار الفلاتر المتقدمة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAdvancedFilters() {
    return [
      const SizedBox(height: 16),
      _buildPricingModelFilter(),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _buildMinPriceFilter()),
          const SizedBox(width: 12),
          Expanded(child: _buildMaxPriceFilter()),
        ],
      ),
      const SizedBox(height: 12),
      _buildShowOnlyFreeFilter(),
    ];
  }

  Widget _buildPricingModelFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نموذج التسعير',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: DropdownButton<String?>(
            value: widget.selectedPricingModel,
            isExpanded: true,
            dropdownColor: AppTheme.darkCard,
            underline: const SizedBox.shrink(),
            hint: Text(
              'جميع الأنواع',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textMuted,
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('جميع الأنواع')),
              DropdownMenuItem(value: 'Fixed', child: Text('ثابت')),
              DropdownMenuItem(value: 'PerPerson', child: Text('للشخص')),
              DropdownMenuItem(value: 'PerNight', child: Text('لكل ليلة')),
            ],
            onChanged: widget.onPricingModelChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMinPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الحد الأدنى للسعر',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _minPriceController,
          keyboardType: TextInputType.number,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.darkSurface.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.5),
                width: 1,
              ),
            ),
            prefixIcon: Icon(
              Icons.attach_money,
              color: AppTheme.textMuted,
            ),
          ),
          onChanged: (value) {
            final price = double.tryParse(value);
            widget.onMinPriceChanged(price);
          },
        ),
      ],
    );
  }

  Widget _buildMaxPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الحد الأقصى للسعر',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _maxPriceController,
          keyboardType: TextInputType.number,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
          ),
          decoration: InputDecoration(
            hintText: '∞',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.darkSurface.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.5),
                width: 1,
              ),
            ),
            prefixIcon: Icon(
              Icons.attach_money,
              color: AppTheme.textMuted,
            ),
          ),
          onChanged: (value) {
            final price = double.tryParse(value);
            widget.onMaxPriceChanged(price);
          },
        ),
      ],
    );
  }

  Widget _buildShowOnlyFreeFilter() {
    return GestureDetector(
      onTap: () {
        final newValue = widget.showOnlyFree == true ? null : true;
        widget.onShowOnlyFreeChanged(newValue);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.showOnlyFree == true 
              ? AppTheme.primaryBlue.withOpacity(0.2) 
              : AppTheme.darkSurface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.showOnlyFree == true 
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.showOnlyFree == true ? Icons.check_box : Icons.check_box_outline_blank,
              color: widget.showOnlyFree == true ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
            const SizedBox(width: 12),
            Text(
              'عرض الخدمات المجانية فقط',
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.showOnlyFree == true ? AppTheme.primaryBlue : AppTheme.textWhite,
                fontWeight: widget.showOnlyFree == true ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}