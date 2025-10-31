// lib/features/admin_properties/domain/usecases/property_types/delete_property_type_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/property_types_repository.dart';

class DeletePropertyTypeUseCase implements UseCase<bool, String> {
  final PropertyTypesRepository repository;
  
  DeletePropertyTypeUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(String propertyTypeId) async {
    return await repository.deletePropertyType(propertyTypeId);
  }
}