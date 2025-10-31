import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String bookingId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final PaymentStatus status;
  final DateTime paymentDate;
  final String? transactionId;
  final String? receiptUrl;
  final String? notes;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.paymentDate,
    this.transactionId,
    this.receiptUrl,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        amount,
        currency,
        paymentMethod,
        status,
        paymentDate,
        transactionId,
        receiptUrl,
        notes,
      ];
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
}