import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/property_types_repository.dart';

class DeletePropertyTypeUseCase implements UseCase<bool, String> {
  final PropertyTypesRepository repository;

  DeletePropertyTypeUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String propertyTypeId) async {
    return await repository.deletePropertyType(propertyTypeId);
  }
}