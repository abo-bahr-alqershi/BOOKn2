import 'package:equatable/equatable.dart';

/// 📊 Entity لتقرير الحجوزات
class BookingReport extends Equatable {
  final List<BookingReportItem> items;
  final BookingReportSummary summary;
  final DateTime startDate;
  final DateTime endDate;

  const BookingReport({
    required this.items,
    required this.summary,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [items, summary, startDate, endDate];
}

/// 📈 عنصر تقرير يومي
class BookingReportItem extends Equatable {
  final DateTime date;
  final int count;
  final double revenue;
  final int checkIns;
  final int checkOuts;
  final int cancellations;
  final Map<String, int> bookingsByStatus;

  const BookingReportItem({
    required this.date,
    required this.count,
    required this.revenue,
    required this.checkIns,
    required this.checkOuts,
    required this.cancellations,
    required this.bookingsByStatus,
  });

  @override
  List<Object> get props => [
        date,
        count,
        revenue,
        checkIns,
        checkOuts,
        cancellations,
        bookingsByStatus,
      ];
}

/// 📊 ملخص التقرير
class BookingReportSummary extends Equatable {
  final int totalBookings;
  final double totalRevenue;
  final double averageBookingValue;
  final double occupancyRate;
  final int totalNights;
  final double averageStayLength;
  final Map<String, int> bookingsBySource;
  final Map<String, double> revenueByPaymentMethod;

  const BookingReportSummary({
    required this.totalBookings,
    required this.totalRevenue,
    required this.averageBookingValue,
    required this.occupancyRate,
    required this.totalNights,
    required this.averageStayLength,
    required this.bookingsBySource,
    required this.revenueByPaymentMethod,
  });

  @override
  List<Object> get props => [
        totalBookings,
        totalRevenue,
        averageBookingValue,
        occupancyRate,
        totalNights,
        averageStayLength,
        bookingsBySource,
        revenueByPaymentMethod,
      ];
}
