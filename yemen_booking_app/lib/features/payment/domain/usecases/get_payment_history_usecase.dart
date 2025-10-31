/// features/payment/domain/usecases/get_payment_history_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction.dart';
import '../repositories/payment_repository.dart';

class GetPaymentHistoryUseCase 
    implements UseCase<PaginatedResult<Transaction>, GetPaymentHistoryParams> {
  final PaymentRepository repository;

  GetPaymentHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Transaction>>> call(
      GetPaymentHistoryParams params) async {
    // Validate date range
    if (params.fromDate != null && params.toDate != null) {
      if (params.fromDate!.isAfter(params.toDate!)) {
        return const Left(ValidationFailure('تاريخ البداية يجب أن يكون قبل تاريخ النهاية'));
      }
    }

    // Validate amount range
    if (params.minAmount != null && params.maxAmount != null) {
      if (params.minAmount! > params.maxAmount!) {
        return const Left(ValidationFailure('الحد الأدنى للمبلغ يجب أن يكون أقل من الحد الأقصى'));
      }
    }

    // Validate pagination
    if (params.pageNumber < 1) {
      return const Left(ValidationFailure('رقم الصفحة غير صالح'));
    }

    if (params.pageSize < 1 || params.pageSize > 100) {
      return const Left(ValidationFailure('حجم الصفحة يجب أن يكون بين 1 و 100'));
    }

    return await repository.getPaymentHistory(
      userId: params.userId,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      status: params.status,
      paymentMethod: params.paymentMethod,
      fromDate: params.fromDate,
      toDate: params.toDate,
      minAmount: params.minAmount,
      maxAmount: params.maxAmount,
    );
  }
}

class GetPaymentHistoryParams extends Equatable {
  final String userId;
  final int pageNumber;
  final int pageSize;
  final String? status;
  final String? paymentMethod;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minAmount;
  final double? maxAmount;

  const GetPaymentHistoryParams({
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