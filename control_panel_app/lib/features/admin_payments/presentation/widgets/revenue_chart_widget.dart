import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../../domain/entities/payment_analytics.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';

class RevenueChartWidget extends StatefulWidget {
  final List<PaymentTrend> data;
  final double height;

  const RevenueChartWidget({
    super.key,
    required this.data,
    this.height = 300,
  });

  @override
  State<RevenueChartWidget> createState() => _RevenueChartWidgetState();
}

class _RevenueChartWidgetState extends State<RevenueChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإيرادات',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'آخر 30 يوم',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.arrow_up_right,
                      color: AppTheme.textWhite,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+12.5%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: widget.data.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chart_bar,
                          size: 48,
                          color: AppTheme.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد بيانات للإيرادات',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سيتم عرض البيانات عند وجود مدفوعات',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return LineChart(
                        _buildChartData(),
                        duration: const Duration(milliseconds: 250),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    // Generate spots from data
    final spots = <FlSpot>[];
    for (int i = 0; i < widget.data.length && i < 30; i++) {
      spots.add(FlSpot(
        i.toDouble(),
        widget.data[i].totalAmount.amount * _animation.value,
      ));
    }

    // If no data, show zero line
    if (spots.isEmpty) {
      for (int i = 0; i < 7; i++) {
        spots.add(FlSpot(
          i.toDouble(),
          0,
        ));
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20000,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.darkBorder.withValues(alpha: 0.2),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 5,
            getTitlesWidget: (value, meta) {
              if (value.toInt() % 5 != 0) return const SizedBox();
              return Text(
                '${value.toInt()}',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                '${(value / 1000).toStringAsFixed(0)}K',
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
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: widget.data.isEmpty ? 6 : (widget.data.length - 1).toDouble(),
      minY: 0,
      maxY: spots.isEmpty || spots.every((e) => e.y == 0)
          ? 100000
          : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: AppTheme.primaryGradient,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: _touchedIndex == index ? 6 : 3,
                color: AppTheme.primaryBlue,
                strokeWidth: 2,
                strokeColor: AppTheme.textWhite,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.3),
                AppTheme.primaryBlue.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppTheme.darkCard,
          // fl_chart 0.69 removed tooltipRoundedRadius
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              return LineTooltipItem(
                '${(touchedSpot.y / 1000).toStringAsFixed(1)}K ر.ي',
                AppTextStyles.caption.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 8,
                    color: AppTheme.primaryBlue,
                    strokeWidth: 2,
                    strokeColor: AppTheme.textWhite,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
