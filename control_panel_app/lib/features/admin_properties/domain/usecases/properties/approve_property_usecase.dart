// lib/features/admin_properties/domain/usecases/properties/approve_property_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/properties_repository.dart';

class ApprovePropertyUseCase implements UseCase<bool, String> {
  final PropertiesRepository repository;
  
  ApprovePropertyUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(String propertyId) async {
    return await repository.approveProperty(propertyId);
  }
}