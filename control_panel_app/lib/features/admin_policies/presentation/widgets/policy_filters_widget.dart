import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/policy.dart';
import '../../../../services/local_storage_service.dart';
import '../../../admin_properties/domain/entities/property.dart';
import '../../../helpers/presentation/pages/property_search_page.dart';

class PolicyFiltersWidget extends StatefulWidget {
  final Function(String?, PolicyType?)? onFilterChanged;
  final bool showPropertyFilter;

  const PolicyFiltersWidget({
    super.key,
    this.onFilterChanged,
    this.showPropertyFilter = true,
  });

  @override
  State<PolicyFiltersWidget> createState() => _PolicyFiltersWidgetState();
}

class _PolicyFiltersWidgetState extends State<PolicyFiltersWidget> {
  PolicyType? _selectedType;
  String? _selectedPropertyId;
  String? _selectedPropertyName;
  final _storage = GetIt.I<LocalStorageService>();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  void _checkUserRole() {
    final role = _storage.getAccountRole();
    setState(() {
      _isAdmin = role.toLowerCase() == 'admin';
      // إذا كان Owner أو Staff، احصل على propertyId تلقائياً
      if (!_isAdmin) {
        _selectedPropertyId = _storage.getPropertyId();
        _selectedPropertyName = _storage.getPropertyName();
        // مرر propertyId تلقائياً للـ Owner/Staff
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onFilterChanged?.call(_selectedPropertyId, null);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.slider_horizontal_3,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'الفلاتر',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(CupertinoIcons.xmark_circle, size: 16),
                label: const Text('مسح'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Property Selector (Admin only)
          if (_isAdmin && widget.showPropertyFilter) ...[
            _buildPropertySelector(),
            const SizedBox(height: 16),
          ],
          // Policy Type Filters
          Text(
            'نوع السياسة',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: PolicyType.values.map((type) {
              final isSelected = _selectedType == type;
              return FilterChip(
                selected: isSelected,
                label: Text(type.displayName),
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? type : null;
                  });
                  widget.onFilterChanged
                      ?.call(_selectedPropertyId, _selectedType);
                },
                backgroundColor: AppTheme.darkBackground,
                selectedColor: _getPolicyTypeColor(type).withValues(alpha: 0.2),
                checkmarkColor: _getPolicyTypeColor(type),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? _getPolicyTypeColor(type)
                      : AppTheme.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? _getPolicyTypeColor(type)
                      : AppTheme.darkBorder.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySelector() {
    return InkWell(
      onTap: _openPropertySearch,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedPropertyId != null
                ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                : AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: _selectedPropertyId != null
                    ? AppTheme.primaryGradient
                    : null,
                color: _selectedPropertyId == null
                    ? AppTheme.darkSurface.withValues(alpha: 0.5)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.apartment_rounded,
                color: _selectedPropertyId != null
                    ? Colors.white
                    : AppTheme.textMuted,
                size: 18,
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
                  const SizedBox(height: 2),
                  Text(
                    _selectedPropertyName ?? 'جميع العقارات',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (_selectedPropertyId != null)
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _selectedPropertyId = null;
                    _selectedPropertyName = null;
                  });
                  widget.onFilterChanged?.call(null, _selectedType);
                },
              )
            else
              Icon(
                Icons.search,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPropertySearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertySearchPage(
          allowMultiSelect: false,
          onPropertySelected: (Property property) {
            setState(() {
              _selectedPropertyId = property.id;
              _selectedPropertyName = property.name;
            });
            widget.onFilterChanged?.call(_selectedPropertyId, _selectedType);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      if (_isAdmin) {
        _selectedPropertyId = null;
        _selectedPropertyName = null;
      }
    });
    widget.onFilterChanged?.call(_isAdmin ? null : _selectedPropertyId, null);
  }

  Color _getPolicyTypeColor(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return AppTheme.error;
      case PolicyType.checkIn:
        return AppTheme.primaryBlue;
      case PolicyType.children:
        return AppTheme.warning;
      case PolicyType.pets:
        return AppTheme.primaryViolet;
      case PolicyType.payment:
        return AppTheme.success;
      case PolicyType.modification:
        return AppTheme.primaryPurple;
    }
  }
}
