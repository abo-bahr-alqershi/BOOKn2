// lib/features/admin_properties/domain/usecases/properties/get_property_details_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/property.dart';
import '../../repositories/properties_repository.dart';

class GetPropertyDetailsParams {
  final String propertyId;
  final bool includeUnits;
  
  GetPropertyDetailsParams({
    required this.propertyId,
    this.includeUnits = false,
  });
}

class GetPropertyDetailsUseCase implements UseCase<Property, GetPropertyDetailsParams> {
  final PropertiesRepository repository;
  
  GetPropertyDetailsUseCase(this.repository);
  
  @override
  Future<Either<Failure, Property>> call(GetPropertyDetailsParams params) async {
    return await repository.getPropertyDetails(
      params.propertyId,
      includeUnits: params.includeUnits,
    );
  }
}