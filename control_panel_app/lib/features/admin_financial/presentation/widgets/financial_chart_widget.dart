// lib/features/admin_financial/presentation/widgets/financial_chart_widget.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/financial_report.dart';

/// 📊 ويدجت الرسوم البيانية المالية
class FinancialChartWidget extends StatefulWidget {
  final List<ChartData> chartData;
  final String chartType; // revenue, expense, cashflow
  final bool isFullScreen;
  final VoidCallback? onToggleFullScreen;

  const FinancialChartWidget({
    super.key,
    required this.chartData,
    required this.chartType,
    this.isFullScreen = false,
    this.onToggleFullScreen,
  });

  @override
  State<FinancialChartWidget> createState() => _FinancialChartWidgetState();
}

class _FinancialChartWidgetState extends State<FinancialChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rotationController;
  late Animation<double> _animation;
  
  int? _touchedIndex;
  double? _touchedValue;
  
  // Chart type: 0 = Bar, 1 = Line, 2 = Pie
  int _currentChartType = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    
    _animationController.forward();
    
    // Set default chart type based on data type
    if (widget.chartType == 'cashflow') {
      _currentChartType = 1; // Line chart for cash flow
    } else if (widget.chartType == 'expense') {
      _currentChartType = 2; // Pie chart for expenses
    } else {
      _currentChartType = 0; // Bar chart for revenue
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Chart Content
        Column(
          children: [
            // Chart Controls
            _buildChartControls(),
            
            const SizedBox(height: 20),
            
            // Chart
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildChart(),
              ),
            ),
          ],
        ),
        
        // Full Screen Toggle
        if (widget.onToggleFullScreen != null)
          Positioned(
            top: 0,
            right: 0,
            child: _buildFullScreenButton(),
          ),
      ],
    );
  }

  /// 🎮 Chart Controls
  Widget _buildChartControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChartTypeButton(
          icon: CupertinoIcons.chart_bar_fill,
          label: 'أعمدة',
          index: 0,
        ),
        const SizedBox(width: 12),
        _buildChartTypeButton(
          icon: CupertinoIcons.graph_circle,
          label: 'خطي',
          index: 1,
        ),
        const SizedBox(width: 12),
        _buildChartTypeButton(
          icon: CupertinoIcons.chart_pie_fill,
          label: 'دائري',
          index: 2,
        ),
      ],
    );
  }

  Widget _buildChartTypeButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentChartType == index;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _currentChartType = index;
          _animationController.forward(from: 0);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryCyan.withOpacity(0.3),
                    AppTheme.primaryPurple.withOpacity(0.3),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.darkCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
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
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppTheme.textWhite : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Build Chart based on type
  Widget _buildChart() {
    switch (_currentChartType) {
      case 0:
        return _buildBarChart();
      case 1:
        return _buildLineChart();
      case 2:
        return _buildPieChart();
      default:
        return _buildBarChart();
    }
  }

  /// 📊 Bar Chart
  Widget _buildBarChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _getMaxValue() * 1.2,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(12),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${widget.chartData[groupIndex].label}\n',
                    AppTextStyles.caption.copyWith(
                      color: AppTheme.textWhite,
                    ),
                    children: [
                      TextSpan(
                        text: CurrencyFormatter.format(rod.toY),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.primaryCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      barTouchResponse == null ||
                      barTouchResponse.spot == null) {
                    _touchedIndex = null;
                    _touchedValue = null;
                    return;
                  }
                  _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                  _touchedValue = barTouchResponse.spot!.touchedRodData.toY;
                });
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= widget.chartData.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.chartData[index].label,
                        style: AppTextStyles.caption.copyWith(
                          color: _touchedIndex == index
                              ? AppTheme.primaryCyan
                              : AppTheme.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 80,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      CurrencyFormatter.formatCompact(value),
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: _getMaxValue() / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppTheme.darkBorder.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: widget.chartData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final isTouched = index == _touchedIndex;
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data.value * _animation.value,
                    width: widget.isFullScreen ? 24 : 20,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _getGradientColors(data, isTouched),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: _getMaxValue(),
                      color: AppTheme.darkBorder.withOpacity(0.05),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// 📈 Line Chart
  Widget _buildLineChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            minX: 0,
            maxX: (widget.chartData.length - 1).toDouble(),
            minY: 0,
            maxY: _getMaxValue() * 1.2,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(12),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    return LineTooltipItem(
                      '${widget.chartData[touchedSpot.x.toInt()].label}\n',
                      AppTextStyles.caption.copyWith(
                        color: AppTheme.textWhite,
                      ),
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.format(touchedSpot.y),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.primaryCyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: AppTheme.primaryCyan.withOpacity(0.3),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: AppTheme.primaryCyan,
                          strokeWidth: 2,
                          strokeColor: AppTheme.darkBackground,
                        );
                      },
                    ),
                  );
                }).toList();
              },
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: _getMaxValue() / 5,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppTheme.darkBorder.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: AppTheme.darkBorder.withOpacity(0.05),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= widget.chartData.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.chartData[index].label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 80,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      CurrencyFormatter.formatCompact(value),
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: widget.chartData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.value * _animation.value,
                  );
                }).toList(),
                isCurved: true,
                curveSmoothness: 0.4,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryCyan,
                    AppTheme.primaryPurple,
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: AppTheme.primaryCyan,
                      strokeWidth: 1.5,
                      strokeColor: AppTheme.darkBackground,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryCyan.withOpacity(0.3),
                      AppTheme.primaryPurple.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🥧 Pie Chart
  Widget _buildPieChart() {
    final total = widget.chartData.fold(0.0, (sum, data) => sum + data.value);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * math.pi * 0.05,
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: widget.isFullScreen ? 80 : 60,
                  sections: _buildPieSections(total),
                ),
              );
            },
          ),
        ),
        
        // Center Text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الإجمالي',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                CurrencyFormatter.formatCompact(total),
                style: AppTextStyles.heading3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(double total) {
    return widget.chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == _touchedIndex;
      final percentage = (data.value / total) * 100;
      final radius = widget.isFullScreen
          ? (isTouched ? 120.0 : 100.0)
          : (isTouched ? 80.0 : 60.0);
      
      // Generate color from data or use default gradient
      final color = data.color != null
          ? Color(int.parse(data.color!.replaceFirst('#', '0xFF')))
          : _getPieColor(index);
      
      return PieChartSectionData(
        color: color,
        value: data.value * _animation.value,
        title: isTouched
            ? '${percentage.toStringAsFixed(1)}%'
            : percentage > 5
                ? '${percentage.toStringAsFixed(0)}%'
                : '',
        radius: radius,
        titleStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isTouched ? 14 : 12,
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatCompact(data.value),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  /// 🎨 Get gradient colors for bar
  List<Color> _getGradientColors(ChartData data, bool isTouched) {
    if (data.color != null) {
      final color = Color(int.parse(data.color!.replaceFirst('#', '0xFF')));
      return [
        color.withOpacity(isTouched ? 1.0 : 0.8),
        color.withOpacity(isTouched ? 0.8 : 0.6),
      ];
    }
    
    if (widget.chartType == 'revenue') {
      return [
        AppTheme.success.withOpacity(isTouched ? 1.0 : 0.8),
        AppTheme.success.withOpacity(isTouched ? 0.8 : 0.6),
      ];
    } else if (widget.chartType == 'expense') {
      return [
        AppTheme.error.withOpacity(isTouched ? 1.0 : 0.8),
        AppTheme.error.withOpacity(isTouched ? 0.8 : 0.6),
      ];
    } else {
      return [
        AppTheme.primaryCyan.withOpacity(isTouched ? 1.0 : 0.8),
        AppTheme.primaryPurple.withOpacity(isTouched ? 0.8 : 0.6),
      ];
    }
  }

  /// 🎨 Get pie chart color by index
  Color _getPieColor(int index) {
    final colors = [
      AppTheme.primaryCyan,
      AppTheme.primaryPurple,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.error,
      AppTheme.primaryViolet,
      AppTheme.neonGreen,
      AppTheme.neonBlue,
    ];
    return colors[index % colors.length];
  }

  /// 📏 Get maximum value from chart data
  double _getMaxValue() {
    if (widget.chartData.isEmpty) return 100;
    return widget.chartData.map((e) => e.value).reduce(math.max);
  }

  /// 🔳 Full Screen Button
  Widget _buildFullScreenButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onToggleFullScreen?.call();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(
              widget.isFullScreen
                  ? CupertinoIcons.fullscreen_exit
                  : CupertinoIcons.fullscreen,
              color: AppTheme.textLight,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
