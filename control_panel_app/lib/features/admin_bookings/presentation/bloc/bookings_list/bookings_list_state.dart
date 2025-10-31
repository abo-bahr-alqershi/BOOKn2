import 'package:equatable/equatable.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/entities/booking_report.dart';
import '../../../domain/entities/booking_trends.dart';

abstract class BookingsListState extends Equatable {
  const BookingsListState();

  @override
  List<Object?> get props => [];
}

/// 🎬 الحالة الابتدائية
class BookingsListInitial extends BookingsListState {}

/// ⏳ حالة التحميل
class BookingsListLoading extends BookingsListState {}

/// ✅ حالة نجاح التحميل
class BookingsListLoaded extends BookingsListState {
  final PaginatedResult<Booking> bookings;
  final List<Booking> selectedBookings;
  final BookingFilters? filters;
  final BookingReport? report;
  final BookingTrends? trends;
  final Map<String, dynamic>? stats;

  const BookingsListLoaded({
    required this.bookings,
    this.selectedBookings = const [],
    this.filters,
    this.report,
    this.trends,
    this.stats,
  });

  BookingsListLoaded copyWith({
    PaginatedResult<Booking>? bookings,
    List<Booking>? selectedBookings,
    BookingFilters? filters,
    BookingReport? report,
    BookingTrends? trends,
    Map<String, dynamic>? stats,
  }) {
    return BookingsListLoaded(
      bookings: bookings ?? this.bookings,
      selectedBookings: selectedBookings ?? this.selectedBookings,
      filters: filters ?? this.filters,
      report: report ?? this.report,
      trends: trends ?? this.trends,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        bookings,
        selectedBookings,
        filters,
        report,
        trends,
        stats,
      ];
}

/// ❌ حالة الخطأ
class BookingsListError extends BookingsListState {
  final String message;

  const BookingsListError({required this.message});

  @override
  List<Object> get props => [message];
}

/// 🔄 حالة العملية الجارية
class BookingOperationInProgress extends BookingsListState {
  final PaginatedResult<Booking> bookings;
  final List<Booking> selectedBookings;
  final String operation;
  final String? bookingId;

  const BookingOperationInProgress({
    required this.bookings,
    required this.selectedBookings,
    required this.operation,
    this.bookingId,
  });

  @override
  List<Object?> get props => [bookings, selectedBookings, operation, bookingId];
}

/// ✅ حالة نجاح العملية
class BookingOperationSuccess extends BookingsListState {
  final PaginatedResult<Booking> bookings;
  final List<Booking> selectedBookings;
  final String message;
  final String? bookingId;

  const BookingOperationSuccess({
    required this.bookings,
    required this.selectedBookings,
    required this.message,
    this.bookingId,
  });

  @override
  List<Object?> get props => [bookings, selectedBookings, message, bookingId];
}

/// ❌ حالة فشل العملية
class BookingOperationFailure extends BookingsListState {
  final PaginatedResult<Booking> bookings;
  final List<Booking> selectedBookings;
  final String message;
  final String? bookingId;

  const BookingOperationFailure({
    required this.bookings,
    required this.selectedBookings,
    required this.message,
    this.bookingId,
  });

  @override
  List<Object?> get props => [bookings, selectedBookings, message, bookingId];
}

/// 📊 فلاتر الحجوزات
class BookingFilters extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userId;
  final String? guestNameOrEmail;
  final String? unitId;
  final String? bookingSource;
  final String? status;
  final String? paymentStatus;
  final bool? isWalkIn;
  final double? minTotalPrice;
  final int? minGuestsCount;

  const BookingFilters({
    this.startDate,
    this.endDate,
    this.userId,
    this.guestNameOrEmail,
    this.unitId,
    this.bookingSource,
    this.status,
    this.paymentStatus,
    this.isWalkIn,
    this.minTotalPrice,
    this.minGuestsCount,
  });

  BookingFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? guestNameOrEmail,
    String? unitId,
    String? bookingSource,
    String? status,
    String? paymentStatus,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
  }) {
    return BookingFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
      guestNameOrEmail: guestNameOrEmail ?? this.guestNameOrEmail,
      unitId: unitId ?? this.unitId,
      bookingSource: bookingSource ?? this.bookingSource,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isWalkIn: isWalkIn ?? this.isWalkIn,
      minTotalPrice: minTotalPrice ?? this.minTotalPrice,
      minGuestsCount: minGuestsCount ?? this.minGuestsCount,
    );
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        userId,
        guestNameOrEmail,
        unitId,
        bookingSource,
        status,
        paymentStatus,
        isWalkIn,
        minTotalPrice,
        minGuestsCount,
      ];
}
