import 'package:bookn_cp_app/features/admin_reviews/domain/entities/review.dart'
    as admin_review;
import 'package:equatable/equatable.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/entities/booking_details.dart';

abstract class BookingDetailsState extends Equatable {
  const BookingDetailsState();

  @override
  List<Object?> get props => [];
}

/// 🎬 الحالة الابتدائية
class BookingDetailsInitial extends BookingDetailsState {}

/// ⏳ حالة التحميل
class BookingDetailsLoading extends BookingDetailsState {}

/// ✅ حالة نجاح التحميل
class BookingDetailsLoaded extends BookingDetailsState {
  final Booking booking;
  final BookingDetails? bookingDetails;
  final List<Service> services;
  final bool isRefreshing;
  final admin_review.Review? review;

  const BookingDetailsLoaded({
    required this.booking,
    this.bookingDetails,
    required this.services,
    this.isRefreshing = false,
    this.review,
  });

  BookingDetailsLoaded copyWith({
    Booking? booking,
    BookingDetails? bookingDetails,
    List<Service>? services,
    bool? isRefreshing,
    admin_review.Review? review,
  }) {
    return BookingDetailsLoaded(
      booking: booking ?? this.booking,
      bookingDetails: bookingDetails ?? this.bookingDetails,
      services: services ?? this.services,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      review: review ?? this.review,
    );
  }

  @override
  List<Object?> get props =>
      [booking, bookingDetails, services, isRefreshing, review];
}

/// ❌ حالة الخطأ
class BookingDetailsError extends BookingDetailsState {
  final String message;

  const BookingDetailsError({required this.message});

  @override
  List<Object> get props => [message];
}

/// 🔄 حالة العملية الجارية
class BookingDetailsOperationInProgress extends BookingDetailsState {
  final Booking booking;
  final BookingDetails? bookingDetails;
  final List<Service> services;
  final String operation;

  const BookingDetailsOperationInProgress({
    required this.booking,
    this.bookingDetails,
    required this.services,
    required this.operation,
  });

  @override
  List<Object?> get props => [booking, bookingDetails, services, operation];
}

/// ✅ حالة نجاح العملية
class BookingDetailsOperationSuccess extends BookingDetailsState {
  final Booking booking;
  final BookingDetails? bookingDetails;
  final List<Service> services;
  final String message;

  const BookingDetailsOperationSuccess({
    required this.booking,
    this.bookingDetails,
    required this.services,
    required this.message,
  });

  BookingDetailsLoaded copyWith() {
    return BookingDetailsLoaded(
      booking: booking,
      bookingDetails: bookingDetails,
      services: services,
    );
  }

  @override
  List<Object?> get props => [booking, bookingDetails, services, message];
}

/// ❌ حالة فشل العملية
class BookingDetailsOperationFailure extends BookingDetailsState {
  final Booking booking;
  final BookingDetails? bookingDetails;
  final List<Service> services;
  final String message;

  const BookingDetailsOperationFailure({
    required this.booking,
    this.bookingDetails,
    required this.services,
    required this.message,
  });

  @override
  List<Object?> get props => [booking, bookingDetails, services, message];
}

/// 🖨️ حالة الطباعة
class BookingDetailsPrinting extends BookingDetailsState {
  final Booking booking;
  final BookingDetails? bookingDetails;
  final List<Service> services;

  const BookingDetailsPrinting({
    required this.booking,
    this.bookingDetails,
    required this.services,
  });

  @override
  List<Object?> get props => [booking, bookingDetails, services];
}

/// 📤 حالة المشاركة
class BookingDetailsSharing extends BookingDetailsState {
  final Booking booking;
  final BookingDetails? bookingDetails;
  final List<Service> services;

  const BookingDetailsSharing({
    required this.booking,
    this.bookingDetails,
    required this.services,
  });

  @override
  List<Object?> get props => [booking, bookingDetails, services];
}

/// 📧 حالة إرسال التأكيد
class BookingDetailsSendingConfirmation extends BookingDetailsState {
  final Booking booking;
  final BookingDetails? bookingDetails;
  final List<Service> services;

  const BookingDetailsSendingConfirmation({
    required this.booking,
    this.bookingDetails,
    required this.services,
  });

  @override
  List<Object?> get props => [booking, bookingDetails, services];
}
