import '../../../../core/enums/payment_method_enum.dart';
import '../../domain/entities/booking.dart' show Money;
import '../../domain/entities/booking_details.dart' show Payment;

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.bookingId,
    required super.amount,
    required super.transactionId,
    required super.method,
    required super.status,
    required super.paymentDate,
    super.refundReason,
    super.refundedAt,
    super.receiptUrl,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    // Amount can come as:
    // - a number (PaymentDto.Amount)
    // - a Money object (amount: { amount, currency, ... })
    // - AmountMoney object (AmountMoney: { Amount, Currency, ... })
    final dynamic amountValue = json['amount'] ?? json['Amount'] ?? json['amountMoney'] ?? json['AmountMoney'];
    final String currencyFromRoot = (json['currency'] ?? json['Currency'])?.toString() ?? 'YER';

    Money amountMoney;
    if (amountValue is Map<String, dynamic>) {
      // Prefer explicit Money object
      amountMoney = MoneyModel.fromJson(amountValue);
    } else if (amountValue is num) {
      // Numeric amount with currency on root
      amountMoney = MoneyModel(
        amount: amountValue.toDouble(),
        currency: currencyFromRoot,
        formattedAmount: '${amountValue.toStringAsFixed(2)} $currencyFromRoot',
      );
    } else {
      // Fallback to zero amount with inferred currency
      amountMoney = MoneyModel(
        amount: 0,
        currency: currencyFromRoot,
        formattedAmount: '0.00 $currencyFromRoot',
      );
    }

    return PaymentModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      amount: amountMoney,
      transactionId: json['transactionId']?.toString() ?? '',
      method: _parsePaymentMethod(json['paymentMethod'] ?? json['method']),
      status: _parsePaymentStatus(json['status']),
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : DateTime.now(),
      refundReason: json['refundReason']?.toString(),
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'])
          : null,
      receiptUrl: json['receiptUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amount': (amount as MoneyModel).toJson(),
      'transactionId': transactionId,
      'method': method.toString().split('.').last,
      'status': status.toString().split('.').last,
      'paymentDate': paymentDate.toIso8601String(),
      'refundReason': refundReason,
      'refundedAt': refundedAt?.toIso8601String(),
      'receiptUrl': receiptUrl,
    };
  }

  static PaymentMethod _parsePaymentMethod(dynamic value) {
    if (value == null) return PaymentMethod.cash;
    
    if (value is int) {
      // Handle backend integer values
      switch (value) {
        case 1:
          return PaymentMethod.jwaliWallet;
        case 2:
          return PaymentMethod.cashWallet;
        case 3:
          return PaymentMethod.oneCashWallet;
        case 4:
          return PaymentMethod.floskWallet;
        case 5:
          return PaymentMethod.jaibWallet;
        case 6:
          return PaymentMethod.cash;
        case 7:
          return PaymentMethod.paypal;
        case 8:
          return PaymentMethod.creditCard;
        default:
          return PaymentMethod.cash;
      }
    }
    
    if (value is String) {
      // Handle string values
      return PaymentMethod.values.firstWhere(
        (method) => method.toString().split('.').last.toLowerCase() == value.toLowerCase(),
        orElse: () => PaymentMethod.cash,
      );
    }
    
    return PaymentMethod.cash;
  }

  static PaymentStatus _parsePaymentStatus(dynamic value) {
    if (value == null) return PaymentStatus.pending;
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'successful':
        case 'success':
          return PaymentStatus.successful;
        case 'failed':
        case 'fail':
          return PaymentStatus.failed;
        case 'pending':
          return PaymentStatus.pending;
        case 'refunded':
          return PaymentStatus.refunded;
        case 'voided':
          return PaymentStatus.voided;
        case 'partiallyrefunded':
        case 'partially_refunded':
          return PaymentStatus.partiallyRefunded;
        default:
          return PaymentStatus.pending;
      }
    }
    
    return PaymentStatus.pending;
  }
}

class MoneyModel extends Money {
  const MoneyModel({
    required super.amount,
    required super.currency,
    required super.formattedAmount,
  });

  factory MoneyModel.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] ?? 0).toDouble();
    final currency = json['currency']?.toString() ?? 'YER';
    
    return MoneyModel(
      amount: amount,
      currency: currency,
      formattedAmount: json['formattedAmount']?.toString() ?? 
                      '${amount.toStringAsFixed(2)} $currency',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'formattedAmount': formattedAmount,
    };
  }
}
