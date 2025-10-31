import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/policy.dart';
import '../repositories/policies_repository.dart';

class GetPoliciesByPropertyUseCase implements UseCase<List<Policy>, String> {
  final PoliciesRepository repository;

  GetPoliciesByPropertyUseCase(this.repository);

  @override
  Future<Either<Failure, List<Policy>>> call(String propertyId) async {
    return await repository.getPoliciesByProperty(propertyId);
  }
}
