import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/unit_types_repository.dart';

class DeleteUnitTypeUseCase implements UseCase<bool, String> {
  final UnitTypesRepository repository;

  DeleteUnitTypeUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String unitTypeId) async {
    return await repository.deleteUnitType(unitTypeId);
  }
}