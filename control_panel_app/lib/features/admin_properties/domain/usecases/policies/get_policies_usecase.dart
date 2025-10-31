// lib/features/admin_properties/domain/usecases/policies/get_policies_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/policy.dart';
import '../../repositories/policies_repository.dart';

class GetPoliciesParams {
  final String? propertyId;
  final PolicyType? policyType;
  final int? pageNumber;
  final int? pageSize;
  
  GetPoliciesParams({
    this.propertyId,
    this.policyType,
    this.pageNumber,
    this.pageSize,
  });
}

class GetPoliciesUseCase implements UseCase<List<Policy>, GetPoliciesParams> {
  final PoliciesRepository repository;
  
  GetPoliciesUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<Policy>>> call(GetPoliciesParams params) async {
    if (params.propertyId != null) {
      return await repository.getPropertyPolicies(params.propertyId!);
    } else {
      // If needed, get policies by type with pagination
      return Left(ValidationFailure('Property ID is required'));
    }
  }
}