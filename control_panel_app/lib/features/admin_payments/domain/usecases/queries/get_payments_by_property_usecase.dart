import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/payment.dart';
import '../../repositories/payments_repository.dart';

class GetPaymentsByPropertyUseCase
    implements UseCase<PaginatedResult<Payment>, GetPaymentsByPropertyParams> {
  final PaymentsRepository repository;

  GetPaymentsByPropertyUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> call(
    GetPaymentsByPropertyParams params,
  ) async {
    return await repository.getPaymentsByProperty(
      propertyId: params.propertyId,
      startDate: params.startDate,
      endDate: params.endDate,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetPaymentsByPropertyParams extends Equatable {
  final String propertyId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? pageNumber;
  final int? pageSize;

  const GetPaymentsByPropertyParams({
    required this.propertyId,
    this.startDate,
    this.endDate,
    this.pageNumber,
    this.pageSize,
  });

  @override
  List<Object?> get props => [
        propertyId,
        startDate,
        endDate,
        pageNumber,
        pageSize,
      ];
}
