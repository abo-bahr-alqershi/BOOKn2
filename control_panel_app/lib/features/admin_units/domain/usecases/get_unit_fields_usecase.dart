import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/unit_type.dart';
import '../repositories/units_repository.dart';

class GetUnitFieldsUseCase implements UseCase<List<UnitTypeField>, String> {
  final UnitsRepository repository;

  GetUnitFieldsUseCase(this.repository);

  @override
  Future<Either<Failure, List<UnitTypeField>>> call(String unitTypeId) async {
    return await repository.getUnitFields(unitTypeId);
  }
}