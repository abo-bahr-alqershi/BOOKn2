import 'package:equatable/equatable.dart';
import 'payment.dart';
import 'refund.dart';

/// 💳 Entity لتفاصيل الدفعة الكاملة
class PaymentDetails extends Equatable {
  final Payment payment;
  final List<Refund> refunds;
  final List<PaymentActivity> activities;
  final BookingInfo? bookingInfo;
  final CustomerInfo? customerInfo;
  final PaymentGatewayInfo? gatewayInfo;
  final Map<String, dynamic>? additionalData;

  const PaymentDetails({
    required this.payment,
    required this.refunds,
    required this.activities,
    this.bookingInfo,
    this.customerInfo,
    this.gatewayInfo,
    this.additionalData,
  });

  /// حساب إجمالي المسترد
  Money get totalRefunded {
    if (refunds.isEmpty) {
      return Money(
        amount: 0,
        currency: payment.amount.currency,
        formattedAmount: '${payment.amount.currency} 0.00',
      );
    }

    final total = refunds
        .where((r) => r.status == RefundStatus.completed)
        .fold(0.0, (sum, refund) => sum + refund.amount.amount);

    return Money(
      amount: total,
      currency: payment.amount.currency,
      formattedAmount: '${payment.amount.currency} ${total.toStringAsFixed(2)}',
    );
  }

  /// حساب المبلغ الصافي
  Money get netAmount {
    return payment.amount - totalRefunded;
  }

  /// التحقق من الاسترداد الكامل
  bool get isFullyRefunded {
    return totalRefunded.amount >= payment.amount.amount;
  }

  /// التحقق من الاسترداد الجزئي
  bool get isPartiallyRefunded {
    return totalRefunded.amount > 0 &&
        totalRefunded.amount < payment.amount.amount;
  }

  @override
  List<Object?> get props => [
        payment,
        refunds,
        activities,
        bookingInfo,
        customerInfo,
        gatewayInfo,
        additionalData,
      ];
}

/// 📝 نشاط الدفعة
class PaymentActivity extends Equatable {
  final String id;
  final String action;
  final String description;
  final DateTime timestamp;
  final String? userId;
  final String? userName;
  final Map<String, dynamic>? data;

  const PaymentActivity({
    required this.id,
    required this.action,
    required this.description,
    required this.timestamp,
    this.userId,
    this.userName,
    this.data,
  });

  @override
  List<Object?> get props => [
        id,
        action,
        description,
        timestamp,
        userId,
        userName,
        data,
      ];
}

/// 🏨 معلومات الحجز
class BookingInfo extends Equatable {
  final String bookingId;
  final String bookingReference;
  final DateTime checkIn;
  final DateTime checkOut;
  final String unitName;
  final String propertyName;
  final int guestsCount;

  const BookingInfo({
    required this.bookingId,
    required this.bookingReference,
    required this.checkIn,
    required this.checkOut,
    required this.unitName,
    required this.propertyName,
    required this.guestsCount,
  });

  @override
  List<Object> get props => [
        bookingId,
        bookingReference,
        checkIn,
        checkOut,
        unitName,
        propertyName,
        guestsCount,
      ];
}

/// 👤 معلومات العميل
class CustomerInfo extends Equatable {
  final String customerId;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? nationality;
  final Map<String, dynamic>? additionalInfo;

  const CustomerInfo({
    required this.customerId,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.nationality,
    this.additionalInfo,
  });

  @override
  List<Object?> get props => [
        customerId,
        name,
        email,
        phone,
        address,
        nationality,
        additionalInfo,
      ];
}

/// 🏦 معلومات بوابة الدفع
class PaymentGatewayInfo extends Equatable {
  final String gatewayName;
  final String gatewayTransactionId;
  final String? authorizationCode;
  final String? responseCode;
  final String? responseMessage;
  final Map<String, dynamic>? rawResponse;

  const PaymentGatewayInfo({
    required this.gatewayName,
    required this.gatewayTransactionId,
    this.authorizationCode,
    this.responseCode,
    this.responseMessage,
    this.rawResponse,
  });

  @override
  List<Object?> get props => [
        gatewayName,
        gatewayTransactionId,
        authorizationCode,
        responseCode,
        responseMessage,
        rawResponse,
      ];
}
