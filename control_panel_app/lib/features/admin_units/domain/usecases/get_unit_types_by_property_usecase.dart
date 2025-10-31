import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/unit_type.dart';
import '../repositories/units_repository.dart';

class GetUnitTypesByPropertyUseCase implements UseCase<List<UnitType>, String> {
  final UnitsRepository repository;

  GetUnitTypesByPropertyUseCase(this.repository);

  @override
  Future<Either<Failure, List<UnitType>>> call(String propertyTypeId) async {
    return await repository.getUnitTypesByProperty(propertyTypeId);
  }
}