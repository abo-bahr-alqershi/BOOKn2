import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../../../../../core/enums/payment_method_enum.dart';
import '../../entities/payment.dart';
import '../../repositories/payments_repository.dart';

class GetPaymentsByStatusUseCase
    implements UseCase<PaginatedResult<Payment>, GetPaymentsByStatusParams> {
  final PaymentsRepository repository;

  GetPaymentsByStatusUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> call(
    GetPaymentsByStatusParams params,
  ) async {
    return await repository.getPaymentsByStatus(
      status: params.status,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetPaymentsByStatusParams extends Equatable {
  final PaymentStatus status;
  final int? pageNumber;
  final int? pageSize;

  const GetPaymentsByStatusParams({
    required this.status,
    this.pageNumber,
    this.pageSize,
  });

  @override
  List<Object?> get props => [status, pageNumber, pageSize];
}
