import '../../domain/entities/booking_trends.dart';

class BookingTrendsModel extends BookingTrends {
  const BookingTrendsModel({
    required super.bookingTrends,
    required super.revenueTrends,
    required super.occupancyTrends,
    required super.analysis,
  });

  factory BookingTrendsModel.fromJson(Map<String, dynamic> json) {
    return BookingTrendsModel(
      bookingTrends: (json['bookingTrends'] as List? ?? [])
          .map((item) => TimeSeriesDataModel.fromJson(item))
          .toList(),
      revenueTrends: (json['revenueTrends'] as List? ?? [])
          .map((item) => TimeSeriesDataModel.fromJson(item))
          .toList(),
      occupancyTrends: (json['occupancyTrends'] as List? ?? [])
          .map((item) => TimeSeriesDataModel.fromJson(item))
          .toList(),
      analysis: TrendAnalysisModel.fromJson(json['analysis'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingTrends': bookingTrends
          .map((item) => (item as TimeSeriesDataModel).toJson())
          .toList(),
      'revenueTrends': revenueTrends
          .map((item) => (item as TimeSeriesDataModel).toJson())
          .toList(),
      'occupancyTrends': occupancyTrends
          .map((item) => (item as TimeSeriesDataModel).toJson())
          .toList(),
      'analysis': (analysis as TrendAnalysisModel).toJson(),
    };
  }
}

/// 📊 Model لبيانات السلسلة الزمنية
class TimeSeriesDataModel extends TimeSeriesData {
  const TimeSeriesDataModel({
    required super.date,
    required super.value,
    super.label,
    super.metadata,
  });

  factory TimeSeriesDataModel.fromJson(Map<String, dynamic> json) {
    return TimeSeriesDataModel(
      date: DateTime.parse(json['date']),
      value: (json['value'] ?? 0).toDouble(),
      label: json['label'],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      if (label != null) 'label': label,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// 📈 Model لتحليل الاتجاهات
class TrendAnalysisModel extends TrendAnalysis {
  const TrendAnalysisModel({
    required super.growthRate,
    required super.trend,
    required super.forecast,
    required super.seasonalFactors,
    required super.insights,
  });

  factory TrendAnalysisModel.fromJson(Map<String, dynamic> json) {
    return TrendAnalysisModel(
      growthRate: (json['growthRate'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'stable',
      forecast: (json['forecast'] ?? 0).toDouble(),
      seasonalFactors: Map<String, double>.from(json['seasonalFactors'] ?? {}),
      insights: List<String>.from(json['insights'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'growthRate': growthRate,
      'trend': trend,
      'forecast': forecast,
      'seasonalFactors': seasonalFactors,
      'insights': insights,
    };
  }
}
