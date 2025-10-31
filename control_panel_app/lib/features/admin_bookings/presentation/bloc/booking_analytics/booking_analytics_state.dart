import 'package:equatable/equatable.dart';
import '../../../domain/entities/booking_report.dart';
import '../../../domain/entities/booking_trends.dart';
import '../../../domain/entities/booking_window_analysis.dart';
import 'booking_analytics_event.dart';

abstract class BookingAnalyticsState extends Equatable {
  const BookingAnalyticsState();

  @override
  List<Object?> get props => [];
}

/// 🎬 الحالة الابتدائية
class BookingAnalyticsInitial extends BookingAnalyticsState {}

/// ⏳ حالة التحميل
class BookingAnalyticsLoading extends BookingAnalyticsState {}

/// ✅ حالة نجاح التحميل
class BookingAnalyticsLoaded extends BookingAnalyticsState {
  final BookingReport report;
  final BookingTrends trends;
  final BookingWindowAnalysis? windowAnalysis;
  final DateTime startDate;
  final DateTime endDate;
  final String? propertyId;
  final AnalyticsPeriod currentPeriod;
  final bool isLoadingReport;
  final bool isLoadingTrends;
  final bool isLoadingWindowAnalysis;

  const BookingAnalyticsLoaded({
    required this.report,
    required this.trends,
    this.windowAnalysis,
    required this.startDate,
    required this.endDate,
    this.propertyId,
    required this.currentPeriod,
    this.isLoadingReport = false,
    this.isLoadingTrends = false,
    this.isLoadingWindowAnalysis = false,
  });

  BookingAnalyticsLoaded copyWith({
    BookingReport? report,
    BookingTrends? trends,
    BookingWindowAnalysis? windowAnalysis,
    DateTime? startDate,
    DateTime? endDate,
    String? propertyId,
    AnalyticsPeriod? currentPeriod,
    bool? isLoadingReport,
    bool? isLoadingTrends,
    bool? isLoadingWindowAnalysis,
  }) {
    return BookingAnalyticsLoaded(
      report: report ?? this.report,
      trends: trends ?? this.trends,
      windowAnalysis: windowAnalysis ?? this.windowAnalysis,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      propertyId: propertyId ?? this.propertyId,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      isLoadingReport: isLoadingReport ?? this.isLoadingReport,
      isLoadingTrends: isLoadingTrends ?? this.isLoadingTrends,
      isLoadingWindowAnalysis:
          isLoadingWindowAnalysis ?? this.isLoadingWindowAnalysis,
    );
  }

  /// حساب مؤشرات الأداء الرئيسية
  Map<String, dynamic> get kpis {
    return {
      'totalBookings': report.summary.totalBookings,
      'totalRevenue': report.summary.totalRevenue,
      'averageBookingValue': report.summary.averageBookingValue,
      'occupancyRate': report.summary.occupancyRate,
      'averageStayLength': report.summary.averageStayLength,
      'growthRate': trends.analysis.growthRate,
      'trend': trends.analysis.trend,
      'averageLeadTime': windowAnalysis?.averageLeadTimeInDays ?? 0,
    };
  }

  @override
  List<Object?> get props => [
        report,
        trends,
        windowAnalysis,
        startDate,
        endDate,
        propertyId,
        currentPeriod,
        isLoadingReport,
        isLoadingTrends,
        isLoadingWindowAnalysis,
      ];
}

/// ❌ حالة الخطأ
class BookingAnalyticsError extends BookingAnalyticsState {
  final String message;

  const BookingAnalyticsError({required this.message});

  @override
  List<Object> get props => [message];
}

/// 📤 حالة التصدير
class BookingAnalyticsExporting extends BookingAnalyticsState {
  final BookingReport report;
  final BookingTrends trends;
  final BookingWindowAnalysis? windowAnalysis;
  final ExportFormat format;

  const BookingAnalyticsExporting({
    required this.report,
    required this.trends,
    this.windowAnalysis,
    required this.format,
  });

  @override
  List<Object?> get props => [report, trends, windowAnalysis, format];
}

/// ✅ حالة نجاح التصدير
class BookingAnalyticsExportSuccess extends BookingAnalyticsState {
  final BookingReport report;
  final BookingTrends trends;
  final BookingWindowAnalysis? windowAnalysis;
  final String message;

  const BookingAnalyticsExportSuccess({
    required this.report,
    required this.trends,
    this.windowAnalysis,
    required this.message,
  });

  @override
  List<Object?> get props => [report, trends, windowAnalysis, message];
}

/// 🔄 حالة المقارنة
class BookingAnalyticsComparison extends BookingAnalyticsState {
  final BookingReport period1Report;
  final BookingReport period2Report;
  final Map<String, dynamic> comparison;
  final DateTime period1Start;
  final DateTime period1End;
  final DateTime period2Start;
  final DateTime period2End;

  const BookingAnalyticsComparison({
    required this.period1Report,
    required this.period2Report,
    required this.comparison,
    required this.period1Start,
    required this.period1End,
    required this.period2Start,
    required this.period2End,
  });

  @override
  List<Object> get props => [
        period1Report,
        period2Report,
        comparison,
        period1Start,
        period1End,
        period2Start,
        period2End,
      ];
}
