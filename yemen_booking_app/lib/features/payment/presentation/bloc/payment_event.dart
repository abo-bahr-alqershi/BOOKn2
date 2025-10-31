/// features/payment/presentation/bloc/payment_event.dart

import 'package:equatable/equatable.dart';
import '../../../../core/enums/payment_method_enum.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class ProcessPaymentEvent extends PaymentEvent {
  final String bookingId;
  final String userId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String currency;
  final Map<String, dynamic>? paymentDetails;

  const ProcessPaymentEvent({
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.currency,
    this.paymentDetails,
  });

  @override
  List<Object?> get props => [
        bookingId,
        userId,
        amount,
        paymentMethod,
        currency,
        paymentDetails,
      ];
}

class GetPaymentHistoryEvent extends PaymentEvent {
  final String userId;
  final int pageNumber;
  final int pageSize;
  final String? status;
  final String? paymentMethod;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minAmount;
  final double? maxAmount;

  const GetPaymentHistoryEvent({
    required this.userId,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.status,
    this.paymentMethod,
    this.fromDate,
    this.toDate,
    this.minAmount,
    this.maxAmount,
  });

  @override
  List<Object?> get props => [
        userId,
        pageNumber,
        pageSize,
        status,
        paymentMethod,
        fromDate,
        toDate,
        minAmount,
        maxAmount,
      ];
}

class LoadMorePaymentHistoryEvent extends PaymentEvent {
  final String userId;
  final int pageSize;
  final String? status;
  final String? paymentMethod;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minAmount;
  final double? maxAmount;

  const LoadMorePaymentHistoryEvent({
    required this.userId,
    this.pageSize = 10,
    this.status,
    this.paymentMethod,
    this.fromDate,
    this.toDate,
    this.minAmount,
    this.maxAmount,
  });

  @override
  List<Object?> get props => [
        userId,
        pageSize,
        status,
        paymentMethod,
        fromDate,
        toDate,
        minAmount,
        maxAmount,
      ];
}

class SelectPaymentMethodEvent extends PaymentEvent {
  final PaymentMethod paymentMethod;

  const SelectPaymentMethodEvent({required this.paymentMethod});

  @override
  List<Object> get props => [paymentMethod];
}

class ValidatePaymentDetailsEvent extends PaymentEvent {
  final PaymentMethod paymentMethod;
  final String? cardNumber;
  final String? cardHolderName;
  final String? expiryDate;
  final String? cvv;
  final String? walletNumber;
  final String? walletPin;

  const ValidatePaymentDetailsEvent({
    required this.paymentMethod,
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.cvv,
    this.walletNumber,
    this.walletPin,
  });

  @override
  List<Object?> get props => [
        paymentMethod,
        cardNumber,
        cardHolderName,
        expiryDate,
        cvv,
        walletNumber,
        walletPin,
      ];
}

class ResetPaymentStateEvent extends PaymentEvent {
  const ResetPaymentStateEvent();
}

class RefundPaymentEvent extends PaymentEvent {
  final String transactionId;
  final String userId;
  final double amount;
  final String reason;

  const RefundPaymentEvent({
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.reason,
  });

  @override
  List<Object> get props => [transactionId, userId, amount, reason];
}