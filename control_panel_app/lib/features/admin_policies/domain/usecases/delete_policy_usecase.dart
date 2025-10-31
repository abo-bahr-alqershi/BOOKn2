import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/policies_repository.dart';

class DeletePolicyUseCase implements UseCase<void, String> {
  final PoliciesRepository repository;

  DeletePolicyUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String policyId) async {
    return await repository.deletePolicy(policyId);
  }
}
