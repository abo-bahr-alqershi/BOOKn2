/// features/payment/domain/usecases/process_payment_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction.dart';
import '../repositories/payment_repository.dart';

class ProcessPaymentUseCase implements UseCase<Transaction, ProcessPaymentParams> {
  final PaymentRepository repository;

  ProcessPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, Transaction>> call(ProcessPaymentParams params) async {
    // Validate payment details
    if (params.amount <= 0) {
      return const Left(ValidationFailure('مبلغ الدفع غير صالح'));
    }

    if (params.paymentMethod.isEmpty) {
      return const Left(ValidationFailure('طريقة الدفع مطلوبة'));
    }

    // Process payment based on method
    if (params.paymentMethod.toLowerCase().contains('credit')) {
      // Validate credit card details
      if (params.paymentDetails == null ||
          params.paymentDetails!['cardNumber'] == null ||
          params.paymentDetails!['cardNumber'].toString().isEmpty) {
        return const Left(ValidationFailure('رقم البطاقة مطلوب'));
      }
    } else if (params.paymentMethod.toLowerCase().contains('wallet')) {
      // Validate wallet details
      if (params.paymentDetails == null ||
          params.paymentDetails!['walletNumber'] == null ||
          params.paymentDetails!['walletNumber'].toString().isEmpty) {
        return const Left(ValidationFailure('رقم المحفظة مطلوب'));
      }
    }

    return await repository.processPayment(
      bookingId: params.bookingId,
      userId: params.userId,
      amount: params.amount,
      paymentMethod: params.paymentMethod,
      currency: params.currency,
      paymentDetails: params.paymentDetails,
    );
  }
}

class ProcessPaymentParams extends Equatable {
  final String bookingId;
  final String userId;
  final double amount;
  final String paymentMethod;
  final String currency;
  final Map<String, dynamic>? paymentDetails;

  const ProcessPaymentParams({
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