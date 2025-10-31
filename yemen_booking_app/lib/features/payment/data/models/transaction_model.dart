/// features/payment/data/models/transaction_model.dart

import '../../../../core/enums/payment_method_enum.dart';
import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.bookingId,
    required super.bookingNumber,
    required super.propertyName,
    required super.unitName,
    required super.amount,
    required super.currency,
    required super.paymentMethod,
    required super.status,
    required super.createdAt,
    super.processedAt,
    super.externalReference,
    super.invoiceNumber,
    super.notes,
    super.failureReason,
    required super.fees,
    required super.taxes,
    required super.netAmount,
    required super.canRefund,
    super.refundExpiryDate,
    super.transactionId,
    super.message,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      bookingNumber: json['bookingNumber'] ?? '',
      propertyName: json['propertyName'] ?? '',
      unitName: json['unitName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'YER',
      paymentMethod: PaymentMethodExtension.fromString(json['paymentMethod'] ?? 'cash'),
      status: PaymentStatusExtension.fromString(json['status'] ?? 'pending'),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt']) 
          : null,
      externalReference: json['externalReference'],
      invoiceNumber: json['invoiceNumber'],
      notes: json['notes'],
      failureReason: json['failureReason'],
      fees: (json['fees'] ?? 0).toDouble(),
      taxes: (json['taxes'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
      canRefund: json['canRefund'] ?? false,
      refundExpiryDate: json['refundExpiryDate'] != null 
          ? DateTime.parse(json['refundExpiryDate']) 
          : null,
      transactionId: json['transactionId'],
      message: json['message'],
    );
  }

  factory TransactionModel.fromProcessPaymentResponse(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['transactionId'] ?? '',
      bookingId: '', // Will be filled from request
      bookingNumber: '', // Will be filled from request
      propertyName: '', // Will be filled from request
      unitName: '', // Will be filled from request
      amount: (json['processedAmount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'YER',
      paymentMethod: PaymentMethod.cash, // Will be filled from request
      status: json['success'] == true 
          ? PaymentStatus.successful 
          : PaymentStatus.failed,
      createdAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt']) 
          : DateTime.now(),
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt']) 
          : null,
      fees: (json['fees'] ?? 0).toDouble(),
      taxes: 0,
      netAmount: (json['processedAmount'] ?? 0).toDouble() - (json['fees'] ?? 0).toDouble(),
      canRefund: json['success'] == true,
      transactionId: json['transactionId'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'bookingNumber': bookingNumber,
      'propertyName': propertyName,
      'unitName': unitName,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'externalReference': externalReference,
      'invoiceNumber': invoiceNumber,
      'notes': notes,
      'failureReason': failureReason,
      'fees': fees,
      'taxes': taxes,
      'netAmount': netAmount,
      'canRefund': canRefund,
      'refundExpiryDate': refundExpiryDate?.toIso8601String(),
      'transactionId': transactionId,
      'message': message,
    };
  }
}