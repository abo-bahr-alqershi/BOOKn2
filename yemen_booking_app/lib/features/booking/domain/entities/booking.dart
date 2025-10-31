import 'package:equatable/equatable.dart';
import 'package:yemen_booking_app/features/booking/domain/entities/payment.dart';
import '../../../../core/enums/booking_status.dart';

class Booking extends Equatable {
  final String id;
  final String bookingNumber;
  final String userId;
  final String userName;
  final String propertyId;
  final String propertyName;
  final String? propertyAddress;
  final String? unitId;
  final String? unitName;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfNights;
  final int adultGuests;
  final int childGuests;
  final int totalGuests;
  final double totalAmount;
  final double? platformCommissionAmount;
  final double? finalAmount;
  final String currency;
  final BookingStatus status;
  final DateTime bookingDate;
  final DateTime? actualCheckInDate;
  final DateTime? actualCheckOutDate;
  final String? specialRequests;
  final String? cancellationReason;
  final String? bookingSource;
  final bool isWalkIn;
  final int? customerRating;
  final String? completionNotes;
  final List<BookingService> services;
  final List<Payment> payments;
  final List<String> unitImages;
  final ContactInfo contactInfo;
  final bool canCancel;
  final bool canReview;
  final bool canModify;

  const Booking({
    required this.id,
    required this.bookingNumber,
    required this.userId,
    required this.userName,
    required this.propertyId,
    required this.propertyName,
    this.propertyAddress,
    this.unitId,
    this.unitName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfNights,
    required this.adultGuests,
    required this.childGuests,
    required this.totalGuests,
    required this.totalAmount,
    this.platformCommissionAmount,
    this.finalAmount,
    required this.currency,
    required this.status,
    required this.bookingDate,
    this.actualCheckInDate,
    this.actualCheckOutDate,
    this.specialRequests,
    this.cancellationReason,
    this.bookingSource,
    this.isWalkIn = false,
    this.customerRating,
    this.completionNotes,
    this.services = const [],
    this.payments = const [],
    this.unitImages = const [],
    required this.contactInfo,
    this.canCancel = false,
    this.canReview = false,
    this.canModify = false,
  });

  @override
  List<Object?> get props => [
        id,
        bookingNumber,
        userId,
        userName,
        propertyId,
        propertyName,
        propertyAddress,
        unitId,
        unitName,
        checkInDate,
        checkOutDate,
        numberOfNights,
        adultGuests,
        childGuests,
        totalGuests,
        totalAmount,
        platformCommissionAmount,
        finalAmount,
        currency,
        status,
        bookingDate,
        actualCheckInDate,
        actualCheckOutDate,
        specialRequests,
        cancellationReason,
        bookingSource,
        isWalkIn,
        customerRating,
        completionNotes,
        services,
        payments,
        unitImages,
        contactInfo,
        canCancel,
        canReview,
        canModify,
      ];
}

class BookingService extends Equatable {
  final String id;
  final String serviceId;
  final String serviceName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String currency;

  const BookingService({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.currency,
  });

  @override
  List<Object> get props => [
        id,
        serviceId,
        serviceName,
        quantity,
        unitPrice,
        totalPrice,
        currency,
      ];
}

class ContactInfo extends Equatable {
  final String phoneNumber;
  final String email;
  final String? alternativePhone;

  const ContactInfo({
    required this.phoneNumber,
    required this.email,
    this.alternativePhone,
  });

  @override
  List<Object?> get props => [
        phoneNumber,
        email,
        alternativePhone,
      ];
}