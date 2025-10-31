// lib/features/admin_bookings/presentation/widgets/booking_analytics_charts.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/booking_report.dart';
import '../../domain/entities/booking_trends.dart';
import '../../domain/entities/booking_window_analysis.dart';

class BookingAnalyticsCharts extends StatefulWidget {
  final BookingReport report;
  final BookingTrends trends;
  final BookingWindowAnalysis? windowAnalysis;

  const BookingAnalyticsCharts({
    super.key,
    required this.report,
    required this.trends,
    this.windowAnalysis,
  });

  @override
  State<BookingAnalyticsCharts> createState() => _BookingAnalyticsChartsState();
}

class _BookingAnalyticsChartsState extends State<BookingAnalyticsCharts>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _chartAnimation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _chartAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRevenueChart(),
        const SizedBox(height: 24),
        _buildBookingTrendsChart(),
        const SizedBox(height: 24),
        _buildOccupancyChart(),
        if (widget.windowAnalysis != null) ...[
          const SizedBox(height: 24),
          _buildBookingWindowChart(),
        ],
        const SizedBox(height: 24),
        _buildSourcesChart(),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return _ChartContainer(
      title: 'الإيرادات',
      icon: CupertinoIcons.money_dollar_circle_fill,
      gradientColors: [AppTheme.success, AppTheme.success.withOpacity(0.7)],
      child: SizedBox(
        height: 250,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.darkBorder.withOpacity(0.1),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() <
                                widget.trends.revenueTrends.length) {
                          final date =
                              widget.trends.revenueTrends[value.toInt()].date;
                          return Text(
                            '${date.day}/${date.month}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1000,
                      reservedSize: 42,
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
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: widget.trends.revenueTrends.length.toDouble() - 1,
                minY: 0,
                maxY: widget.trends.revenueTrends
                        .map((e) => e.value)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: widget.trends.revenueTrends
                        .asMap()
                        .entries
                        .map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.value * _chartAnimation.value,
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.success.withOpacity(0.8),
                        AppTheme.success,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.success,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.success.withOpacity(0.2),
                          AppTheme.success.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppTheme.darkCard,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(0)} YER',
                          AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingTrendsChart() {
    return _ChartContainer(
      title: 'اتجاهات الحجوزات',
      icon: Icons.show_chart,
      gradientColors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
      child: SizedBox(
        height: 200,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: widget.trends.bookingTrends
                        .map((e) => e.value)
                        .reduce((a, b) => a > b ? a : b) *
                    1.3,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppTheme.darkCard,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(0)} حجز',
                        AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() <
                                widget.trends.bookingTrends.length) {
                          final date =
                              widget.trends.bookingTrends[value.toInt()].date;
                          return Text(
                            '${date.day}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.darkBorder.withOpacity(0.1),
                      strokeWidth: 1,
                      dashArray: [3, 3],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups:
                    widget.trends.bookingTrends.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value * _chartAnimation.value,
                        gradient: AppTheme.primaryGradient,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOccupancyChart() {
    final occupancyData = widget.trends.occupancyTrends;

    return _ChartContainer(
      title: 'معدل الإشغال',
      icon: CupertinoIcons.chart_pie_fill,
      gradientColors: [AppTheme.primaryCyan, AppTheme.primaryViolet],
      child: SizedBox(
        height: 200,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.darkBorder.withOpacity(0.1),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < occupancyData.length) {
                          final date = occupancyData[value.toInt()].date;
                          return Text(
                            '${date.day}/${date.month}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(0)}%',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: occupancyData.length.toDouble() - 1,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: occupancyData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.value * _chartAnimation.value,
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryCyan,
                        AppTheme.primaryViolet,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryCyan.withOpacity(0.2),
                          AppTheme.primaryViolet.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingWindowChart() {
    final windowData = widget.windowAnalysis!.segments;

    return _ChartContainer(
      title: 'نافذة الحجز',
      icon: CupertinoIcons.time,
      gradientColors: [AppTheme.warning, AppTheme.warning.withOpacity(0.7)],
      child: SizedBox(
        height: 200,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: windowData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final segment = entry.value;
                  final isTouched = index == _touchedIndex;
                  final fontSize = isTouched ? 16.0 : 12.0;
                  final radius =
                      (isTouched ? 80.0 : 70.0) * _chartAnimation.value;

                  return PieChartSectionData(
                    color: _getSegmentColor(index),
                    value: segment.percentage,
                    title: '${segment.percentage.toStringAsFixed(1)}%',
                    radius: radius,
                    titleStyle: AppTextStyles.caption.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: isTouched
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.shadowDark.withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  segment.name,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${segment.bookingsCount} حجز',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                    badgePositionPercentageOffset: 1.3,
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSourcesChart() {
    final sources = widget.report.summary.bookingsBySource;
    final total = sources.values.reduce((a, b) => a + b);

    return _ChartContainer(
      title: 'مصادر الحجوزات',
      icon: CupertinoIcons.globe,
      gradientColors: [AppTheme.info, AppTheme.info.withOpacity(0.7)],
      child: Column(
        children: sources.entries.map((entry) {
          final percentage = (entry.value / total) * 100;
          return _buildSourceBar(
            source: entry.key,
            count: entry.value,
            percentage: percentage,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSourceBar({
    required String source,
    required int count,
    required double percentage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getSourceLabel(source),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.darkBorder.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (percentage / 100) * _chartAnimation.value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getSegmentColor(int index) {
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
      AppTheme.success,
      AppTheme.warning,
    ];
    return colors[index % colors.length];
  }

  String _getSourceLabel(String source) {
    switch (source.toLowerCase()) {
      case 'website':
        return 'الموقع الإلكتروني';
      case 'mobile':
        return 'التطبيق';
      case 'walkin':
        return 'زيارة مباشرة';
      default:
        return source;
    }
  }
}

class _ChartContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final Widget child;

  const _ChartContainer({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                color: AppTheme.darkBorder.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradientColors[0].withOpacity(0.1),
                        gradientColors[1].withOpacity(0.05),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.darkBorder.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
