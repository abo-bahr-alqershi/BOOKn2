/// features/payment/domain/repositories/payment_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/transaction.dart';

abstract class PaymentRepository {
  Future<Either<Failure, Transaction>> processPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String paymentMethod,
    required String currency,
    Map<String, dynamic>? paymentDetails,
  });

  Future<Either<Failure, PaginatedResult<Transaction>>> getPaymentHistory({
    required String userId,
    int pageNumber = 1,
    int pageSize = 10,
    String? status,
    String? paymentMethod,
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
  });
}