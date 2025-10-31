// lib/features/admin_properties/domain/usecases/properties/get_property_details_public_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/property.dart';
import '../../repositories/properties_repository.dart';

class GetPropertyDetailsPublicParams {
  final String propertyId;
  final bool includeUnits;

  GetPropertyDetailsPublicParams({
    required this.propertyId,
    this.includeUnits = false,
  });
}

class GetPropertyDetailsPublicUseCase implements UseCase<Property, GetPropertyDetailsPublicParams> {
  final PropertiesRepository repository;

  GetPropertyDetailsPublicUseCase(this.repository);

  @override
  Future<Either<Failure, Property>> call(GetPropertyDetailsPublicParams params) async {
    return await repository.getPropertyDetailsPublic(
      params.propertyId,
      includeUnits: params.includeUnits,
    );
  }
}
