import 'package:equatable/equatable.dart';

/// 📈 Entity لاتجاهات الحجوزات
class BookingTrends extends Equatable {
  final List<TimeSeriesData> bookingTrends;
  final List<TimeSeriesData> revenueTrends;
  final List<TimeSeriesData> occupancyTrends;
  final TrendAnalysis analysis;

  const BookingTrends({
    required this.bookingTrends,
    required this.revenueTrends,
    required this.occupancyTrends,
    required this.analysis,
  });

  @override
  List<Object> get props => [
        bookingTrends,
        revenueTrends,
        occupancyTrends,
        analysis,
      ];
}

/// 📊 بيانات السلسلة الزمنية
class TimeSeriesData extends Equatable {
  final DateTime date;
  final double value;
  final String? label;
  final Map<String, dynamic>? metadata;

  const TimeSeriesData({
    required this.date,
    required this.value,
    this.label,
    this.metadata,
  });

  @override
  List<Object?> get props => [date, value, label, metadata];
}

/// 📈 تحليل الاتجاهات
class TrendAnalysis extends Equatable {
  final double growthRate;
  final String trend; // 'increasing', 'decreasing', 'stable'
  final double forecast;
  final Map<String, double> seasonalFactors;
  final List<String> insights;

  const TrendAnalysis({
    required this.growthRate,
    required this.trend,
    required this.forecast,
    required this.seasonalFactors,
    required this.insights,
  });

  @override
  List<Object> get props => [
        growthRate,
        trend,
        forecast,
        seasonalFactors,
        insights,
      ];
}
