import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/units_repository.dart';

class DeleteUnitUseCase implements UseCase<bool, String> {
  final UnitsRepository repository;

  DeleteUnitUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String unitId) async {
    return await repository.deleteUnit(unitId);
  }
}