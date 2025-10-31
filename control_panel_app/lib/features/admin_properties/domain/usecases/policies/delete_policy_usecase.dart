// lib/features/admin_properties/domain/usecases/policies/delete_policy_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/policies_repository.dart';

class DeletePolicyUseCase implements UseCase<bool, String> {
  final PoliciesRepository repository;
  
  DeletePolicyUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(String policyId) async {
    return await repository.deletePolicy(policyId);
  }
}