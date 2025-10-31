/// features/payment/domain/entities/transaction.dart

import 'package:equatable/equatable.dart';
import '../../../../core/enums/payment_method_enum.dart';

class Transaction extends Equatable {
  final String id;
  final String bookingId;
  final String bookingNumber;
  final String propertyName;
  final String unitName;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? externalReference;
  final String? invoiceNumber;
  final String? notes;
  final String? failureReason;
  final double fees;
  final double taxes;
  final double netAmount;
  final bool canRefund;
  final DateTime? refundExpiryDate;
  final String? transactionId;
  final String? message;

  const Transaction({
    required this.id,
    required this.bookingId,
    required this.bookingNumber,
    required this.propertyName,
    required this.unitName,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.externalReference,
    this.invoiceNumber,
    this.notes,
    this.failureReason,
    required this.fees,
    required this.taxes,
    required this.netAmount,
    required this.canRefund,
    this.refundExpiryDate,
    this.transactionId,
    this.message,
  });

  double get totalAmount => amount + fees + taxes;
  bool get isSuccessful => status == PaymentStatus.successful;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isRefunded => status == PaymentStatus.refunded || status == PaymentStatus.partiallyRefunded;

  @override
  List<Object?> get props => [
        id,
        bookingId,
        bookingNumber,
        propertyName,
        unitName,
        amount,
        currency,
        paymentMethod,
        status,
        createdAt,
        processedAt,
        externalReference,
        invoiceNumber,
        notes,
        failureReason,
        fees,
        taxes,
        netAmount,
        canRefund,
        refundExpiryDate,
        transactionId,
        message,
      ];
}