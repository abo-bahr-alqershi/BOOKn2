import 'package:bookn_cp_app/features/admin_payments/data/models/money_model.dart';

import '../../../../../core/enums/payment_method_enum.dart';
import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.bookingId,
    required super.amount,
    required super.transactionId,
    required super.method,
    required super.status,
    required super.paymentDate,
    super.userId,
    super.userName,
    super.userEmail,
    super.unitId,
    super.unitName,
    super.propertyId,
    super.propertyName,
    super.description,
    super.notes,
    super.receiptUrl,
    super.invoiceNumber,
    super.metadata,
    super.isRefundable,
    super.refundDeadline,
    super.refundedAmount,
    super.refundedAt,
    super.refundReason,
    super.refundTransactionId,
    super.isVoided,
    super.voidedAt,
    super.voidReason,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    // Parse amount and currency separately - Handle backend PaymentDto structure
    final amountValue = json['amount'] ?? json['Amount'];
    final currencyValue = json['currency'] ?? json['Currency'];

    // Create Money object based on amount type
    final Money money;
    if (amountValue is num && amountValue > 0) {
      // Amount is a direct number from backend PaymentDto
      final currency = currencyValue?.toString().toUpperCase() ?? 'YER';
      money = MoneyModel(
        amount: amountValue.toDouble(),
        currency: currency,
        formattedAmount:
            '$currency ${amountValue.toStringAsFixed(currency == "USD" ? 2 : 0)}',
      );
    } else if (amountValue is Map<String, dynamic>) {
      // Amount is already a Money object
      money = MoneyModel.fromJson(amountValue);
    } else {
      // Fallback - try to parse as string or default to 0
      double parsedAmount = 0;
      if (amountValue != null) {
        try {
          parsedAmount = double.parse(amountValue.toString());
        } catch (e) {
          // Failed to parse amount
        }
      }
      final currency = currencyValue?.toString().toUpperCase() ?? 'YER';
      money = MoneyModel(
        amount: parsedAmount,
        currency: currency,
        formattedAmount:
            '$currency ${parsedAmount.toStringAsFixed(currency == "USD" ? 2 : 0)}',
      );
    }

    // Parse transaction ID - handle multiple possible field names from .NET backend
    String transactionId = '';
    final possibleTransactionIdFields = [
      'transactionId',
      'TransactionId',
      'transaction_id',
      'transactionID',
      'TransactionID'
    ];

    for (final field in possibleTransactionIdFields) {
      if (json.containsKey(field) &&
          json[field] != null &&
          json[field].toString().isNotEmpty) {
        transactionId = json[field].toString();
        break;
      }
    }

    // Parse payment method - handle both 'method' and 'Method' fields
    final methodValue = json['method'] ?? json['Method'];
    final parsedMethod = _parsePaymentMethod(methodValue);

    return PaymentModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      bookingId:
          json['bookingId']?.toString() ?? json['BookingId']?.toString() ?? '',
      amount: money,
      transactionId: transactionId,
      method: parsedMethod,
      status: _parsePaymentStatus(json['status'] ?? json['Status']),
      paymentDate: _parseDateTime(json['paymentDate'] ?? json['PaymentDate']) ??
          DateTime.now(),
      userId: json['userId']?.toString() ?? json['UserId']?.toString(),
      userName: json['userName'] ?? json['UserName'],
      userEmail: json['userEmail'] ?? json['UserEmail'],
      unitId: json['unitId']?.toString() ?? json['UnitId']?.toString(),
      unitName: json['unitName'] ?? json['UnitName'],
      propertyId:
          json['propertyId']?.toString() ?? json['PropertyId']?.toString(),
      propertyName: json['propertyName'] ?? json['PropertyName'],
      description: json['description'] ?? json['Description'],
      notes: json['notes'] ?? json['Notes'],
      receiptUrl: json['receiptUrl'] ?? json['ReceiptUrl'],
      invoiceNumber: json['invoiceNumber'] ?? json['InvoiceNumber'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRefundable: json['isRefundable'] ?? json['IsRefundable'],
      refundDeadline:
          _parseDateTime(json['refundDeadline'] ?? json['RefundDeadline']),
      refundedAmount:
          _parseDouble(json['refundedAmount'] ?? json['RefundedAmount']),
      refundedAt: _parseDateTime(json['refundedAt'] ?? json['RefundedAt']),
      refundReason: json['refundReason'] ?? json['RefundReason'],
      refundTransactionId:
          json['refundTransactionId'] ?? json['RefundTransactionId'],
      isVoided: json['isVoided'] ?? json['IsVoided'],
      voidedAt: _parseDateTime(json['voidedAt'] ?? json['VoidedAt']),
      voidReason: json['voidReason'] ?? json['VoidReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amount': (amount as MoneyModel).toJson(),
      'transactionId': transactionId,
      'method': method.backendValue,
      'status': status.backendKey,
      'paymentDate': paymentDate.toIso8601String(),
      if (userId != null) 'userId': userId,
      if (userName != null) 'userName': userName,
      if (userEmail != null) 'userEmail': userEmail,
      if (unitId != null) 'unitId': unitId,
      if (unitName != null) 'unitName': unitName,
      if (propertyId != null) 'propertyId': propertyId,
      if (propertyName != null) 'propertyName': propertyName,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
      if (metadata != null) 'metadata': metadata,
      if (isRefundable != null) 'isRefundable': isRefundable,
      if (refundDeadline != null)
        'refundDeadline': refundDeadline!.toIso8601String(),
      if (refundedAmount != null) 'refundedAmount': refundedAmount,
      if (refundedAt != null) 'refundedAt': refundedAt!.toIso8601String(),
      if (refundReason != null) 'refundReason': refundReason,
      if (refundTransactionId != null)
        'refundTransactionId': refundTransactionId,
      if (isVoided != null) 'isVoided': isVoided,
      if (voidedAt != null) 'voidedAt': voidedAt!.toIso8601String(),
      if (voidReason != null) 'voidReason': voidReason,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (e) {
      return 0.0;
    }
  }

  static PaymentMethod _parsePaymentMethod(dynamic method) {
    if (method == null) {
      return PaymentMethod.cash;
    }

    // Handle integer values (enum from backend)
    if (method is int) {
      return PaymentMethodExtension.fromBackendValue(method);
    }

    // Handle string values
    if (method is String) {
      // Try to parse as integer first (string representation of enum value)
      try {
        final intValue = int.parse(method);
        return PaymentMethodExtension.fromBackendValue(intValue);
      } catch (e) {
        // Not an integer, parse as string name
        return PaymentMethodExtension.fromString(method);
      }
    }

    return PaymentMethod.cash;
  }

  static PaymentStatus _parsePaymentStatus(dynamic status) {
    if (status == null) return PaymentStatus.pending;

    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'successful':
      case 'success':
        return PaymentStatus.successful;
      case 'failed':
      case 'failure':
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

  factory PaymentModel.fromEntity(Payment entity) {
    return PaymentModel(
      id: entity.id,
      bookingId: entity.bookingId,
      amount: entity.amount,
      transactionId: entity.transactionId,
      method: entity.method,
      status: entity.status,
      paymentDate: entity.paymentDate,
      userId: entity.userId,
      userName: entity.userName,
      userEmail: entity.userEmail,
      unitId: entity.unitId,
      unitName: entity.unitName,
      propertyId: entity.propertyId,
      propertyName: entity.propertyName,
      description: entity.description,
      notes: entity.notes,
      receiptUrl: entity.receiptUrl,
      invoiceNumber: entity.invoiceNumber,
      metadata: entity.metadata,
      isRefundable: entity.isRefundable,
      refundDeadline: entity.refundDeadline,
      refundedAmount: entity.refundedAmount,
      refundedAt: entity.refundedAt,
      refundReason: entity.refundReason,
      refundTransactionId: entity.refundTransactionId,
      isVoided: entity.isVoided,
      voidedAt: entity.voidedAt,
      voidReason: entity.voidReason,
    );
  }
}
