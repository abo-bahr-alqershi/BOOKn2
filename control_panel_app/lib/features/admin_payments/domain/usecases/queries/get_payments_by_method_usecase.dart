import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../../../../../core/enums/payment_method_enum.dart';
import '../../entities/payment.dart';
import '../../repositories/payments_repository.dart';

class GetPaymentsByMethodUseCase
    implements UseCase<PaginatedResult<Payment>, GetPaymentsByMethodParams> {
  final PaymentsRepository repository;

  GetPaymentsByMethodUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> call(
    GetPaymentsByMethodParams params,
  ) async {
    return await repository.getPaymentsByMethod(
      method: params.method,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetPaymentsByMethodParams extends Equatable {
  final PaymentMethod method;
  final int? pageNumber;
  final int? pageSize;

  const GetPaymentsByMethodParams({
    required this.method,
    this.pageNumber,
    this.pageSize,
  });

  @override
  List<Object?> get props => [method, pageNumber, pageSize];
}
