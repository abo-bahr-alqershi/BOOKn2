import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/property_types_with_units.dart';
import '../repositories/home_repository.dart';

class GetPropertyTypesWithUnitsUseCase implements UseCase<PropertyTypesWithUnits, NoParams> {
  final HomeRepository repository;
  GetPropertyTypesWithUnitsUseCase(this.repository);

  @override
  Future<Either<Failure, PropertyTypesWithUnits>> call(NoParams params) {
    return repository.getPropertyTypesWithUnits();
  }
}
