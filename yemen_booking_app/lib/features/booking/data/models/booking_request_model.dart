import '../../domain/entities/booking_request.dart';

class BookingRequestModel extends BookingRequest {
  const BookingRequestModel({
    required super.userId,
    required super.unitId,
    required super.checkIn,
    required super.checkOut,
    required super.guestsCount,
    super.services,
    super.specialRequests,
    super.bookingSource,
  });

  factory BookingRequestModel.fromEntity(BookingRequest entity) {
    return BookingRequestModel(
      userId: entity.userId,
      unitId: entity.unitId,
      checkIn: entity.checkIn,
      checkOut: entity.checkOut,
      guestsCount: entity.guestsCount,
      services: entity.services,
      specialRequests: entity.specialRequests,
      bookingSource: entity.bookingSource,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'unitId': unitId,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'guestsCount': guestsCount,
      'services': services
          .map((e) => BookingServiceRequestModel.fromEntity(e).toJson())
          .toList(),
      'specialRequests': specialRequests,
      'bookingSource': bookingSource,
    };
  }
}

class BookingServiceRequestModel extends BookingServiceRequest {
  const BookingServiceRequestModel({
    required super.serviceId,
    required super.quantity,
  });

  factory BookingServiceRequestModel.fromEntity(BookingServiceRequest entity) {
    return BookingServiceRequestModel(
      serviceId: entity.serviceId,
      quantity: entity.quantity,
    );
  }

  factory BookingServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return BookingServiceRequestModel(
      serviceId: json['serviceId'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'quantity': quantity,
    };
  }
}