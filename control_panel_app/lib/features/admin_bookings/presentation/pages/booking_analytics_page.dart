// lib/features/admin_bookings/presentation/pages/booking_analytics_page.dart

import 'package:bookn_cp_app/features/admin_bookings/domain/entities/booking_trends.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/formatters.dart';
import '../bloc/booking_analytics/booking_analytics_bloc.dart';
import '../bloc/booking_analytics/booking_analytics_event.dart';
import '../bloc/booking_analytics/booking_analytics_state.dart';
import '../widgets/booking_analytics_charts.dart';
import '../widgets/booking_stats_cards.dart';

class BookingAnalyticsPage extends StatefulWidget {
  const BookingAnalyticsPage({super.key});

  @override
  State<BookingAnalyticsPage> createState() => _BookingAnalyticsPageState();
}

class _BookingAnalyticsPageState extends State<BookingAnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late TabController _tabController;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
    _animationController.forward();
  }

  void _loadAnalytics() {
    final now = DateTime.now();
    final startDate = _getStartDateForPeriod(_selectedPeriod);

    context.read<BookingAnalyticsBloc>().add(
          LoadBookingAnalyticsEvent(
            startDate: startDate,
            endDate: now,
          ),
        );
  }

  DateTime _getStartDateForPeriod(AnalyticsPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case AnalyticsPeriod.day:
        return DateTime(now.year, now.month, now.day);
      case AnalyticsPeriod.week:
        return now.subtract(const Duration(days: 7));
      case AnalyticsPeriod.month:
        return DateTime(now.year, now.month - 1, now.day);
      case AnalyticsPeriod.quarter:
        return DateTime(now.year, now.month - 3, now.day);
      case AnalyticsPeriod.year:
        return DateTime(now.year - 1, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocBuilder<BookingAnalyticsBloc, BookingAnalyticsState>(
        builder: (context, state) {
          if (state is BookingAnalyticsLoading) {
            return const LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل التحليلات...',
            );
          }

          if (state is BookingAnalyticsError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: _loadAnalytics,
            );
          }

          if (state is BookingAnalyticsLoaded) {
            return _buildContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BookingAnalyticsLoaded state) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        _buildPeriodSelector(),
        _buildKPICards(state),
        _buildTabBar(),
        _buildTabContent(state),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'تحليلات الحجوزات',
          style: AppTextStyles.heading1.copyWith(
            color: AppTheme.textWhite,
            shadows: [
              Shadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryPurple.withOpacity(0.1),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.square_arrow_down),
          onPressed: _exportReport,
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.arrow_2_circlepath),
          onPressed: _loadAnalytics,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: AnalyticsPeriod.values.map((period) {
            final isSelected = _selectedPeriod == period;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_getPeriodLabel(period)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPeriod = period);
                    context.read<BookingAnalyticsBloc>().add(
                          ChangePeriodEvent(period: period),
                        );
                  }
                },
                selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                backgroundColor: AppTheme.darkCard,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.darkBorder.withOpacity(0.3),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKPICards(BookingAnalyticsLoaded state) {
    return SliverToBoxAdapter(
      child: Container(
        height: 180,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildKPICard(
              title: 'إجمالي الحجوزات',
              value: state.kpis['totalBookings'].toString(),
              icon: CupertinoIcons.doc_text_fill,
              gradient: AppTheme.primaryGradient,
              trend: state.kpis['growthRate'] as double? ?? 0,
            ),
            _buildKPICard(
              title: 'الإيرادات',
              value: Formatters.formatCurrency(
                state.kpis['totalRevenue'] as double? ?? 0,
                'YER',
              ),
              icon: CupertinoIcons.money_dollar_circle_fill,
              gradient: LinearGradient(
                colors: [AppTheme.success, AppTheme.success.withOpacity(0.6)],
              ),
              trend: 15.3,
            ),
            _buildKPICard(
              title: 'معدل الإشغال',
              value:
                  '${state.kpis['occupancyRate']?.toStringAsFixed(1) ?? '0'}%',
              icon: CupertinoIcons.chart_pie_fill,
              gradient: LinearGradient(
                colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.6)],
              ),
              trend: -5.2,
            ),
            _buildKPICard(
              title: 'متوسط الإقامة',
              value:
                  '${state.kpis['averageStayLength']?.toStringAsFixed(1) ?? '0'} ليلة',
              icon: CupertinoIcons.moon_fill,
              gradient: LinearGradient(
                colors: [AppTheme.info, AppTheme.info.withOpacity(0.6)],
              ),
              trend: 8.7,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required double trend,
  }) {
    final isPositive = trend >= 0;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              icon,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: AppTextStyles.heading1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? CupertinoIcons.arrow_up_right
                            : CupertinoIcons.arrow_down_right,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trend.abs().toStringAsFixed(1)}%',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'الاتجاهات'),
            Tab(text: 'المصادر'),
            Tab(text: 'المقارنات'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BookingAnalyticsLoaded state) {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(state),
          _buildTrendsTab(state),
          _buildSourcesTab(state),
          _buildComparisonsTab(state),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BookingAnalyticsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BookingAnalyticsCharts(
        report: state.report,
        trends: state.trends,
        windowAnalysis: state.windowAnalysis,
      ),
    );
  }

  Widget _buildTrendsTab(BookingAnalyticsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTrendChart(
            title: 'اتجاه الحجوزات',
            data: state.trends.bookingTrends,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 24),
          _buildTrendChart(
            title: 'اتجاه الإيرادات',
            data: state.trends.revenueTrends,
            color: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart({
    required String title,
    required List<TimeSeriesData> data,
    required Color color,
  }) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.darkBorder.withOpacity(0.1),
                      strokeWidth: 1,
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
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Text(
                            _formatChartDate(data[value.toInt()].date),
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
                      interval: 1,
                      reservedSize: 42,
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
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: data.length.toDouble() - 1,
                minY: 0,
                maxY: data.map((e) => e.value).reduce((a, b) => a > b ? a : b) *
                    1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.value);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.8),
                        color,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.1),
                          color.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesTab(BookingAnalyticsLoaded state) {
    final sources = state.report.summary.bookingsBySource;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPieChart(
            title: 'مصادر الحجوزات',
            data: sources,
          ),
          const SizedBox(height: 24),
          ...sources.entries.map((entry) {
            return _buildSourceCard(
              source: entry.key,
              count: entry.value,
              total: sources.values.reduce((a, b) => a + b),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPieChart({
    required String title,
    required Map<String, int> data,
  }) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _generatePieSections(data),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(Map<String, int> data) {
    final total = data.values.reduce((a, b) => a + b);
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
      AppTheme.success,
      AppTheme.warning,
    ];

    return data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = (item.value / total) * 100;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: item.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildSourceCard({
    required String source,
    required int count,
    required int total,
  }) {
    final percentage = (count / total) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getSourceIcon(source),
              color: AppTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSourceLabel(source),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: AppTheme.darkBorder.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count.toString(),
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonsTab(BookingAnalyticsLoaded state) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chart_bar_alt_fill,
              size: 80,
              color: AppTheme.textMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'المقارنات',
              style: AppTextStyles.heading2.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'قارن بين فترات زمنية مختلفة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showComparisonDialog,
              icon: const Icon(CupertinoIcons.arrow_2_circlepath),
              label: const Text('بدء المقارنة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.day:
        return 'اليوم';
      case AnalyticsPeriod.week:
        return 'الأسبوع';
      case AnalyticsPeriod.month:
        return 'الشهر';
      case AnalyticsPeriod.quarter:
        return 'الربع';
      case AnalyticsPeriod.year:
        return 'السنة';
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source.toLowerCase()) {
      case 'website':
        return CupertinoIcons.globe;
      case 'mobile':
        return CupertinoIcons.phone;
      case 'walkin':
        return CupertinoIcons.person_2;
      default:
        return CupertinoIcons.square_grid_2x2;
    }
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

  String _formatChartDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  void _exportReport() {
    context.read<BookingAnalyticsBloc>().add(
          const ExportAnalyticsReportEvent(format: ExportFormat.pdf),
        );
  }

  void _showComparisonDialog() {
    // Implement comparison dialog
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.darkBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
