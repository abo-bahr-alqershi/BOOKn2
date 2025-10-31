import '../../../../../core/enums/booking_status.dart';

/// 📊 Model لحالة الحجز مع إحصائيات
class BookingStatusModel {
  final BookingStatus status;
  final int count;
  final double percentage;
  final double revenue;

  BookingStatusModel({
    required this.status,
    required this.count,
    required this.percentage,
    required this.revenue,
  });

  factory BookingStatusModel.fromJson(Map<String, dynamic> json) {
    return BookingStatusModel(
      status: _parseStatus(json['status']),
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.displayNameEn,
      'count': count,
      'percentage': percentage,
      'revenue': revenue,
    };
  }

  static BookingStatus _parseStatus(dynamic status) {
    if (status == null) return BookingStatus.pending;

    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'pending':
        return BookingStatus.pending;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'checkedin':
      case 'checked_in':
        return BookingStatus.checkedIn;
      default:
        return BookingStatus.pending;
    }
  }
}

/// 📊 Model لإحصائيات الحالات
class BookingStatusStats {
  final List<BookingStatusModel> statusBreakdown;
  final int totalBookings;
  final double totalRevenue;

  BookingStatusStats({
    required this.statusBreakdown,
    required this.totalBookings,
    required this.totalRevenue,
  });

  factory BookingStatusStats.fromJson(Map<String, dynamic> json) {
    return BookingStatusStats(
      statusBreakdown: (json['statusBreakdown'] as List? ?? [])
          .map((item) => BookingStatusModel.fromJson(item))
          .toList(),
      totalBookings: json['totalBookings'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}
