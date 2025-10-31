// lib/features/admin_financial/presentation/widgets/financial_summary_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/financial_report.dart';

class _RatioCardData {
  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;

  const _RatioCardData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
}

/// 📊 بطاقة الملخص المالي
class FinancialSummaryCard extends StatefulWidget {
  final FinancialSummary? summary;

  const FinancialSummaryCard({
    super.key,
    this.summary,
  });

  @override
  State<FinancialSummaryCard> createState() => _FinancialSummaryCardState();
}

class _FinancialSummaryCardState extends State<FinancialSummaryCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    );

    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );

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
    if (widget.summary == null) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.1, 0),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkCard.withOpacity(0.8),
                    AppTheme.darkCard.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildFinancialHealthIndicator(),
                      _buildRatiosGrid(),
                      _buildProfitabilityMetrics(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🎯 Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryCyan
                          .withOpacity(0.2 + _pulseController.value * 0.2),
                      AppTheme.primaryPurple
                          .withOpacity(0.2 + _pulseController.value * 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryCyan
                          .withOpacity(0.3 * _pulseController.value),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.chart_bar_square_fill,
                  color: AppTheme.primaryCyan,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الملخص المالي',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'المؤشرات والنسب المالية الرئيسية',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Health Status Badge
          _buildHealthBadge(),
        ],
      ),
    );
  }

  /// 🏥 Health Badge
  Widget _buildHealthBadge() {
    final isHealthy = widget.summary?.isFinanciallyHealthy ?? false;
    final color = isHealthy ? AppTheme.success : AppTheme.warning;
    final label = isHealthy ? 'صحة جيدة' : 'يحتاج تحسين';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Financial Health Indicator
  Widget _buildFinancialHealthIndicator() {
    final summary = widget.summary!;
    final healthScore = _calculateHealthScore(summary);
    final healthColor = _getHealthColor(healthScore);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مؤشر الصحة المالية',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular Progress
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 8.0,
                animation: true,
                animationDuration: 1500,
                percent: healthScore / 100,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${healthScore.toStringAsFixed(0)}%',
                      style: AppTextStyles.heading3.copyWith(
                        color: healthColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'النقاط',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: healthColor,
                backgroundColor: AppTheme.darkBorder.withOpacity(0.2),
                backgroundWidth: 4,
              ),

              const SizedBox(width: 24),

              // Health Metrics
              Expanded(
                child: Column(
                  children: [
                    _buildHealthMetric(
                      'السيولة',
                      summary.currentRatio,
                      1.5,
                      3.0,
                      'نسبة',
                    ),
                    const SizedBox(height: 8),
                    _buildHealthMetric(
                      'الديون',
                      summary.debtToEquityRatio,
                      0,
                      2.0,
                      'نسبة',
                      isInverted: true,
                    ),
                    const SizedBox(height: 8),
                    _buildHealthMetric(
                      'رأس المال العامل',
                      summary.workingCapital,
                      0,
                      summary.currentAssets,
                      'ريال',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Health Metric Row
  Widget _buildHealthMetric(
    String label,
    double value,
    double min,
    double max,
    String unit, {
    bool isInverted = false,
  }) {
    final percentage = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final adjustedPercentage = isInverted ? 1.0 - percentage : percentage;
    final color = _getMetricColor(adjustedPercentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                unit == 'ريال'
                    ? CurrencyFormatter.formatCompact(value)
                    : '${value.toStringAsFixed(2)} $unit',
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                softWrap: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 6.0,
          percent: adjustedPercentage,
          backgroundColor: AppTheme.darkBorder.withOpacity(0.2),
          progressColor: color,
          barRadius: const Radius.circular(3),
          animation: true,
          animationDuration: 1000,
        ),
      ],
    );
  }

  /// 📊 Ratios Grid
  Widget _buildRatiosGrid() {
    final summary = widget.summary!;
    final ratioCards = <_RatioCardData>[
      _RatioCardData(
        label: 'نسبة التداول',
        value: summary.currentRatio,
        unit: 'مرة',
        icon: CupertinoIcons.arrow_2_circlepath,
        color: AppTheme.primaryCyan,
      ),
      _RatioCardData(
        label: 'نسبة السيولة السريعة',
        value: summary.quickRatio,
        unit: 'مرة',
        icon: CupertinoIcons.bolt_circle_fill,
        color: AppTheme.neonBlue,
      ),
      _RatioCardData(
        label: 'العائد على الأصول',
        value: summary.returnOnAssets,
        unit: '%',
        icon: CupertinoIcons.chart_bar_circle_fill,
        color: AppTheme.success,
      ),
      _RatioCardData(
        label: 'العائد على حقوق الملكية',
        value: summary.returnOnEquity,
        unit: '%',
        icon: CupertinoIcons.chart_pie_fill,
        color: AppTheme.primaryPurple,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          const spacing = 12.0;
          final useTwoColumns = availableWidth >= 520;
          final itemWidth =
              useTwoColumns ? (availableWidth - spacing) / 2 : availableWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'النسب المالية',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: spacing,
                runSpacing: 12,
                children: ratioCards.map((card) {
                  return SizedBox(
                    width: itemWidth,
                    child: _buildRatioCard(
                      card.label,
                      card.value,
                      card.unit,
                      card.icon,
                      card.color,
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 📊 Ratio Card
  Widget _buildRatioCard(
    String label,
    double value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📈 Profitability Metrics
  Widget _buildProfitabilityMetrics() {
    final summary = widget.summary!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مؤشرات الربحية',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProfitMetric(
                  'هامش الربح الإجمالي',
                  summary.grossProfitMargin,
                  CupertinoIcons.chart_bar_alt_fill,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfitMetric(
                  'هامش الربح الصافي',
                  summary.netProfitMargin,
                  CupertinoIcons.graph_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfitMetric(
                  'هامش الربح التشغيلي',
                  summary.operatingProfitMargin,
                  CupertinoIcons.gear_alt_fill,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Profit Metric
  Widget _buildProfitMetric(String label, double value, IconData icon) {
    final color = value > 20
        ? AppTheme.success
        : value > 10
            ? AppTheme.warning
            : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 🔍 Empty State
  Widget _buildEmptyState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.darkBorder.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.chart_bar_square,
                color: AppTheme.textMuted,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد بيانات مالية',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم تحديث الملخص المالي قريباً',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Calculate Health Score
  double _calculateHealthScore(FinancialSummary summary) {
    double score = 0;

    // Current Ratio (25 points)
    if (summary.currentRatio > 2)
      score += 25;
    else if (summary.currentRatio > 1.5)
      score += 20;
    else if (summary.currentRatio > 1) score += 10;

    // Debt to Equity (25 points)
    if (summary.debtToEquityRatio < 0.5)
      score += 25;
    else if (summary.debtToEquityRatio < 1)
      score += 20;
    else if (summary.debtToEquityRatio < 1.5) score += 10;

    // Net Profit Margin (25 points)
    if (summary.netProfitMargin > 20)
      score += 25;
    else if (summary.netProfitMargin > 10)
      score += 20;
    else if (summary.netProfitMargin > 5) score += 10;

    // ROE (25 points)
    if (summary.returnOnEquity > 20)
      score += 25;
    else if (summary.returnOnEquity > 15)
      score += 20;
    else if (summary.returnOnEquity > 10) score += 10;

    return score.clamp(0, 100);
  }

  /// 🎨 Get Health Color
  Color _getHealthColor(double score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.primaryCyan;
    if (score >= 40) return AppTheme.warning;
    return AppTheme.error;
  }

  /// 🎨 Get Metric Color
  Color _getMetricColor(double percentage) {
    if (percentage >= 0.75) return AppTheme.success;
    if (percentage >= 0.5) return AppTheme.primaryCyan;
    if (percentage >= 0.25) return AppTheme.warning;
    return AppTheme.error;
  }
}
