import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';

class AmenityFiltersWidget extends StatefulWidget {
  final Function(String?, bool?, bool?, String?) onFilterChanged;
  final String? initialSearchTerm;
  final bool? initialIsAssigned;
  final bool? initialIsFree;
  final String? initialPropertyTypeId;

  const AmenityFiltersWidget({
    super.key,
    required this.onFilterChanged,
    this.initialSearchTerm,
    this.initialIsAssigned,
    this.initialIsFree,
    this.initialPropertyTypeId,
  });

  @override
  State<AmenityFiltersWidget> createState() => _AmenityFiltersWidgetState();
}

class _AmenityFiltersWidgetState extends State<AmenityFiltersWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late TextEditingController _searchController;

  bool _isExpanded = false;
  String? _searchTerm;
  bool? _isAssigned;
  bool? _isFree;
  String? _propertyTypeId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchTerm ?? '');
    _searchTerm = widget.initialSearchTerm;
    _isAssigned = widget.initialIsAssigned;
    _isFree = widget.initialIsFree;
    _propertyTypeId = widget.initialPropertyTypeId;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
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
          child: Column(
            children: [
              _buildHeader(),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildFilters(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _isExpanded
                  ? AppTheme.primaryBlue.withOpacity(0.2)
                  : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.filter_list_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'الفلاتر',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_hasActiveFilters()) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getActiveFiltersCount().toString(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const Spacer(),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildPropertyTypeDropdown(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterOption(
                  'المرافق المسندة',
                  Icons.link_rounded,
                  _isAssigned == true,
                  () => _updateFilter(isAssigned: _isAssigned == true ? null : true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterOption(
                  'المرافق المجانية',
                  Icons.money_off_rounded,
                  _isFree == true,
                  () => _updateFilter(isFree: _isFree == true ? null : true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'مسح الفلاتر',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Text(
                      'تطبيق',
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryPurple.withOpacity(0.1),
                  ],
                )
              : null,
          color: !isActive ? AppTheme.darkSurface.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isActive)
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryBlue,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _updateFilter({bool? isAssigned, bool? isFree}) {
    setState(() {
      if (isAssigned != null) _isAssigned = isAssigned;
      if (isFree != null) _isFree = isFree;
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppTheme.textWhite,
      ),
      decoration: InputDecoration(
        hintText: 'ابحث عن مرفق...',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textMuted,
        ),
        filled: true,
        fillColor: AppTheme.darkSurface.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.5),
            width: 1,
          ),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppTheme.textMuted,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: AppTheme.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchTerm = null;
                  });
                },
              )
            : null,
      ),
      onChanged: (value) {
        setState(() {
          _searchTerm = value.isEmpty ? null : value;
        });
      },
    );
  }

  Widget _buildPropertyTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _propertyTypeId != null 
              ? AppTheme.primaryBlue.withOpacity(0.5)
              : AppTheme.darkBorder.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButton<String?>(
        value: _propertyTypeId,
        isExpanded: true,
        dropdownColor: AppTheme.darkCard,
        underline: const SizedBox.shrink(),
        hint: Text(
          'نوع العقار',
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
        items: [
          DropdownMenuItem(value: null, child: Text('جميع الأنواع')),
          DropdownMenuItem(value: 'hotel', child: Text('فندق')),
          DropdownMenuItem(value: 'apartment', child: Text('شقة')),
          DropdownMenuItem(value: 'resort', child: Text('منتجع')),
          DropdownMenuItem(value: 'villa', child: Text('فيلا')),
          DropdownMenuItem(value: 'chalet', child: Text('شاليه')),
        ],
        onChanged: (value) {
          setState(() {
            _propertyTypeId = value;
          });
        },
      ),
    );
  }

  void _applyFilters() {
    widget.onFilterChanged(_searchTerm, _isAssigned, _isFree, _propertyTypeId);
    _toggleExpanded();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchTerm = null;
      _isAssigned = null;
      _isFree = null;
      _propertyTypeId = null;
    });
    widget.onFilterChanged(null, null, null, null);
  }

  bool _hasActiveFilters() {
    return _searchTerm != null || _isAssigned != null || _isFree != null || _propertyTypeId != null;
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_searchTerm != null && _searchTerm!.isNotEmpty) count++;
    if (_isAssigned != null) count++;
    if (_isFree != null) count++;
    if (_propertyTypeId != null) count++;
    return count;
  }
}