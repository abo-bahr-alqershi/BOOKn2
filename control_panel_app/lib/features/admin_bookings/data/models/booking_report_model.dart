import '../../domain/entities/booking_report.dart';

class BookingReportModel extends BookingReport {
  const BookingReportModel({
    required super.items,
    required super.summary,
    required super.startDate,
    required super.endDate,
  });

  factory BookingReportModel.fromJson(Map<String, dynamic> json) {
    return BookingReportModel(
      items: (json['items'] as List? ?? [])
          .map((item) => BookingReportItemModel.fromJson(item))
          .toList(),
      summary: BookingReportSummaryModel.fromJson(json['summary'] ?? json),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items
          .map((item) => (item as BookingReportItemModel).toJson())
          .toList(),
      'summary': (summary as BookingReportSummaryModel).toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}

/// 📈 Model لعنصر التقرير اليومي
class BookingReportItemModel extends BookingReportItem {
  const BookingReportItemModel({
    required super.date,
    required super.count,
    required super.revenue,
    required super.checkIns,
    required super.checkOuts,
    required super.cancellations,
    required super.bookingsByStatus,
  });

  factory BookingReportItemModel.fromJson(Map<String, dynamic> json) {
    return BookingReportItemModel(
      date: DateTime.parse(json['date']),
      count: json['count'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      checkIns: json['checkIns'] ?? 0,
      checkOuts: json['checkOuts'] ?? 0,
      cancellations: json['cancellations'] ?? 0,
      bookingsByStatus: Map<String, int>.from(json['bookingsByStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'count': count,
      'revenue': revenue,
      'checkIns': checkIns,
      'checkOuts': checkOuts,
      'cancellations': cancellations,
      'bookingsByStatus': bookingsByStatus,
    };
  }
}

/// 📊 Model لملخص التقرير
class BookingReportSummaryModel extends BookingReportSummary {
  const BookingReportSummaryModel({
    required super.totalBookings,
    required super.totalRevenue,
    required super.averageBookingValue,
    required super.occupancyRate,
    required super.totalNights,
    required super.averageStayLength,
    required super.bookingsBySource,
    required super.revenueByPaymentMethod,
  });

  factory BookingReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return BookingReportSummaryModel(
      totalBookings: json['totalBookings'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      averageBookingValue: (json['averageBookingValue'] ?? 0).toDouble(),
      occupancyRate: (json['occupancyRate'] ?? 0).toDouble(),
      totalNights: json['totalNights'] ?? 0,
      averageStayLength: (json['averageStayLength'] ?? 0).toDouble(),
      bookingsBySource: Map<String, int>.from(json['bookingsBySource'] ?? {}),
      revenueByPaymentMethod:
          Map<String, double>.from(json['revenueByPaymentMethod'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'totalRevenue': totalRevenue,
      'averageBookingValue': averageBookingValue,
      'occupancyRate': occupancyRate,
      'totalNights': totalNights,
      'averageStayLength': averageStayLength,
      'bookingsBySource': bookingsBySource,
      'revenueByPaymentMethod': revenueByPaymentMethod,
    };
  }
}
