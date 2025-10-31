import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_analytics/payment_analytics_bloc.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_analytics/payment_analytics_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../bloc/payment_analytics/payment_analytics_state.dart';
import '../widgets/payment_stats_cards.dart';
import '../widgets/revenue_chart_widget.dart';
import '../widgets/payment_trends_graph.dart';
import '../widgets/payment_breakdown_pie_chart.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_dimensions.dart';
import '../../../../../../core/widgets/loading_widget.dart';
import '../../../../../../core/widgets/error_widget.dart';

class PaymentAnalyticsPage extends StatefulWidget {
  const PaymentAnalyticsPage({super.key});

  @override
  State<PaymentAnalyticsPage> createState() => _PaymentAnalyticsPageState();
}

class _PaymentAnalyticsPageState extends State<PaymentAnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late TabController _tabController;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _tabController = TabController(length: 3, vsync: this);

    // Load analytics
    context.read<PaymentAnalyticsBloc>().add(
          const LoadPaymentAnalyticsEvent(),
        );
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
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildPeriodSelector(),
              _buildTabs(),
              Expanded(
                child: BlocBuilder<PaymentAnalyticsBloc, PaymentAnalyticsState>(
                  builder: (context, state) {
                    if (state is PaymentAnalyticsLoading) {
                      return const LoadingWidget(
                        type: LoadingType.futuristic,
                        message: 'جاري تحميل التحليلات...',
                      );
                    }

                    if (state is PaymentAnalyticsError) {
                      return CustomErrorWidget(
                        message: state.message,
                        type: ErrorType.general,
                        onRetry: () {
                          context.read<PaymentAnalyticsBloc>().add(
                                const RefreshAnalyticsEvent(),
                              );
                        },
                      );
                    }

                    if (state is PaymentAnalyticsLoaded) {
                      return _buildTabContent(state);
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      // padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                CupertinoIcons.arrow_right,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'تحليلات المدفوعات',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'رؤى تفصيلية حول الأداء المالي',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _exportReport,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.arrow_down_doc,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(
        vertical: 16,
        // horizontal: AppDimensions.paddingLarge,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
              });
              context.read<PaymentAnalyticsBloc>().add(
                    ChangePeriodEvent(period: period),
                  );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppTheme.darkBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _getPeriodText(period),
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      // margin: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppTheme.textWhite,
        unselectedLabelColor: AppTheme.textMuted,
        tabs: const [
          Tab(text: 'نظرة عامة'),
          Tab(text: 'الاتجاهات'),
          Tab(text: 'التفاصيل'),
        ],
      ),
    );
  }

  Widget _buildTabContent(PaymentAnalyticsLoaded state) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Overview Tab
        _buildOverviewTab(state),
        // Trends Tab
        _buildTrendsTab(state),
        // Details Tab
        _buildDetailsTab(state),
      ],
    );
  }

  Widget _buildOverviewTab(PaymentAnalyticsLoaded state) {
    return SingleChildScrollView(
      // padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PaymentStatsCards(
            statistics: state.kpis,
          ),
          const SizedBox(height: 24),
          RevenueChartWidget(
            data: state.analytics.trends,
            height: 250,
          ),
          const SizedBox(height: 24),
          PaymentBreakdownPieChart(
            methodAnalytics: state.analytics.methodAnalytics,
            height: 300,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(PaymentAnalyticsLoaded state) {
    return SingleChildScrollView(
      // padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          PaymentTrendsGraph(
            trends: state.trends,
            chartType: state.chartType,
            selectedMetrics: state.selectedMetrics,
            height: 300,
          ),
          const SizedBox(height: 24),
          _buildMetricsSelector(state),
          const SizedBox(height: 24),
          _buildChartTypeSelector(state),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(PaymentAnalyticsLoaded state) {
    return SingleChildScrollView(
      // padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          _buildDetailCard(
            'إجمالي المعاملات',
            state.analytics.summary.totalTransactions.toString(),
            Icons.receipt_long,
            AppTheme.primaryBlue,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            'إجمالي الإيرادات',
            state.analytics.summary.totalAmount.formattedAmount,
            Icons.attach_money,
            AppTheme.success,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            'متوسط قيمة المعاملة',
            state.analytics.summary.averageTransactionValue.formattedAmount,
            Icons.analytics,
            AppTheme.primaryPurple,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            'معدل النجاح',
            '${state.analytics.summary.successRate.toStringAsFixed(1)}%',
            Icons.check_circle,
            AppTheme.success,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            'إجمالي المستردات',
            state.analytics.summary.totalRefunded.formattedAmount,
            Icons.replay,
            AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.heading2.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSelector(PaymentAnalyticsLoaded state) {
    final metrics = ['revenue', 'transactions', 'success_rate', 'refunds'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics.map((metric) {
        final isSelected = state.selectedMetrics.contains(metric);
        return GestureDetector(
          onTap: () {
            context.read<PaymentAnalyticsBloc>().add(
                  ToggleMetricEvent(metric: metric),
                );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                  : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.darkBorder,
                width: 1,
              ),
            ),
            child: Text(
              _getMetricText(metric),
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartTypeSelector(PaymentAnalyticsLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ChartType.values.map((type) {
        final isSelected = state.chartType == type;
        return GestureDetector(
          onTap: () {
            context.read<PaymentAnalyticsBloc>().add(
                  ChangeChartTypeEvent(chartType: type),
                );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getChartIcon(type),
              color: AppTheme.textWhite,
              size: 20,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _exportReport() {
    context.read<PaymentAnalyticsBloc>().add(
          const ExportAnalyticsReportEvent(format: ExportFormat.pdf),
        );
  }

  String _getPeriodText(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.day:
        return 'يوم';
      case AnalyticsPeriod.week:
        return 'أسبوع';
      case AnalyticsPeriod.month:
        return 'شهر';
      case AnalyticsPeriod.quarter:
        return 'ربع سنة';
      case AnalyticsPeriod.year:
        return 'سنة';
      case AnalyticsPeriod.custom:
        return 'مخصص';
    }
  }

  String _getMetricText(String metric) {
    switch (metric) {
      case 'revenue':
        return 'الإيرادات';
      case 'transactions':
        return 'المعاملات';
      case 'success_rate':
        return 'معدل النجاح';
      case 'refunds':
        return 'المستردات';
      default:
        return metric;
    }
  }

  IconData _getChartIcon(ChartType type) {
    switch (type) {
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.pie:
        return Icons.pie_chart;
      case ChartType.area:
        return Icons.area_chart;
      case ChartType.donut:
        return Icons.donut_large;
    }
  }
}
