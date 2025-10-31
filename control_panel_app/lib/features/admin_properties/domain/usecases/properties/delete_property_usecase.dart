// lib/features/admin_properties/domain/usecases/properties/delete_property_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/properties_repository.dart';

class DeletePropertyUseCase implements UseCase<bool, String> {
  final PropertiesRepository repository;
  
  DeletePropertyUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(String propertyId) async {
    return await repository.deleteProperty(propertyId);
  }
}