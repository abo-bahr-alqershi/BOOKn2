import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/policy.dart';
import '../repositories/policies_repository.dart';

class GetPolicyByIdUseCase implements UseCase<Policy, String> {
  final PoliciesRepository repository;

  GetPolicyByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Policy>> call(String policyId) async {
    return await repository.getPolicyById(policyId);
  }
}
