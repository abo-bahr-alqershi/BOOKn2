import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/policy.dart';
import '../repositories/policies_repository.dart';

class GetPoliciesByTypeUseCase implements UseCase<PaginatedResult<Policy>, GetPoliciesByTypeParams> {
  final PoliciesRepository repository;

  GetPoliciesByTypeUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Policy>>> call(GetPoliciesByTypeParams params) async {
    return await repository.getPoliciesByType(
      type: params.type,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetPoliciesByTypeParams extends Equatable {
  final PolicyType type;
  final int pageNumber;
  final int pageSize;

  const GetPoliciesByTypeParams({
    required this.type,
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [type, pageNumber, pageSize];
}
