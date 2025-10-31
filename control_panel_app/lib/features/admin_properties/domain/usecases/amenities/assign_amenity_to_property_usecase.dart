// lib/features/admin_properties/domain/usecases/amenities/assign_amenity_to_property_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/amenities_repository.dart';

class AssignAmenityParams {
  final String amenityId;
  final String propertyId;
  final bool isAvailable;
  final double? extraCost;
  final String? currency;
  final String? description;
  
  AssignAmenityParams({
    required this.amenityId,
    required this.propertyId,
    this.isAvailable = true,
    this.extraCost,
    this.currency,
    this.description,
  });
  
  Map<String, dynamic> toJson() => {
    'isAvailable': isAvailable,
    if (extraCost != null) 'extraCost': {
      'amount': extraCost,
      'currency': currency ?? 'YER',
    },
    if (description != null) 'description': description,
  };
}

class AssignAmenityToPropertyUseCase implements UseCase<bool, AssignAmenityParams> {
  final AmenitiesRepository repository;
  
  AssignAmenityToPropertyUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(AssignAmenityParams params) async {
    return await repository.assignAmenityToProperty(
      params.amenityId,
      params.propertyId,
      params.toJson(),
    );
  }
}