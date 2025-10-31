import '../../../../../core/enums/booking_status.dart';
import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.unitId,
    required super.checkIn,
    required super.checkOut,
    required super.guestsCount,
    required super.totalPrice,
    required super.status,
    required super.bookedAt,
    required super.userName,
    required super.unitName,
    super.userEmail,
    super.userPhone,
    super.unitImage,
    super.propertyId,
    super.propertyName,
    super.notes,
    super.specialRequests,
    super.cancellationReason,
    super.cancelledAt,
    super.confirmedAt,
    super.checkedInAt,
    super.checkedOutAt,
    super.bookingSource,
    super.isWalkIn,
    super.paymentStatus,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      unitId: json['unitId']?.toString() ?? '',
      checkIn: DateTime.parse(json['checkIn']),
      checkOut: DateTime.parse(json['checkOut']),
      guestsCount: json['guestsCount'] ?? 1,
      totalPrice: MoneyModel.fromJson(
          Map<String, dynamic>.from(json['totalPrice'] ?? {})),
      status: _parseBookingStatus(json['status']),
      bookedAt: DateTime.parse(json['bookedAt'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()),
      userName: json['userName'] ?? '',
      unitName: json['unitName'] ?? '',
      userEmail: json['userEmail'],
      userPhone: json['userPhone'],
      unitImage: json['unitImage'],
      propertyId: json['propertyId']?.toString(),
      propertyName: json['propertyName'],
      notes: json['notes'],
      specialRequests: json['specialRequests'],
      cancellationReason: json['cancellationReason'],
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'])
          : null,
      checkedOutAt: json['checkedOutAt'] != null
          ? DateTime.parse(json['checkedOutAt'])
          : null,
      bookingSource: json['bookingSource'],
      isWalkIn: json['isWalkIn'],
      paymentStatus: json['paymentStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'unitId': unitId,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'guestsCount': guestsCount,
      'totalPrice': (totalPrice as MoneyModel).toJson(),
      'status': status.displayNameEn,
      'bookedAt': bookedAt.toIso8601String(),
      'userName': userName,
      'unitName': unitName,
      if (userEmail != null) 'userEmail': userEmail,
      if (userPhone != null) 'userPhone': userPhone,
      if (unitImage != null) 'unitImage': unitImage,
      if (propertyId != null) 'propertyId': propertyId,
      if (propertyName != null) 'propertyName': propertyName,
      if (notes != null) 'notes': notes,
      if (specialRequests != null) 'specialRequests': specialRequests,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
      if (confirmedAt != null) 'confirmedAt': confirmedAt!.toIso8601String(),
      if (checkedInAt != null) 'checkedInAt': checkedInAt!.toIso8601String(),
      if (checkedOutAt != null) 'checkedOutAt': checkedOutAt!.toIso8601String(),
      if (bookingSource != null) 'bookingSource': bookingSource,
      if (isWalkIn != null) 'isWalkIn': isWalkIn,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
    };
  }

  static BookingStatus _parseBookingStatus(dynamic status) {
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

  factory BookingModel.fromEntity(Booking entity) {
    return BookingModel(
      id: entity.id,
      userId: entity.userId,
      unitId: entity.unitId,
      checkIn: entity.checkIn,
      checkOut: entity.checkOut,
      guestsCount: entity.guestsCount,
      totalPrice: entity.totalPrice,
      status: entity.status,
      bookedAt: entity.bookedAt,
      userName: entity.userName,
      unitName: entity.unitName,
      userEmail: entity.userEmail,
      userPhone: entity.userPhone,
      unitImage: entity.unitImage,
      propertyId: entity.propertyId,
      propertyName: entity.propertyName,
      notes: entity.notes,
      specialRequests: entity.specialRequests,
      cancellationReason: entity.cancellationReason,
      cancelledAt: entity.cancelledAt,
      confirmedAt: entity.confirmedAt,
      checkedInAt: entity.checkedInAt,
      checkedOutAt: entity.checkedOutAt,
      bookingSource: entity.bookingSource,
      isWalkIn: entity.isWalkIn,
      paymentStatus: entity.paymentStatus,
    );
  }
}

/// 💰 Model للمبلغ المالي
class MoneyModel extends Money {
  const MoneyModel({
    required super.amount,
    required super.currency,
    required super.formattedAmount,
  });

  factory MoneyModel.fromJson(Map<String, dynamic> json) {
    return MoneyModel(
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'YER',
      formattedAmount: json['formattedAmount'] ??
          '${json['currency'] ?? 'YER'} ${(json['amount'] ?? 0).toStringAsFixed(2)}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'formattedAmount': formattedAmount,
    };
  }

  factory MoneyModel.fromEntity(Money entity) {
    return MoneyModel(
      amount: entity.amount,
      currency: entity.currency,
      formattedAmount: entity.formattedAmount,
    );
  }
}
