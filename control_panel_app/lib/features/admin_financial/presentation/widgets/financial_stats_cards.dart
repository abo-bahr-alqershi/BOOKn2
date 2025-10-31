// lib/features/admin_financial/presentation/widgets/futuristic_financial_stats.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/financial_report.dart';

class FinancialStatsCards extends StatefulWidget {
  final FinancialReport report;

  const FinancialStatsCards({
    super.key,
    required this.report,
  });

  @override
  State<FinancialStatsCards> createState() => _FinancialStatsCardsState();
}

class _FinancialStatsCardsState extends State<FinancialStatsCards>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          // Mobile: Single Column
          return _buildMobileLayout();
        } else if (constraints.maxWidth < 800) {
          // Tablet: 2 Columns
          return _buildTabletLayout();
        } else {
          // Desktop: 4 Columns
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return SizedBox(
      height: 280,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _buildStatCard(
            title: 'إجمالي الإيرادات',
            value: widget.report.totalRevenue,
            icon: CupertinoIcons.arrow_up_circle_fill,
            gradient: [AppTheme.success, AppTheme.neonGreen],
            percentage: _calculateGrowthPercentage(widget.report.totalRevenue),
            index: 0,
            width: 150,
          ),
          _buildStatCard(
            title: 'إجمالي المصروفات',
            value: widget.report.totalExpenses,
            icon: CupertinoIcons.arrow_down_circle_fill,
            gradient: [AppTheme.error, AppTheme.error.withOpacity(0.7)],
            percentage: _calculateGrowthPercentage(widget.report.totalExpenses),
            isNegative: true,
            index: 1,
            width: 150,
          ),
          _buildStatCard(
            title: 'صافي الأرباح',
            value: widget.report.netProfit,
            icon: CupertinoIcons.money_dollar_circle_fill,
            gradient: widget.report.isProfitable
                ? [AppTheme.primaryCyan, AppTheme.primaryBlue]
                : [AppTheme.warning, AppTheme.warning.withOpacity(0.7)],
            percentage: widget.report.profitMargin,
            index: 2,
            width: 150,
          ),
          _buildStatCard(
            title: 'العمولات',
            value: widget.report.totalCommissions,
            icon: CupertinoIcons.percent,
            gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
            percentage: widget.report.commissionRate,
            index: 3,
            width: 150,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'إجمالي الإيرادات',
          value: widget.report.totalRevenue,
          icon: CupertinoIcons.arrow_up_circle_fill,
          gradient: [AppTheme.success, AppTheme.neonGreen],
          percentage: _calculateGrowthPercentage(widget.report.totalRevenue),
          index: 0,
        ),
        _buildStatCard(
          title: 'إجمالي المصروفات',
          value: widget.report.totalExpenses,
          icon: CupertinoIcons.arrow_down_circle_fill,
          gradient: [AppTheme.error, AppTheme.error.withOpacity(0.7)],
          percentage: _calculateGrowthPercentage(widget.report.totalExpenses),
          isNegative: true,
          index: 1,
        ),
        _buildStatCard(
          title: 'صافي الأرباح',
          value: widget.report.netProfit,
          icon: CupertinoIcons.money_dollar_circle_fill,
          gradient: widget.report.isProfitable
              ? [AppTheme.primaryCyan, AppTheme.primaryBlue]
              : [AppTheme.warning, AppTheme.warning.withOpacity(0.7)],
          percentage: widget.report.profitMargin,
          index: 2,
        ),
        _buildStatCard(
          title: 'العمولات',
          value: widget.report.totalCommissions,
          icon: CupertinoIcons.percent,
          gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
          percentage: widget.report.commissionRate,
          index: 3,
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'إجمالي الإيرادات',
            value: widget.report.totalRevenue,
            icon: CupertinoIcons.arrow_up_circle_fill,
            gradient: [AppTheme.success, AppTheme.neonGreen],
            percentage: _calculateGrowthPercentage(widget.report.totalRevenue),
            index: 0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'إجمالي المصروفات',
            value: widget.report.totalExpenses,
            icon: CupertinoIcons.arrow_down_circle_fill,
            gradient: [AppTheme.error, AppTheme.error.withOpacity(0.7)],
            percentage: _calculateGrowthPercentage(widget.report.totalExpenses),
            isNegative: true,
            index: 1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'صافي الأرباح',
            value: widget.report.netProfit,
            icon: CupertinoIcons.money_dollar_circle_fill,
            gradient: widget.report.isProfitable
                ? [AppTheme.primaryCyan, AppTheme.primaryBlue]
                : [AppTheme.warning, AppTheme.warning.withOpacity(0.7)],
            percentage: widget.report.profitMargin,
            index: 2,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'العمولات',
            value: widget.report.totalCommissions,
            icon: CupertinoIcons.percent,
            gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
            percentage: widget.report.commissionRate,
            index: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required double value,
    required IconData icon,
    required List<Color> gradient,
    required double percentage,
    bool isNegative = false,
    required int index,
    double? width,
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        horizontalOffset: 50,
        child: FadeInAnimation(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue =
                  math.sin(_pulseController.value * math.pi) * 0.02;

              return Transform.scale(
                scale: 1.0 + pulseValue,
                child: Container(
                  width: width,
                  height: 130,
                  margin: width != null
                      ? const EdgeInsets.symmetric(horizontal: 6)
                      : null,
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
                      color: gradient.first.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Stack(
                        children: [
                          // Background Pattern
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: gradient
                                      .map((c) => c.withOpacity(0.1))
                                      .toList(),
                                ),
                              ),
                            ),
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.textMuted,
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        gradient:
                                            LinearGradient(colors: gradient),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        icon,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),

                                // Value
                                Text(
                                  Formatters.formatCurrency(
                                    value,
                                    AppConstants.currencySymbol,
                                  ),
                                  style: AppTextStyles.heading2.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Percentage
                                _buildPercentageIndicator(
                                  percentage,
                                  isNegative,
                                  gradient.first,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageIndicator(
      double percentage, bool isNegative, Color baseColor) {
    final isPositive = percentage > 0;
    final color = isNegative
        ? (percentage < 0 ? AppTheme.success : AppTheme.error)
        : (percentage > 0 ? AppTheme.success : AppTheme.error);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? CupertinoIcons.arrow_up_right
                : CupertinoIcons.arrow_down_right,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '${percentage.abs().toStringAsFixed(1)}%',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getPeriodText(),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateGrowthPercentage(double currentValue) {
    // محاكاة حساب النسبة - يجب استبدالها بالبيانات الفعلية
    return ((currentValue * 0.12) / currentValue) * 100;
  }

  String _getPeriodText() {
    final days =
        widget.report.endDate.difference(widget.report.startDate).inDays;
    if (days <= 7) return 'أسبوع';
    if (days <= 30) return 'شهر';
    if (days <= 90) return '3 شهور';
    if (days <= 365) return 'سنة';
    return 'فترة';
  }
}
