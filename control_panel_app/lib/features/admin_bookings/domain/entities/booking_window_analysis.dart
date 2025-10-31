import 'package:equatable/equatable.dart';

/// 🪟 Entity لتحليل نافذة الحجز
class BookingWindowAnalysis extends Equatable {
  final double averageLeadTimeInDays;
  final int bookingsLastMinute;
  final int bookingsAdvance;
  final Map<String, int> bookingsByLeadTime;
  final List<LeadTimeSegment> segments;
  final WindowInsights insights;

  const BookingWindowAnalysis({
    required this.averageLeadTimeInDays,
    required this.bookingsLastMinute,
    required this.bookingsAdvance,
    required this.bookingsByLeadTime,
    required this.segments,
    required this.insights,
  });

  @override
  List<Object> get props => [
        averageLeadTimeInDays,
        bookingsLastMinute,
        bookingsAdvance,
        bookingsByLeadTime,
        segments,
        insights,
      ];
}

/// 📊 شريحة وقت الحجز المسبق
class LeadTimeSegment extends Equatable {
  final String name;
  final int minDays;
  final int maxDays;
  final int bookingsCount;
  final double percentage;
  final double averageValue;

  const LeadTimeSegment({
    required this.name,
    required this.minDays,
    required this.maxDays,
    required this.bookingsCount,
    required this.percentage,
    required this.averageValue,
  });

  @override
  List<Object> get props => [
        name,
        minDays,
        maxDays,
        bookingsCount,
        percentage,
        averageValue,
      ];
}

/// 💡 رؤى نافذة الحجز
class WindowInsights extends Equatable {
  final String optimalBookingWindow;
  final List<String> recommendations;
  final Map<String, dynamic> patterns;

  const WindowInsights({
    required this.optimalBookingWindow,
    required this.recommendations,
    required this.patterns,
  });

  @override
  List<Object> get props => [
        optimalBookingWindow,
        recommendations,
        patterns,
      ];
}
