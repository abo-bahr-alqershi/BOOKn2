import 'package:equatable/equatable.dart';
import '../../../../../core/enums/booking_status.dart';

/// 📋 Entity الحجز الأساسي
class Booking extends Equatable {
  final String id;
  final String userId;
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestsCount;
  final Money totalPrice;
  final BookingStatus status;
  final DateTime bookedAt;
  final String userName;
  final String unitName;

  // معلومات إضافية
  final String? userEmail;
  final String? userPhone;
  final String? unitImage;
  final String? propertyId;
  final String? propertyName;
  final String? notes;
  final String? specialRequests;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime? confirmedAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? bookingSource;
  final bool? isWalkIn;
  final String? paymentStatus;

  const Booking({
    required this.id,
    required this.userId,
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.guestsCount,
    required this.totalPrice,
    required this.status,
    required this.bookedAt,
    required this.userName,
    required this.unitName,
    this.userEmail,
    this.userPhone,
    this.unitImage,
    this.propertyId,
    this.propertyName,
    this.notes,
    this.specialRequests,
    this.cancellationReason,
    this.cancelledAt,
    this.confirmedAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.bookingSource,
    this.isWalkIn,
    this.paymentStatus,
  });

  /// حساب عدد الليالي
  int get nights {
    return checkOut.difference(checkIn).inDays;
  }

  /// التحقق من إمكانية الإلغاء
  bool get canCancel {
    return status == BookingStatus.pending || status == BookingStatus.confirmed;
  }

  /// التحقق من إمكانية التأكيد
  bool get canConfirm {
    return status == BookingStatus.pending;
  }

  /// التحقق من إمكانية تسجيل الوصول
  bool get canCheckIn {
    return status == BookingStatus.confirmed &&
        DateTime.now().isAfter(checkIn.subtract(const Duration(hours: 2)));
  }

  /// التحقق من إمكانية تسجيل المغادرة
  bool get canCheckOut {
    return status == BookingStatus.checkedIn;
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? unitId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestsCount,
    Money? totalPrice,
    BookingStatus? status,
    DateTime? bookedAt,
    String? userName,
    String? unitName,
    String? userEmail,
    String? userPhone,
    String? unitImage,
    String? propertyId,
    String? propertyName,
    String? notes,
    String? specialRequests,
    String? cancellationReason,
    DateTime? cancelledAt,
    DateTime? confirmedAt,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    String? bookingSource,
    bool? isWalkIn,
    String? paymentStatus,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      unitId: unitId ?? this.unitId,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guestsCount: guestsCount ?? this.guestsCount,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      bookedAt: bookedAt ?? this.bookedAt,
      userName: userName ?? this.userName,
      unitName: unitName ?? this.unitName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      unitImage: unitImage ?? this.unitImage,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      notes: notes ?? this.notes,
      specialRequests: specialRequests ?? this.specialRequests,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      bookingSource: bookingSource ?? this.bookingSource,
      isWalkIn: isWalkIn ?? this.isWalkIn,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        unitId,
        checkIn,
        checkOut,
        guestsCount,
        totalPrice,
        status,
        bookedAt,
        userName,
        unitName,
        userEmail,
        userPhone,
        unitImage,
        propertyId,
        propertyName,
        notes,
        specialRequests,
        cancellationReason,
        cancelledAt,
        confirmedAt,
        checkedInAt,
        checkedOutAt,
        bookingSource,
        isWalkIn,
        paymentStatus,
      ];
}

/// 💰 Entity للمبلغ المالي
class Money extends Equatable {
  final double amount;
  final String currency;
  final String formattedAmount;

  const Money({
    required this.amount,
    required this.currency,
    required this.formattedAmount,
  });

  Money copyWith({
    double? amount,
    String? currency,
    String? formattedAmount,
  }) {
    return Money(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      formattedAmount: formattedAmount ?? this.formattedAmount,
    );
  }

  @override
  List<Object> get props => [amount, currency, formattedAmount];
}
