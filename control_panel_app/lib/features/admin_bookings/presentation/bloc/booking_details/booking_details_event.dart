import 'package:equatable/equatable.dart';

abstract class BookingDetailsEvent extends Equatable {
  const BookingDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// 📥 حدث تحميل تفاصيل الحجز
class LoadBookingDetailsEvent extends BookingDetailsEvent {
  final String bookingId;

  const LoadBookingDetailsEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 🔄 حدث تحديث تفاصيل الحجز
class RefreshBookingDetailsEvent extends BookingDetailsEvent {
  const RefreshBookingDetailsEvent();
}

/// ✏️ حدث تحديث بيانات الحجز
class UpdateBookingDetailsEvent extends BookingDetailsEvent {
  final String bookingId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guestsCount;

  const UpdateBookingDetailsEvent({
    required this.bookingId,
    this.checkIn,
    this.checkOut,
    this.guestsCount,
  });

  @override
  List<Object?> get props => [bookingId, checkIn, checkOut, guestsCount];
}

/// ❌ حدث إلغاء الحجز
class CancelBookingDetailsEvent extends BookingDetailsEvent {
  final String bookingId;
  final String cancellationReason;
  final bool refundPayments;

  const CancelBookingDetailsEvent({
    required this.bookingId,
    required this.cancellationReason,
    this.refundPayments = false,
  });

  @override
  List<Object> get props => [bookingId, cancellationReason, refundPayments];
}

/// ✅ حدث تأكيد الحجز
class ConfirmBookingDetailsEvent extends BookingDetailsEvent {
  final String bookingId;

  const ConfirmBookingDetailsEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 🏨 حدث تسجيل الوصول
class CheckInBookingDetailsEvent extends BookingDetailsEvent {
  final String bookingId;

  const CheckInBookingDetailsEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 🚪 حدث تسجيل المغادرة
class CheckOutBookingDetailsEvent extends BookingDetailsEvent {
  final String bookingId;

  const CheckOutBookingDetailsEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// ➕ حدث إضافة خدمة
class AddServiceEvent extends BookingDetailsEvent {
  final String bookingId;
  final String serviceId;

  const AddServiceEvent({
    required this.bookingId,
    required this.serviceId,
  });

  @override
  List<Object> get props => [bookingId, serviceId];
}

/// ➖ حدث إزالة خدمة
class RemoveServiceEvent extends BookingDetailsEvent {
  final String bookingId;
  final String serviceId;

  const RemoveServiceEvent({
    required this.bookingId,
    required this.serviceId,
  });

  @override
  List<Object> get props => [bookingId, serviceId];
}

/// 🛎️ حدث تحميل خدمات الحجز
class LoadBookingServicesEvent extends BookingDetailsEvent {
  final String bookingId;

  const LoadBookingServicesEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 📝 حدث تحميل أنشطة الحجز
class LoadBookingActivitiesEvent extends BookingDetailsEvent {
  final String bookingId;

  const LoadBookingActivitiesEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 💳 حدث تحميل مدفوعات الحجز
class LoadBookingPaymentsEvent extends BookingDetailsEvent {
  final String bookingId;

  const LoadBookingPaymentsEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 🖨️ حدث طباعة تفاصيل الحجز
class PrintBookingDetailsEvent extends BookingDetailsEvent {
  final String bookingId;

  const PrintBookingDetailsEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 📤 حدث مشاركة تفاصيل الحجز
class ShareBookingDetailsEvent extends BookingDetailsEvent {
  final String bookingId;

  const ShareBookingDetailsEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 📧 حدث إرسال تأكيد الحجز
class SendBookingConfirmationEvent extends BookingDetailsEvent {
  final String bookingId;
  final String? email;
  final String? phone;

  const SendBookingConfirmationEvent({
    required this.bookingId,
    this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [bookingId, email, phone];
}
