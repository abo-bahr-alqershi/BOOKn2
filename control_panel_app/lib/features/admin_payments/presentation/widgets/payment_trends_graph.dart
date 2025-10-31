import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_analytics/payment_analytics_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../domain/entities/payment_analytics.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';

class PaymentTrendsGraph extends StatefulWidget {
  final List<PaymentTrend> trends;
  final ChartType chartType;
  final List<String> selectedMetrics;
  final double height;

  const PaymentTrendsGraph({
    super.key,
    required this.trends,
    required this.chartType,
    required this.selectedMetrics,
    this.height = 300,
  });

  @override
  State<PaymentTrendsGraph> createState() => _PaymentTrendsGraphState();
}

class _PaymentTrendsGraphState extends State<PaymentTrendsGraph>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.8),
            AppTheme.darkCard.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return _buildChart();
        },
      ),
    );
  }

  Widget _buildChart() {
    switch (widget.chartType) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.area:
        return _buildAreaChart();
      default:
        return _buildLineChart();
    }
  }

  Widget _buildLineChart() {
    final spots = <String, List<FlSpot>>{};

    for (final metric in widget.selectedMetrics) {
      spots[metric] = [];
      for (int i = 0; i < widget.trends.length && i < 12; i++) {
        final trend = widget.trends[i];
        double value = 0;

        switch (metric) {
          case 'revenue':
            value = trend.totalAmount.amount;
            break;
          case 'transactions':
            value = trend.transactionCount.toDouble();
            break;
          case 'success_rate':
            value = trend.successRate;
            break;
        }

        spots[metric]!.add(FlSpot(i.toDouble(), value * _animation.value));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 11,
        lineBarsData: spots.entries.map((entry) {
          return LineChartBarData(
            spots: entry.value,
            isCurved: true,
            gradient: _getMetricGradient(entry.key),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getMetricColor(entry.key).withValues(alpha: 0.2),
                  _getMetricColor(entry.key).withValues(alpha: 0.0),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart() {
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < widget.trends.length && i < 12; i++) {
      final trend = widget.trends[i];
      final bars = <BarChartRodData>[];

      int barIndex = 0;
      for (final metric in widget.selectedMetrics) {
        double value = 0;

        switch (metric) {
          case 'revenue':
            value = trend.totalAmount.amount / 1000; // Convert to K
            break;
          case 'transactions':
            value = trend.transactionCount.toDouble();
            break;
          case 'success_rate':
            value = trend.successRate;
            break;
        }

        bars.add(
          BarChartRodData(
            toY: value * _animation.value,
            gradient: _getMetricGradient(metric),
            width: 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        );
        barIndex++;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: bars,
          barsSpace: 4,
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.darkCard,
            // fl_chart 0.69 removed tooltipRoundedRadius, borderRadius is used in decoration
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final metric = widget.selectedMetrics[rodIndex];
              return BarTooltipItem(
                '${_getMetricLabel(metric)}\n${rod.toY.toStringAsFixed(1)}',
                AppTextStyles.caption.copyWith(
                  color: AppTheme.textWhite,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAreaChart() {
    final spots = <FlSpot>[];

    for (int i = 0; i < widget.trends.length && i < 12; i++) {
      final trend = widget.trends[i];
      spots.add(FlSpot(
        i.toDouble(),
        trend.totalAmount.amount * _animation.value,
      ));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 11,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: AppTheme.primaryGradient,
            barWidth: 0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.5),
                  AppTheme.primaryPurple.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= 0 && value.toInt() < 12) {
              final months = [
                'ينا',
                'فبر',
                'مار',
                'أبر',
                'ماي',
                'يون',
                'يول',
                'أغس',
                'سبت',
                'أكت',
                'نوف',
                'ديس'
              ];
              return Text(
                months[value.toInt()],
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              '${value.toInt()}',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  LinearGradient _getMetricGradient(String metric) {
    switch (metric) {
      case 'revenue':
        return LinearGradient(
          colors: [AppTheme.success, AppTheme.success.withValues(alpha: 0.7)],
        );
      case 'transactions':
        return LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withValues(alpha: 0.7)
          ],
        );
      case 'success_rate':
        return LinearGradient(
          colors: [
            AppTheme.primaryPurple,
            AppTheme.primaryPurple.withValues(alpha: 0.7)
          ],
        );
      default:
        return AppTheme.primaryGradient;
    }
  }

  Color _getMetricColor(String metric) {
    switch (metric) {
      case 'revenue':
        return AppTheme.success;
      case 'transactions':
        return AppTheme.primaryBlue;
      case 'success_rate':
        return AppTheme.primaryPurple;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _getMetricLabel(String metric) {
    switch (metric) {
      case 'revenue':
        return 'الإيرادات';
      case 'transactions':
        return 'المعاملات';
      case 'success_rate':
        return 'معدل النجاح';
      default:
        return metric;
    }
  }
}
