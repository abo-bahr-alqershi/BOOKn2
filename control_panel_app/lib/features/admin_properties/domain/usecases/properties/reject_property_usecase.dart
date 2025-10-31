// lib/features/admin_properties/domain/usecases/properties/reject_property_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/properties_repository.dart';

class RejectPropertyUseCase implements UseCase<bool, String> {
  final PropertiesRepository repository;
  
  RejectPropertyUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(String propertyId) async {
    return await repository.rejectProperty(propertyId);
  }
}