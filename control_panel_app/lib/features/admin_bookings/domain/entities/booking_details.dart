import 'package:equatable/equatable.dart';
import '../../../../../core/enums/payment_method_enum.dart';
import 'booking.dart';

/// 📋 Entity لتفاصيل الحجز الكاملة
class BookingDetails extends Equatable {
  final Booking booking;
  final List<Payment> payments;
  final List<Service> services;
  final List<BookingActivity> activities;
  final GuestInfo? guestInfo;
  final UnitDetails? unitDetails;
  final PropertyDetails? propertyDetails;

  const BookingDetails({
    required this.booking,
    required this.payments,
    required this.services,
    this.activities = const [],
    this.guestInfo,
    this.unitDetails,
    this.propertyDetails,
  });

  /// حساب إجمالي المدفوعات
  Money get totalPaid {
    final total = payments
        .where((p) => p.status == PaymentStatus.successful)
        .fold(0.0, (sum, payment) => sum + payment.amount.amount);

    return Money(
      amount: total,
      currency: booking.totalPrice.currency,
      formattedAmount: _formatMoney(total, booking.totalPrice.currency),
    );
  }

  /// حساب المبلغ المتبقي
  Money get remainingAmount {
    final remaining = booking.totalPrice.amount - totalPaid.amount;
    return Money(
      amount: remaining,
      currency: booking.totalPrice.currency,
      formattedAmount: _formatMoney(remaining, booking.totalPrice.currency),
    );
  }

  /// التحقق من اكتمال الدفع
  bool get isFullyPaid {
    return remainingAmount.amount <= 0;
  }

  String _formatMoney(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
        booking,
        payments,
        services,
        activities,
        guestInfo,
        unitDetails,
        propertyDetails,
      ];
}

/// 💳 Entity للدفعة
class Payment extends Equatable {
  final String id;
  final String bookingId;
  final Money amount;
  final String transactionId;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime paymentDate;
  final String? refundReason;
  final DateTime? refundedAt;
  final String? receiptUrl;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.transactionId,
    required this.method,
    required this.status,
    required this.paymentDate,
    this.refundReason,
    this.refundedAt,
    this.receiptUrl,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        amount,
        transactionId,
        method,
        status,
        paymentDate,
        refundReason,
        refundedAt,
        receiptUrl,
      ];
}

/// 🛎️ Entity للخدمة
class Service extends Equatable {
  final String id;
  final String name;
  final String description;
  final Money price;
  final int quantity;
  final String? icon;
  final String? category;

  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    this.icon,
    this.category,
  });

  /// حساب السعر الإجمالي للخدمة
  Money get totalPrice {
    return Money(
      amount: price.amount * quantity,
      currency: price.currency,
      formattedAmount:
          '${price.currency} ${(price.amount * quantity).toStringAsFixed(2)}',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        quantity,
        icon,
        category,
      ];
}

/// 📝 Entity لنشاط الحجز
class BookingActivity extends Equatable {
  final String id;
  final String action;
  final String description;
  final DateTime timestamp;
  final String? userId;
  final String? userName;

  const BookingActivity({
    required this.id,
    required this.action,
    required this.description,
    required this.timestamp,
    this.userId,
    this.userName,
  });

  @override
  List<Object?> get props => [
        id,
        action,
        description,
        timestamp,
        userId,
        userName,
      ];
}

/// 👤 معلومات الضيف
class GuestInfo extends Equatable {
  final String name;
  final String email;
  final String phone;
  final String? nationality;
  final String? idNumber;
  final String? idType;
  final String? address;

  const GuestInfo({
    required this.name,
    required this.email,
    required this.phone,
    this.nationality,
    this.idNumber,
    this.idType,
    this.address,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        nationality,
        idNumber,
        idType,
        address,
      ];
}

/// 🏠 تفاصيل الوحدة
class UnitDetails extends Equatable {
  final String id;
  final String name;
  final String type;
  final int capacity;
  final List<String> amenities;
  final List<String> images;
  final String? description;
  final String? location;

  const UnitDetails({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.amenities,
    required this.images,
    this.description,
    this.location,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        capacity,
        amenities,
        images,
        description,
        location,
      ];
}

/// 🏢 تفاصيل العقار
class PropertyDetails extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final String? checkInTime;
  final String? checkOutTime;
  final Map<String, dynamic>? policies;

  const PropertyDetails({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.checkInTime,
    this.checkOutTime,
    this.policies,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phone,
        email,
        checkInTime,
        checkOutTime,
        policies,
      ];
}
