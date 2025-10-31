import 'package:equatable/equatable.dart';

abstract class BookingsListEvent extends Equatable {
  const BookingsListEvent();

  @override
  List<Object?> get props => [];
}

/// 📥 حدث تحميل الحجوزات
class LoadBookingsEvent extends BookingsListEvent {
  final DateTime startDate;
  final DateTime endDate;
  final int pageNumber;
  final int pageSize;
  final String? userId;
  final String? guestNameOrEmail;
  final String? unitId;
  final String? bookingSource;

  const LoadBookingsEvent({
    required this.startDate,
    required this.endDate,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.userId,
    this.guestNameOrEmail,
    this.unitId,
    this.bookingSource,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        pageNumber,
        pageSize,
        userId,
        guestNameOrEmail,
        unitId,
        bookingSource,
      ];
}

/// 🔄 حدث تحديث قائمة الحجوزات
class RefreshBookingsEvent extends BookingsListEvent {
  const RefreshBookingsEvent();
}

/// ❌ حدث إلغاء الحجز
class CancelBookingEvent extends BookingsListEvent {
  final String bookingId;
  final String cancellationReason;
  final bool refundPayments;

  const CancelBookingEvent({
    required this.bookingId,
    required this.cancellationReason,
    this.refundPayments = false,
  });

  @override
  List<Object> get props => [bookingId, cancellationReason, refundPayments];
}

/// ✏️ حدث تحديث الحجز
class UpdateBookingEvent extends BookingsListEvent {
  final String bookingId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guestsCount;

  const UpdateBookingEvent({
    required this.bookingId,
    this.checkIn,
    this.checkOut,
    this.guestsCount,
  });

  @override
  List<Object?> get props => [bookingId, checkIn, checkOut, guestsCount];
}

/// ✅ حدث تأكيد الحجز
class ConfirmBookingEvent extends BookingsListEvent {
  final String bookingId;

  const ConfirmBookingEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 🏨 حدث تسجيل الوصول
class CheckInBookingEvent extends BookingsListEvent {
  final String bookingId;

  const CheckInBookingEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 🚪 حدث تسجيل المغادرة
class CheckOutBookingEvent extends BookingsListEvent {
  final String bookingId;

  const CheckOutBookingEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 🔍 حدث البحث في الحجوزات
class SearchBookingsEvent extends BookingsListEvent {
  final String searchTerm;

  const SearchBookingsEvent({required this.searchTerm});

  @override
  List<Object> get props => [searchTerm];
}

/// 🏷️ حدث تطبيق الفلاتر
class FilterBookingsEvent extends BookingsListEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userId;
  final String? guestNameOrEmail;
  final String? unitId;
  final String? bookingSource;

  const FilterBookingsEvent({
    this.startDate,
    this.endDate,
    this.userId,
    this.guestNameOrEmail,
    this.unitId,
    this.bookingSource,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        userId,
        guestNameOrEmail,
        unitId,
        bookingSource,
      ];
}

/// 📑 حدث تغيير الصفحة
class ChangePageEvent extends BookingsListEvent {
  final int pageNumber;

  const ChangePageEvent({required this.pageNumber});

  @override
  List<Object> get props => [pageNumber];
}

/// 🔢 حدث تغيير حجم الصفحة
class ChangePageSizeEvent extends BookingsListEvent {
  final int pageSize;

  const ChangePageSizeEvent({required this.pageSize});

  @override
  List<Object> get props => [pageSize];
}

/// 🎯 حدث اختيار حجز
class SelectBookingEvent extends BookingsListEvent {
  final String bookingId;

  const SelectBookingEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// ❌ حدث إلغاء اختيار حجز
class DeselectBookingEvent extends BookingsListEvent {
  final String bookingId;

  const DeselectBookingEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 📋 حدث اختيار حجوزات متعددة
class SelectMultipleBookingsEvent extends BookingsListEvent {
  final List<String> bookingIds;

  const SelectMultipleBookingsEvent({required this.bookingIds});

  @override
  List<Object> get props => [bookingIds];
}

/// 🧹 حدث مسح الاختيار
class ClearSelectionEvent extends BookingsListEvent {
  const ClearSelectionEvent();
}

/// 📊 حدث تحميل إحصائيات الحجوزات
class LoadBookingStatsEvent extends BookingsListEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? propertyId;

  const LoadBookingStatsEvent({
    required this.startDate,
    required this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}

/// 📈 حدث تحميل اتجاهات الحجوزات
class LoadBookingTrendsEvent extends BookingsListEvent {
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
