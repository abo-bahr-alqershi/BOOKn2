import 'package:equatable/equatable.dart';

abstract class BookingAnalyticsEvent extends Equatable {
  const BookingAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// 📊 حدث تحميل التحليلات
class LoadBookingAnalyticsEvent extends BookingAnalyticsEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? propertyId;

  const LoadBookingAnalyticsEvent({
    required this.startDate,
    required this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}

/// 🔄 حدث تحديث التحليلات
class RefreshAnalyticsEvent extends BookingAnalyticsEvent {
  const RefreshAnalyticsEvent();
}

/// 📅 حدث تغيير الفترة الزمنية
class ChangePeriodEvent extends BookingAnalyticsEvent {
  final AnalyticsPeriod period;

  const ChangePeriodEvent({required this.period});

  @override
  List<Object> get props => [period];
}

/// 🏢 حدث تغيير فلتر العقار
class ChangePropertyFilterEvent extends BookingAnalyticsEvent {
  final String? propertyId;

  const ChangePropertyFilterEvent({this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

/// 📈 حدث تحميل تقرير الحجوزات
class LoadBookingReportEvent extends BookingAnalyticsEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? propertyId;

  const LoadBookingReportEvent({
    required this.startDate,
    required this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}

/// 📊 حدث تحميل اتجاهات الحجوزات
class LoadBookingTrendsEvent extends BookingAnalyticsEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? propertyId;

  const LoadBookingTrendsEvent({
    required this.startDate,
    required this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}

/// 🪟 حدث تحميل تحليل نافذة الحجز
class LoadBookingWindowAnalysisEvent extends BookingAnalyticsEvent {
  final String propertyId;

  const LoadBookingWindowAnalysisEvent({required this.propertyId});

  @override
  List<Object> get props => [propertyId];
}

/// 📤 حدث تصدير التقرير
class ExportAnalyticsReportEvent extends BookingAnalyticsEvent {
  final ExportFormat format;

  const ExportAnalyticsReportEvent({required this.format});

  @override
  List<Object> get props => [format];
}

/// 🔄 حدث مقارنة الفترات
class ComparePeriodsEvent extends BookingAnalyticsEvent {
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

/// فترات التحليل
enum AnalyticsPeriod {
  day,
  week,
  month,
  quarter,
  year,
}

/// صيغ التصدير
enum ExportFormat {
  pdf,
  excel,
  csv,
}
