// lib/features/admin_audit_logs/presentation/widgets/activity_chart_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/audit_log.dart';

class ActivityChartWidget extends StatefulWidget {
  final List<AuditLog> auditLogs;

  const ActivityChartWidget({
    super.key,
    required this.auditLogs,
  });

  @override
  State<ActivityChartWidget> createState() => _ActivityChartWidgetState();
}

class _ActivityChartWidgetState extends State<ActivityChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _chartAnimation;

  String _selectedPeriod = 'week';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withValues(alpha: 0.6),
                AppTheme.darkCard.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                  _buildHeader(isCompact),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildChart(isCompact),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: isCompact ? 32 : 36,
                height: isCompact ? 32 : 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withValues(alpha: 0.3),
                      AppTheme.primaryViolet.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.chart_bar_alt_fill,
                    color: AppTheme.primaryPurple,
                    size: isCompact ? 16 : 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليل النشاط',
                      style: (isCompact
                              ? AppTextStyles.bodyLarge
                              : AppTextStyles.heading3)
                          .copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    Text(
                      'إحصائيات الأنشطة حسب الفترة',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: isCompact ? 10 : 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilters(isCompact),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isCompact) {
    return Row(
      children: [
        Expanded(
          child: _buildPeriodSelector(isCompact),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTypeSelector(isCompact),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(bool isCompact) {
    return Container(
      height: isCompact ? 32 : 36,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'أسبوع',
            value: 'week',
            groupValue: _selectedPeriod,
            onChanged: (value) => setState(() => _selectedPeriod = value),
            isCompact: isCompact,
          ),
          _buildFilterChip(
            label: 'شهر',
            value: 'month',
            groupValue: _selectedPeriod,
            onChanged: (value) => setState(() => _selectedPeriod = value),
            isCompact: isCompact,
          ),
          _buildFilterChip(
            label: 'سنة',
            value: 'year',
            groupValue: _selectedPeriod,
            onChanged: (value) => setState(() => _selectedPeriod = value),
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool isCompact) {
    return Container(
      height: isCompact ? 32 : 36,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'الكل',
            value: 'all',
            groupValue: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value),
            isCompact: isCompact,
          ),
          _buildFilterChip(
            label: 'إضافة',
            value: 'create',
            groupValue: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value),
            isCompact: isCompact,
          ),
          _buildFilterChip(
            label: 'تحديث',
            value: 'update',
            groupValue: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value),
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required String groupValue,
    required Function(String) onChanged,
    required bool isCompact,
  }) {
    final isSelected = value == groupValue;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withValues(alpha: 0.3),
                      AppTheme.primaryViolet.withValues(alpha: 0.2),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppTheme.primaryPurple : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : null,
                fontSize: isCompact ? 10 : 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(bool isCompact) {
    final data = _prepareChartData();
    final maxValue =
        data.isEmpty ? 1 : data.map((e) => e.value).reduce(math.max);

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  final barHeight =
                      (item.value / maxValue) * _chartAnimation.value;

                  return Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: isCompact ? 2 : 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            item.value.toString(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                              fontSize: isCompact ? 9 : 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    item.color,
                                    item.color.withValues(alpha: 0.5),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.color.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: barHeight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        item.color,
                                        item.color.withValues(alpha: 0.7),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            Row(
              children: data.map((item) {
                return Expanded(
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: isCompact ? 1 : 0,
                      child: Text(
                        item.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: isCompact ? 8 : 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  List<ChartData> _prepareChartData() {
    // Simulate data preparation based on selected filters
    final now = DateTime.now();
    List<ChartData> data = [];

    if (_selectedPeriod == 'week') {
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final count = _getCountForDate(date);
        data.add(ChartData(
          label: _getDayLabel(date),
          value: count,
          color: _getColorForValue(count),
        ));
      }
    } else if (_selectedPeriod == 'month') {
      for (int i = 3; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: i * 7));
        final count = _getCountForWeek(weekStart);
        data.add(ChartData(
          label: 'أسبوع ${4 - i}',
          value: count,
          color: _getColorForValue(count),
        ));
      }
    } else {
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final count = _getCountForMonth(month);
        data.add(ChartData(
          label: _getMonthLabel(month),
          value: count,
          color: _getColorForValue(count),
        ));
      }
    }

    return data;
  }

  int _getCountForDate(DateTime date) {
    return widget.auditLogs.where((log) {
      final logDate = log.timestamp;
      return logDate.year == date.year &&
          logDate.month == date.month &&
          logDate.day == date.day &&
          (_selectedType == 'all' || log.action.toLowerCase() == _selectedType);
    }).length;
  }

  int _getCountForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return widget.auditLogs.where((log) {
      return log.timestamp.isAfter(weekStart) &&
          log.timestamp.isBefore(weekEnd) &&
          (_selectedType == 'all' || log.action.toLowerCase() == _selectedType);
    }).length;
  }

  int _getCountForMonth(DateTime month) {
    return widget.auditLogs.where((log) {
      final logDate = log.timestamp;
      return logDate.year == month.year &&
          logDate.month == month.month &&
          (_selectedType == 'all' || log.action.toLowerCase() == _selectedType);
    }).length;
  }

  String _getDayLabel(DateTime date) {
    const days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    return days[date.weekday % 7];
  }

  String _getMonthLabel(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[date.month - 1];
  }

  Color _getColorForValue(int value) {
    if (value == 0) return AppTheme.textMuted.withValues(alpha: 0.3);
    if (value < 5) return AppTheme.primaryBlue;
    if (value < 10) return AppTheme.primaryPurple;
    if (value < 20) return AppTheme.warning;
    return AppTheme.success;
  }
}

class ChartData {
  final String label;
  final int value;
  final Color color;

  ChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}
