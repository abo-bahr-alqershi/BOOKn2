import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../../services/local_data_service.dart';

class FilterChipsWidget extends StatefulWidget {
  final Map<String, dynamic> filters;
  final Function(String) onRemoveFilter;
  final VoidCallback? onClearAll;

  const FilterChipsWidget({
    super.key,
    required this.filters,
    required this.onRemoveFilter,
    this.onClearAll,
  });

  @override
  State<FilterChipsWidget> createState() => _FilterChipsWidgetState();
}

class _FilterChipsWidgetState extends State<FilterChipsWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  final Map<String, AnimationController> _chipAnimations = {};
  
  // Local names cache
  late final LocalDataService _localDataService = sl<LocalDataService>();
  Map<String, String> _propertyTypeIdToName = {};
  Map<String, String> _unitTypeIdToName = {};

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    
    // Create animation for each chip
    for (var key in widget.filters.keys) {
      _chipAnimations[key] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      )..forward();
    }

    // Load locally saved names for property and unit types
    _loadLocalNames();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    for (var controller in _chipAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLocalNames() async {
    try {
      // Load property types names from local cache (saved on home)
      final propertyTypes = _localDataService.getPropertyTypes();
      final unitTypes = _localDataService.getUnitTypes();
      if (mounted) {
        setState(() {
          _propertyTypeIdToName = {
            for (final pt in propertyTypes) pt.id: pt.name,
          };
          _unitTypeIdToName = {
            for (final ut in unitTypes) ut.id: ut.name,
          };
        });
      }
    } catch (_) {
      // Ignore silently; widget will fallback to generic labels
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filters.isEmpty) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      )),
      child: FadeTransition(
        opacity: _fadeController,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingSmall,
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
            ),
            children: [
              if (widget.filters.length > 1 && widget.onClearAll != null) ...[
                _buildClearAllChip(),
                const SizedBox(width: AppDimensions.spacingSm),
              ],
              ...widget.filters.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(left: AppDimensions.spacingSm),
                  child: _buildFilterChip(
                    entry.key,
                    entry.value,
                    () => _removeFilter(entry.key),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildClearAllChip() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fadeController,
        curve: Curves.elasticOut,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.error.withOpacity(0.2),
              AppTheme.error.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onClearAll,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.clear_all_rounded,
                    size: 16,
                    color: AppTheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'مسح الكل',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, dynamic value, VoidCallback onDelete) {
    final String label = _getFilterLabel(key, value);
    final IconData icon = _getFilterIcon(key);
    final Color color = _getFilterColor(key);
    
    final controller = _chipAnimations[key];
    if (controller == null) return const SizedBox.shrink();

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_isRequiredField(key, widget.filters)) {
                    _showRequiredFieldError(key);
                    return;
                  }
                  _animateRemoval(key, onDelete);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 12,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _removeFilter(String key) {
                  // منع حذف الحقول المطلوبة
  if (_isRequiredField(key, widget.filters)) {
    _showRequiredFieldError(key);
    return;
  }
    widget.onRemoveFilter(key);
  }
  
  void _animateRemoval(String key, VoidCallback onComplete) {
    final controller = _chipAnimations[key];
    if (controller != null) {
      controller.reverse().then((_) {
        onComplete();
      });
    } else {
      onComplete();
    }
  }

  String _getFilterLabel(String key, dynamic value) {
    switch (key) {
      case 'searchTerm':
        return value.toString();
      case 'city':
        return value.toString();
      case 'propertyTypeId':
        return _getPropertyTypeName(value);
      case 'unitTypeId':
        return _getUnitTypeName(value);
      case 'minPrice':
        return 'من ${_formatPrice(value)}';
      case 'maxPrice':
        return 'إلى ${_formatPrice(value)}';
      case 'minStarRating':
        return '$value نجوم+';
      case 'checkIn':
        return 'دخول: ${_formatDate(value as DateTime)}';
      case 'checkOut':
        return 'خروج: ${_formatDate(value as DateTime)}';
      case 'guestsCount':
        return '$value ${value == 1 ? "ضيف" : "ضيوف"}';
      case 'requiredAmenities':
        final List<String> amenities = value as List<String>;
        return '${amenities.length} مرافق';
      case 'serviceIds':
        final List<String> services = value as List<String>;
        return '${services.length} خدمات';
      case 'dynamicFieldFilters':
        final Map<String, dynamic> dynamicFilters = value as Map<String, dynamic>;
        return '${dynamicFilters.length} حقول ديناميكية';
      case 'sortBy':
        return _getSortByLabel(value);
      default:
        return value.toString();
    }
  }

  IconData _getFilterIcon(String key) {
    switch (key) {
      case 'searchTerm':
        return Icons.search_rounded;
      case 'city':
        return Icons.location_on_rounded;
      case 'propertyTypeId':
        return Icons.home_rounded;
      case 'unitTypeId':
        return Icons.bed_rounded;
      case 'minPrice':
      case 'maxPrice':
        return Icons.attach_money_rounded;
      case 'minStarRating':
        return Icons.star_rounded;
      case 'checkIn':
      case 'checkOut':
        return Icons.calendar_today_rounded;
      case 'guestsCount':
        return Icons.people_rounded;
      case 'requiredAmenities':
        return Icons.apps_rounded;
      case 'serviceIds':
        return Icons.room_service_rounded;
      case 'dynamicFieldFilters':
        return Icons.tune_rounded;
      case 'sortBy':
        return Icons.sort_rounded;
      default:
        return Icons.filter_alt_rounded;
    }
  }

  Color _getFilterColor(String key) {
    switch (key) {
      case 'searchTerm':
        return AppTheme.primaryBlue;
      case 'city':
        return AppTheme.neonBlue;
      case 'propertyTypeId':
        return AppTheme.primaryPurple;
      case 'unitTypeId':
        return AppTheme.primaryCyan;
      case 'minPrice':
      case 'maxPrice':
        return AppTheme.success;
      case 'minStarRating':
        return AppTheme.warning;
      case 'checkIn':
      case 'checkOut':
        return AppTheme.primaryViolet;
      case 'guestsCount':
        return AppTheme.info;
      case 'requiredAmenities':
        return AppTheme.neonPurple;
      case 'serviceIds':
        return AppTheme.primaryCyan;
      case 'dynamicFieldFilters':
        return AppTheme.neonGreen;
      default:
        return AppTheme.textMuted;
    }
  }

  String _getPropertyTypeName(String typeId) {
    if (_propertyTypeIdToName.isNotEmpty) {
      return _propertyTypeIdToName[typeId] ?? 'نوع العقار';
    }
    return 'نوع العقار';
  }

  String _getUnitTypeName(String typeId) {
    if (_unitTypeIdToName.isNotEmpty) {
      return _unitTypeIdToName[typeId] ?? 'نوع الوحدة';
    }
    return 'نوع الوحدة';
  }

  String _getSortByLabel(String sortBy) {
    switch (sortBy) {
      case 'price_asc':
        return 'السعر ↑';
      case 'price_desc':
        return 'السعر ↓';
      case 'rating':
        return 'التقييم';
      case 'popularity':
        return 'الأكثر شعبية';
      case 'newest':
        return 'الأحدث';
      case 'distance':
        return 'المسافة';
      default:
        return 'ترتيب';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
  
  String _formatPrice(dynamic price) {
    final value = price is int ? price.toDouble() : price as double;
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

    bool _isRequiredField(String key, Map<String, dynamic> filters) {
    // الحقول الأساسية المطلوبة
    if (key == 'propertyTypeId' || key == 'unitTypeId') {
      return true;
    }
    
    // التحقق من الحقول الديناميكية المطلوبة
    if (key == 'dynamicFieldFilters') {
      // تحقق من وجود حقول ديناميكية مطلوبة
      return _hasMandatoryDynamicFields(filters);
    }
    
    // التحقق من الحقول الديناميكية المطلوبة
    if (key == 'checkIn' || key == 'checkOut') {
      // تحقق من وجود حقول ديناميكية مطلوبة
      return true;
    }

    return false;
  }

  bool _hasMandatoryDynamicFields(Map<String, dynamic> filters) {
    // هنا يمكنك التحقق من الحقول الديناميكية المطلوبة
    // بناءً على نوع الوحدة المحدد
    final unitTypeId = filters['unitTypeId'];
    if (unitTypeId == null) return false;
    
    // يمكنك جلب معلومات الحقول المطلوبة من LocalDataService
    // أو من البيانات المحفوظة
    return false; // مؤقتاً
  }
    void _showRequiredFieldError(String fieldKey) {
    String message = '';
    
    switch (fieldKey) {
      case 'propertyTypeId':
        message = 'نوع العقار مطلوب ولا يمكن إلغاؤه';
        break;
      case 'unitTypeId':
        message = 'نوع الوحدة مطلوب ولا يمكن إلغاؤه';
        break;
      case 'dynamicFieldFilters':
        message = 'هناك حقول مطلوبة لا يمكن إلغاؤها';
        break;
      case 'checkIn':
        message = 'تاريخ الوصول مطلوب ولا يمكن إلغاؤه';
        break;
      case 'checkOut':
        message = 'تاريخ المغادرة مطلوب ولا يمكن إلغاؤه';
        break;
      default:
        message = 'هذا الحقل مطلوب';
    }
    
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.warning,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}