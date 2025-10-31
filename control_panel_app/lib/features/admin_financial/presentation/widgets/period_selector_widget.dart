// lib/features/admin_financial/presentation/widgets/period_selector_widget.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 📅 ويدجت محدد الفترة الزمنية
class PeriodSelectorWidget extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime)? onPeriodChanged;

  const PeriodSelectorWidget({
    super.key,
    required this.startDate,
    required this.endDate,
    this.onPeriodChanged,
  });

  @override
  State<PeriodSelectorWidget> createState() => _PeriodSelectorWidgetState();
}

class _PeriodSelectorWidgetState extends State<PeriodSelectorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  String _selectedPeriod = 'custom';
  late DateTime _startDate;
  late DateTime _endDate;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _detectSelectedPeriod();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _detectSelectedPeriod() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);
    
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    
    if (start == today && end == today) {
      _selectedPeriod = 'today';
    } else if (start == today.subtract(const Duration(days: 6)) && end == today) {
      _selectedPeriod = 'week';
    } else if (start == today.subtract(const Duration(days: 29)) && end == today) {
      _selectedPeriod = 'month';
    } else if (start == startOfMonth && end == today) {
      _selectedPeriod = 'thisMonth';
    } else if (start == today.subtract(const Duration(days: 89)) && end == today) {
      _selectedPeriod = 'quarter';
    } else if (start == startOfYear && end == today) {
      _selectedPeriod = 'year';
    } else {
      _selectedPeriod = 'custom';
    }
  }

  void _selectPeriod(String period) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedPeriod = period;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      switch (period) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = today;
          break;
        case 'week':
          _startDate = today.subtract(const Duration(days: 6));
          _endDate = today;
          break;
        case 'month':
          _startDate = today.subtract(const Duration(days: 29));
          _endDate = today;
          break;
        case 'thisMonth':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = today;
          break;
        case 'quarter':
          _startDate = today.subtract(const Duration(days: 89));
          _endDate = today;
          break;
        case 'year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = today;
          break;
      }
      
      if (period != 'custom') {
        widget.onPeriodChanged?.call(_startDate, _endDate);
      }
    });
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('ar', 'SA'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryCyan,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhite,
            ),
            dialogBackgroundColor: AppTheme.darkCard,
            textTheme: TextTheme(
              headlineMedium: AppTextStyles.heading3.copyWith(color: AppTheme.textWhite),
              bodyLarge: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textLight),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'custom';
      });
      widget.onPeriodChanged?.call(_startDate, _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main Period Display
                _buildMainDisplay(),
                
                // Period Options (Expandable)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded ? _buildPeriodOptions() : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎯 Main Display
  Widget _buildMainDisplay() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isExpanded = !_isExpanded;
          if (_isExpanded) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryCyan.withOpacity(0.1),
              AppTheme.primaryPurple.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryCyan.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Calendar Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.calendar,
                color: AppTheme.primaryCyan,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Date Range Display
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPeriodLabel(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatDate(_startDate),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' - ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _formatDate(_endDate),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Expand/Collapse Icon
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                CupertinoIcons.chevron_down,
                color: AppTheme.primaryCyan,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Period Options
  Widget _buildPeriodOptions() {
    return Column(
      children: [
        const SizedBox(height: 16),
        
        // Quick Select Buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPeriodChip('اليوم', 'today', CupertinoIcons.sun_max_fill),
            _buildPeriodChip('أسبوع', 'week', CupertinoIcons.calendar_today),
            _buildPeriodChip('شهر', 'month', CupertinoIcons.calendar),
            _buildPeriodChip('هذا الشهر', 'thisMonth', CupertinoIcons.calendar_badge_plus),
            _buildPeriodChip('ربع سنة', 'quarter', CupertinoIcons.chart_bar_square),
            _buildPeriodChip('سنة', 'year', CupertinoIcons.calendar_circle),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Custom Date Range Button
        GestureDetector(
          onTap: _selectCustomDateRange,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: _selectedPeriod == 'custom'
                  ? AppTheme.primaryGradient
                  : LinearGradient(
                      colors: [
                        AppTheme.darkBackground.withOpacity(0.5),
                        AppTheme.darkBackground.withOpacity(0.3),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedPeriod == 'custom'
                    ? AppTheme.primaryCyan.withOpacity(0.5)
                    : AppTheme.darkBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.calendar_badge_plus,
                  color: _selectedPeriod == 'custom'
                      ? Colors.white
                      : AppTheme.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'تحديد فترة مخصصة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _selectedPeriod == 'custom'
                        ? Colors.white
                        : AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 📅 Period Chip
  Widget _buildPeriodChip(String label, String value, IconData icon) {
    final isSelected = _selectedPeriod == value;
    
    return GestureDetector(
      onTap: () => _selectPeriod(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryCyan.withOpacity(0.3),
                    AppTheme.primaryPurple.withOpacity(0.3),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.darkBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryCyan.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryCyan : AppTheme.textMuted,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppTheme.textWhite : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'اليوم';
      case 'week':
        return 'آخر 7 أيام';
      case 'month':
        return 'آخر 30 يوم';
      case 'thisMonth':
        return 'الشهر الحالي';
      case 'quarter':
        return 'آخر 3 شهور';
      case 'year':
        return 'السنة الحالية';
      case 'custom':
        return 'فترة مخصصة';
      default:
        return 'اختر الفترة';
    }
  }

  String _formatDate(DateTime date) {
    return intl.DateFormat('dd MMM yyyy', 'ar').format(date);
  }
}
