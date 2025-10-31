// lib/features/admin_properties/domain/repositories/policies_repository.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../entities/policy.dart';

abstract class PoliciesRepository {
  Future<Either<Failure, List<Policy>>> getPropertyPolicies(String propertyId);
  Future<Either<Failure, Policy>> getPolicyById(String policyId);
  Future<Either<Failure, String>> createPolicy(Map<String, dynamic> data);
  Future<Either<Failure, bool>> updatePolicy(String policyId, Map<String, dynamic> data);
  Future<Either<Failure, bool>> deletePolicy(String policyId);
  Future<Either<Failure, PaginatedResult<Policy>>> getPoliciesByType({
    required String policyType,
    int? pageNumber,
    int? pageSize,
  });
}