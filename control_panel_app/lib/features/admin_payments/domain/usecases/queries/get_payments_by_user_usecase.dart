import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/payment.dart';
import '../../repositories/payments_repository.dart';

class GetPaymentsByUserUseCase
    implements UseCase<PaginatedResult<Payment>, GetPaymentsByUserParams> {
  final PaymentsRepository repository;

  GetPaymentsByUserUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> call(
    GetPaymentsByUserParams params,
  ) async {
    return await repository.getPaymentsByUser(
      userId: params.userId,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetPaymentsByUserParams extends Equatable {
  final String userId;
  final int? pageNumber;
  final int? pageSize;

  const GetPaymentsByUserParams({
    required this.userId,
    this.pageNumber,
    this.pageSize,
  });

  @override
  List<Object?> get props => [userId, pageNumber, pageSize];
}
