// lib/features/admin_properties/domain/usecases/amenities/update_amenity_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/amenities_repository.dart';

class UpdateAmenityParams {
  final String amenityId;
  final String? name;
  final String? description;
  final String? icon;
  
  UpdateAmenityParams({
    required this.amenityId,
    this.name,
    this.description,
    this.icon,
  });
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (icon != null) data['icon'] = icon;
    return data;
  }
}

class UpdateAmenityUseCase implements UseCase<bool, UpdateAmenityParams> {
  final AmenitiesRepository repository;
  
  UpdateAmenityUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(UpdateAmenityParams params) async {
    return await repository.updateAmenity(params.amenityId, params.toJson());
  }
}