import 'package:equatable/equatable.dart';

abstract class PaymentAnalyticsEvent extends Equatable {
  const PaymentAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// 📊 حدث تحميل التحليلات
class LoadPaymentAnalyticsEvent extends PaymentAnalyticsEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? propertyId;

  const LoadPaymentAnalyticsEvent({
    this.startDate,
    this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}

/// 🔄 حدث تحديث التحليلات
class RefreshAnalyticsEvent extends PaymentAnalyticsEvent {
  const RefreshAnalyticsEvent();
}

/// 📅 حدث تغيير الفترة الزمنية
class ChangePeriodEvent extends PaymentAnalyticsEvent {
  final AnalyticsPeriod period;

  const ChangePeriodEvent({required this.period});

  @override
  List<Object> get props => [period];
}

/// 🏢 حدث تغيير فلتر العقار
class ChangePropertyFilterEvent extends PaymentAnalyticsEvent {
  final String? propertyId;

  const ChangePropertyFilterEvent({this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

/// 📈 حدث تحميل تقرير الإيرادات
class LoadRevenueReportEvent extends PaymentAnalyticsEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? propertyId;

  const LoadRevenueReportEvent({
    required this.startDate,
    required this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}

/// 📊 حدث تحميل اتجاهات المدفوعات
class LoadPaymentTrendsEvent extends PaymentAnalyticsEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? propertyId;

  const LoadPaymentTrendsEvent({
    required this.startDate,
    required this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}

/// 💸 حدث تحميل إحصائيات الاستردادات
class LoadRefundStatisticsEvent extends PaymentAnalyticsEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? propertyId;

  const LoadRefundStatisticsEvent({
    this.startDate,
    this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}

/// 📤 حدث تصدير التقرير
class ExportAnalyticsReportEvent extends PaymentAnalyticsEvent {
  final ExportFormat format;

  const ExportAnalyticsReportEvent({required this.format});

  @override
  List<Object> get props => [format];
}

/// 🔄 حدث مقارنة الفترات
class ComparePeriodsEvent extends PaymentAnalyticsEvent {
  final DateTime period1Start;
  final DateTime period1End;
  final DateTime period2Start;
  final DateTime period2End;

  const ComparePeriodsEvent({
    required this.period1Start,
    required this.period1End,
    required this.period2Start,
    required this.period2End,
  });

  @override
  List<Object> get props =>
      [period1Start, period1End, period2Start, period2End];
}

/// 📊 حدث تغيير نوع الرسم البياني
class ChangeChartTypeEvent extends PaymentAnalyticsEvent {
  final ChartType chartType;

  const ChangeChartTypeEvent({required this.chartType});

  @override
  List<Object> get props => [chartType];
}

/// 📈 حدث تبديل المقياس
class ToggleMetricEvent extends PaymentAnalyticsEvent {
  final String metric;

  const ToggleMetricEvent({required this.metric});

  @override
  List<Object> get props => [metric];
}

/// فترات التحليل
enum AnalyticsPeriod {
  day,
  week,
  month,
  quarter,
  year,
  custom,
}

/// أنواع الرسوم البيانية
enum ChartType {
  line,
  bar,
  pie,
  area,
  donut,
}

/// صيغ التصدير
enum ExportFormat {
  pdf,
  excel,
  csv,
}
