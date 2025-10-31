// filepath: /home/ameen/Desktop/BOOKIN/BOOKIN/control_panel_app/lib/features/admin_properties/domain/usecases/amenities/unassign_amenity_from_property_usecase.dart
// lib/features/admin_properties/domain/usecases/amenities/unassign_amenity_from_property_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/amenities_repository.dart';

class UnassignAmenityParams {
  final String amenityId;
  final String propertyId;

  UnassignAmenityParams({
    required this.amenityId,
    required this.propertyId,
  });
}

class UnassignAmenityFromPropertyUseCase
    implements UseCase<bool, UnassignAmenityParams> {
  final AmenitiesRepository repository;

  UnassignAmenityFromPropertyUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UnassignAmenityParams params) async {
    return await repository.unassignAmenityFromProperty(
      params.amenityId,
      params.propertyId,
    );
  }
}
