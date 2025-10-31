import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/policy.dart';
import '../repositories/policies_repository.dart';

class GetAllPoliciesUseCase implements UseCase<PaginatedResult<Policy>, GetAllPoliciesParams> {
  final PoliciesRepository repository;

  GetAllPoliciesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Policy>>> call(GetAllPoliciesParams params) async {
    return await repository.getAllPolicies(
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      searchTerm: params.searchTerm,
      propertyId: params.propertyId,
      policyType: params.policyType,
    );
  }
}

class GetAllPoliciesParams extends Equatable {
  final int pageNumber;
  final int pageSize;
  final String? searchTerm;
  final String? propertyId;
  final PolicyType? policyType;

  const GetAllPoliciesParams({
    this.pageNumber = 1,
    this.pageSize = 20,
    this.searchTerm,
    this.propertyId,
    this.policyType,
  });

  @override
  List<Object?> get props => [pageNumber, pageSize, searchTerm, propertyId, policyType];
}
