import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_request.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class CreateBookingEvent extends BookingEvent {
  final BookingRequest bookingRequest;

  const CreateBookingEvent({required this.bookingRequest});

  @override
  List<Object> get props => [bookingRequest];
}

class GetBookingDetailsEvent extends BookingEvent {
  final String bookingId;
  final String userId;

  const GetBookingDetailsEvent({
    required this.bookingId,
    required this.userId,
  });

  @override
  List<Object> get props => [bookingId, userId];
}

class CancelBookingEvent extends BookingEvent {
  final String bookingId;
  final String userId;
  final String reason;

  const CancelBookingEvent({
    required this.bookingId,
    required this.userId,
    required this.reason,
  });

  @override
  List<Object> get props => [bookingId, userId, reason];
}

class GetUserBookingsEvent extends BookingEvent {
  final String userId;
  final String? status;
  final int pageNumber;
  final int pageSize;
  final bool loadMore;

  const GetUserBookingsEvent({
    required this.userId,
    this.status,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.loadMore = false,
  });

  @override
  List<Object?> get props => [userId, status, pageNumber, pageSize, loadMore];
}

class GetUserBookingsSummaryEvent extends BookingEvent {
  final String userId;
  final int? year;

  const GetUserBookingsSummaryEvent({
    required this.userId,
    this.year,
  });

  @override
  List<Object?> get props => [userId, year];
}

class AddServicesToBookingEvent extends BookingEvent {
  final String bookingId;
  final String serviceId;
  final int quantity;

  const AddServicesToBookingEvent({
    required this.bookingId,
    required this.serviceId,
    required this.quantity,
  });

  @override
  List<Object> get props => [bookingId, serviceId, quantity];
}

class CheckAvailabilityEvent extends BookingEvent {
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestsCount;

  const CheckAvailabilityEvent({
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.guestsCount,
  });

  @override
  List<Object> get props => [unitId, checkIn, checkOut, guestsCount];
}

class UpdateBookingFormEvent extends BookingEvent {
  final Map<String, dynamic> formData;

  const UpdateBookingFormEvent({required this.formData});

  @override
  List<Object> get props => [formData];
}

class ResetBookingStateEvent extends BookingEvent {
  const ResetBookingStateEvent();
}

class ProcessBookingPaymentEvent extends BookingEvent {
  final String bookingId;
  final String userId;
  final double amount;
  final String paymentMethod;
  final Map<String, dynamic>? paymentDetails;

  const ProcessBookingPaymentEvent({
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    this.paymentDetails,
  });

  @override
  List<Object?> get props => [bookingId, userId, amount, paymentMethod, paymentDetails];
}