import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/payment_analytics.dart';
import '../../../domain/usecases/analytics/get_payment_analytics_usecase.dart';
import '../../../domain/usecases/analytics/get_revenue_report_usecase.dart';
import '../../../domain/usecases/analytics/get_payment_trends_usecase.dart';
import '../../../domain/usecases/analytics/get_refund_statistics_usecase.dart';
import 'payment_analytics_event.dart';
import 'payment_analytics_state.dart';

class PaymentAnalyticsBloc
    extends Bloc<PaymentAnalyticsEvent, PaymentAnalyticsState> {
  final GetPaymentAnalyticsUseCase getPaymentAnalyticsUseCase;
  final GetRevenueReportUseCase getRevenueReportUseCase;
  final GetPaymentTrendsUseCase getPaymentTrendsUseCase;
  final GetRefundStatisticsUseCase getRefundStatisticsUseCase;

  DateTime _currentStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _currentEndDate = DateTime.now();
  String? _currentPropertyId;
  AnalyticsPeriod _currentPeriod = AnalyticsPeriod.month;

  PaymentAnalyticsBloc({
    required this.getPaymentAnalyticsUseCase,
    required this.getRevenueReportUseCase,
    required this.getPaymentTrendsUseCase,
    required this.getRefundStatisticsUseCase,
  }) : super(PaymentAnalyticsInitial()) {
    on<LoadPaymentAnalyticsEvent>(_onLoadPaymentAnalytics);
    on<RefreshAnalyticsEvent>(_onRefreshAnalytics);
    on<ChangePeriodEvent>(_onChangePeriod);
    on<ChangePropertyFilterEvent>(_onChangePropertyFilter);
    on<LoadRevenueReportEvent>(_onLoadRevenueReport);
    on<LoadPaymentTrendsEvent>(_onLoadPaymentTrends);
    on<LoadRefundStatisticsEvent>(_onLoadRefundStatistics);
    on<ExportAnalyticsReportEvent>(_onExportAnalyticsReport);
    on<ComparePeriodsEvent>(_onComparePeriods);
    on<ChangeChartTypeEvent>(_onChangeChartType);
    on<ToggleMetricEvent>(_onToggleMetric);
  }

  Future<void> _onLoadPaymentAnalytics(
    LoadPaymentAnalyticsEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    emit(PaymentAnalyticsLoading());

    _currentStartDate = event.startDate ?? _currentStartDate;
    _currentEndDate = event.endDate ?? _currentEndDate;
    _currentPropertyId = event.propertyId;

    try {
      // تنفيذ الطلبات الثلاثة بالتوازي لتقليل زمن الانتظار
      final futures = await Future.wait([
        getPaymentAnalyticsUseCase(
          GetPaymentAnalyticsParams(
            startDate: _currentStartDate,
            endDate: _currentEndDate,
            propertyId: _currentPropertyId,
          ),
        ),
        getPaymentTrendsUseCase(
          GetPaymentTrendsParams(
            startDate: _currentStartDate,
            endDate: _currentEndDate,
            propertyId: _currentPropertyId,
          ),
        ),
        getRefundStatisticsUseCase(
          GetRefundStatisticsParams(
            startDate: _currentStartDate,
            endDate: _currentEndDate,
            propertyId: _currentPropertyId,
          ),
        ),
      ]);

      final dynamic analyticsResult = futures[0];
      final dynamic trendsResult = futures[1];
      final dynamic refundStatsResult = futures[2];

      PaymentAnalytics? analytics;
      List<PaymentTrend>? trends;
      RefundAnalytics? refundStats;
      String? errorMessage;

      analyticsResult.fold(
        (failure) => errorMessage = failure.message,
        (a) => analytics = a,
      );

      trendsResult.fold(
        (failure) => errorMessage ??= failure.message,
        (t) => trends = t,
      );

      refundStatsResult.fold(
        (failure) => errorMessage ??= failure.message,
        (r) => refundStats = r,
      );

      if (analytics != null) {
        emit(PaymentAnalyticsLoaded(
          analytics: analytics!,
          trends: trends ?? [],
          refundStatistics: refundStats,
          revenueReport: null,
          startDate: _currentStartDate,
          endDate: _currentEndDate,
          propertyId: _currentPropertyId,
          currentPeriod: _currentPeriod,
          chartType: ChartType.line,
          selectedMetrics: const ['revenue', 'transactions'],
        ));
      } else {
        emit(PaymentAnalyticsError(
          message: errorMessage ?? 'فشل تحميل التحليلات',
        ));
      }
    } catch (e) {
      emit(PaymentAnalyticsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshAnalytics(
    RefreshAnalyticsEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    add(LoadPaymentAnalyticsEvent(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      propertyId: _currentPropertyId,
    ));
  }

  Future<void> _onChangePeriod(
    ChangePeriodEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    _currentPeriod = event.period;

    final dateRange = _calculateDateRangeForPeriod(event.period);

    add(LoadPaymentAnalyticsEvent(
      startDate: dateRange.start,
      endDate: dateRange.end,
      propertyId: _currentPropertyId,
    ));
  }

  Future<void> _onChangePropertyFilter(
    ChangePropertyFilterEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    _currentPropertyId = event.propertyId;

    add(LoadPaymentAnalyticsEvent(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      propertyId: event.propertyId,
    ));
  }

  Future<void> _onLoadRevenueReport(
    LoadRevenueReportEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    if (state is PaymentAnalyticsLoaded) {
      final currentState = state as PaymentAnalyticsLoaded;
      emit(currentState.copyWith(isLoadingReport: true));

      final result = await getRevenueReportUseCase(
        GetRevenueReportParams(
          startDate: event.startDate,
          endDate: event.endDate,
          propertyId: event.propertyId,
        ),
      );

      result.fold(
        (failure) => emit(PaymentAnalyticsError(message: failure.message)),
        (report) => emit(currentState.copyWith(
          revenueReport: report,
          isLoadingReport: false,
        )),
      );
    }
  }

  Future<void> _onLoadPaymentTrends(
    LoadPaymentTrendsEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    if (state is PaymentAnalyticsLoaded) {
      final currentState = state as PaymentAnalyticsLoaded;
      emit(currentState.copyWith(isLoadingTrends: true));

      final result = await getPaymentTrendsUseCase(
        GetPaymentTrendsParams(
          startDate: event.startDate,
          endDate: event.endDate,
          propertyId: event.propertyId,
        ),
      );

      result.fold(
        (failure) => emit(PaymentAnalyticsError(message: failure.message)),
        (trends) => emit(currentState.copyWith(
          trends: trends,
          isLoadingTrends: false,
        )),
      );
    }
  }

  Future<void> _onLoadRefundStatistics(
    LoadRefundStatisticsEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    if (state is PaymentAnalyticsLoaded) {
      final currentState = state as PaymentAnalyticsLoaded;
      emit(currentState.copyWith(isLoadingRefundStats: true));

      final result = await getRefundStatisticsUseCase(
        GetRefundStatisticsParams(
          startDate: event.startDate,
          endDate: event.endDate,
          propertyId: event.propertyId,
        ),
      );

      result.fold(
        (failure) => emit(PaymentAnalyticsError(message: failure.message)),
        (stats) => emit(currentState.copyWith(
          refundStatistics: stats,
          isLoadingRefundStats: false,
        )),
      );
    }
  }

  Future<void> _onExportAnalyticsReport(
    ExportAnalyticsReportEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    if (state is PaymentAnalyticsLoaded) {
      final currentState = state as PaymentAnalyticsLoaded;
      emit(PaymentAnalyticsExporting(
        analytics: currentState.analytics,
        trends: currentState.trends,
        refundStatistics: currentState.refundStatistics,
        format: event.format,
      ));

      // تنفيذ منطق التصدير
      await Future.delayed(const Duration(seconds: 2));

      emit(PaymentAnalyticsExportSuccess(
        analytics: currentState.analytics,
        trends: currentState.trends,
        refundStatistics: currentState.refundStatistics,
        message: 'تم تصدير التقرير بنجاح',
      ));

      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  Future<void> _onComparePeriods(
    ComparePeriodsEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    emit(PaymentAnalyticsLoading());

    try {
      // تحميل تحليلات الفترة الأولى
      final period1Result = await getPaymentAnalyticsUseCase(
        GetPaymentAnalyticsParams(
          startDate: event.period1Start,
          endDate: event.period1End,
          propertyId: _currentPropertyId,
        ),
      );

      // تحميل تحليلات الفترة الثانية
      final period2Result = await getPaymentAnalyticsUseCase(
        GetPaymentAnalyticsParams(
          startDate: event.period2Start,
          endDate: event.period2End,
          propertyId: _currentPropertyId,
        ),
      );

      PaymentAnalytics? period1Analytics;
      PaymentAnalytics? period2Analytics;

      period1Result.fold(
        (_) => {},
        (analytics) => period1Analytics = analytics,
      );

      period2Result.fold(
        (_) => {},
        (analytics) => period2Analytics = analytics,
      );

      if (period1Analytics != null && period2Analytics != null) {
        final comparison =
            _compareAnalytics(period1Analytics!, period2Analytics!);

        emit(PaymentAnalyticsComparison(
          period1Analytics: period1Analytics!,
          period2Analytics: period2Analytics!,
          comparison: comparison,
          period1Start: event.period1Start,
          period1End: event.period1End,
          period2Start: event.period2Start,
          period2End: event.period2End,
        ));
      } else {
        emit(const PaymentAnalyticsError(
          message: 'فشل تحميل بيانات المقارنة',
        ));
      }
    } catch (e) {
      emit(PaymentAnalyticsError(message: e.toString()));
    }
  }

  Future<void> _onChangeChartType(
    ChangeChartTypeEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    if (state is PaymentAnalyticsLoaded) {
      final currentState = state as PaymentAnalyticsLoaded;
      emit(currentState.copyWith(chartType: event.chartType));
    }
  }

  Future<void> _onToggleMetric(
    ToggleMetricEvent event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    if (state is PaymentAnalyticsLoaded) {
      final currentState = state as PaymentAnalyticsLoaded;
      final updatedMetrics = List<String>.from(currentState.selectedMetrics);

      if (updatedMetrics.contains(event.metric)) {
        updatedMetrics.remove(event.metric);
      } else {
        updatedMetrics.add(event.metric);
      }

      emit(currentState.copyWith(selectedMetrics: updatedMetrics));
    }
  }

  DateRange _calculateDateRangeForPeriod(AnalyticsPeriod period) {
    final now = DateTime.now();
    DateTime start, end;

    switch (period) {
      case AnalyticsPeriod.day:
        start = DateTime(now.year, now.month, now.day);
        end = now;
        break;
      case AnalyticsPeriod.week:
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case AnalyticsPeriod.month:
        start = DateTime(now.year, now.month - 1, now.day);
        end = now;
        break;
      case AnalyticsPeriod.quarter:
        start = DateTime(now.year, now.month - 3, now.day);
        end = now;
        break;
      case AnalyticsPeriod.year:
        start = DateTime(now.year - 1, now.month, now.day);
        end = now;
        break;
      case AnalyticsPeriod.custom:
        start = _currentStartDate;
        end = _currentEndDate;
        break;
    }

    return DateRange(start: start, end: end);
  }

  Map<String, dynamic> _compareAnalytics(
    PaymentAnalytics analytics1,
    PaymentAnalytics analytics2,
  ) {
    final comparison = <String, dynamic>{};

    // مقارنة إجمالي المعاملات
    comparison['transactionsChange'] = _calculatePercentageChange(
      analytics1.summary.totalTransactions.toDouble(),
      analytics2.summary.totalTransactions.toDouble(),
    );

    // مقارنة الإيرادات
    comparison['revenueChange'] = _calculatePercentageChange(
      analytics1.summary.totalAmount.amount,
      analytics2.summary.totalAmount.amount,
    );

    // مقارنة معدل النجاح
    comparison['successRateChange'] = _calculatePercentageChange(
      analytics1.summary.successRate,
      analytics2.summary.successRate,
    );

    // مقارنة متوسط قيمة المعاملة
    comparison['avgTransactionChange'] = _calculatePercentageChange(
      analytics1.summary.averageTransactionValue.amount,
      analytics2.summary.averageTransactionValue.amount,
    );

    // مقارنة الاستردادات
    comparison['refundsChange'] = _calculatePercentageChange(
      analytics1.summary.refundCount.toDouble(),
      analytics2.summary.refundCount.toDouble(),
    );

    return comparison;
  }

  double _calculatePercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return newValue > 0 ? 100 : 0;
    return ((newValue - oldValue) / oldValue) * 100;
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}
