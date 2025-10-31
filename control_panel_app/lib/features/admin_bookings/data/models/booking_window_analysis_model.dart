import '../../domain/entities/booking_window_analysis.dart';

class BookingWindowAnalysisModel extends BookingWindowAnalysis {
  const BookingWindowAnalysisModel({
    required super.averageLeadTimeInDays,
    required super.bookingsLastMinute,
    required super.bookingsAdvance,
    required super.bookingsByLeadTime,
    required super.segments,
    required super.insights,
  });

  factory BookingWindowAnalysisModel.fromJson(Map<String, dynamic> json) {
    return BookingWindowAnalysisModel(
      averageLeadTimeInDays: (json['averageLeadTimeInDays'] ?? 0).toDouble(),
      bookingsLastMinute: json['bookingsLastMinute'] ?? 0,
      bookingsAdvance: json['bookingsAdvance'] ?? 0,
      bookingsByLeadTime:
          Map<String, int>.from(json['bookingsByLeadTime'] ?? {}),
      segments: (json['segments'] as List? ?? [])
          .map((item) => LeadTimeSegmentModel.fromJson(item))
          .toList(),
      insights: WindowInsightsModel.fromJson(json['insights'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageLeadTimeInDays': averageLeadTimeInDays,
      'bookingsLastMinute': bookingsLastMinute,
      'bookingsAdvance': bookingsAdvance,
      'bookingsByLeadTime': bookingsByLeadTime,
      'segments': segments
          .map((item) => (item as LeadTimeSegmentModel).toJson())
          .toList(),
      'insights': (insights as WindowInsightsModel).toJson(),
    };
  }
}

/// 📊 Model لشريحة وقت الحجز المسبق
class LeadTimeSegmentModel extends LeadTimeSegment {
  const LeadTimeSegmentModel({
    required super.name,
    required super.minDays,
    required super.maxDays,
    required super.bookingsCount,
    required super.percentage,
    required super.averageValue,
  });

  factory LeadTimeSegmentModel.fromJson(Map<String, dynamic> json) {
    return LeadTimeSegmentModel(
      name: json['name'] ?? '',
      minDays: json['minDays'] ?? 0,
      maxDays: json['maxDays'] ?? 0,
      bookingsCount: json['bookingsCount'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      averageValue: (json['averageValue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'minDays': minDays,
      'maxDays': maxDays,
      'bookingsCount': bookingsCount,
      'percentage': percentage,
      'averageValue': averageValue,
    };
  }
}

/// 💡 Model لرؤى نافذة الحجز
class WindowInsightsModel extends WindowInsights {
  const WindowInsightsModel({
    required super.optimalBookingWindow,
    required super.recommendations,
    required super.patterns,
  });

  factory WindowInsightsModel.fromJson(Map<String, dynamic> json) {
    return WindowInsightsModel(
      optimalBookingWindow: json['optimalBookingWindow'] ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      patterns: json['patterns'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optimalBookingWindow': optimalBookingWindow,
      'recommendations': recommendations,
      'patterns': patterns,
    };
  }
}
