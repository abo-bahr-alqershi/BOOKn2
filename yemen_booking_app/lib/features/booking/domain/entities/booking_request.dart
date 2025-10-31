import 'package:equatable/equatable.dart';

class BookingRequest extends Equatable {
  final String userId;
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestsCount;
  final List<BookingServiceRequest> services;
  final String? specialRequests;
  final String bookingSource;

  const BookingRequest({
    required this.userId,
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.guestsCount,
    this.services = const [],
    this.specialRequests,
    this.bookingSource = 'MobileApp',
  });

  @override
  List<Object?> get props => [
        userId,
        unitId,
        checkIn,
        checkOut,
        guestsCount,
        services,
        specialRequests,
        bookingSource,
      ];
}

class BookingServiceRequest extends Equatable {
  final String serviceId;
  final int quantity;

  const BookingServiceRequest({
    required this.serviceId,
    required this.quantity,
  });

  @override
  List<Object> get props => [serviceId, quantity];
}