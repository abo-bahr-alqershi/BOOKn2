// lib/features/admin_properties/domain/usecases/property_types/update_property_type_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/property_types_repository.dart';

class UpdatePropertyTypeParams {
  final String propertyTypeId;
  final String? name;
  final String? description;
  final String? defaultAmenities;
  final String? icon;
  
  UpdatePropertyTypeParams({
    required this.propertyTypeId,
    this.name,
    this.description,
    this.defaultAmenities,
    this.icon,
  });
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (defaultAmenities != null) data['defaultAmenities'] = defaultAmenities;
    if (icon != null) data['icon'] = icon;
    return data;
  }
}

class UpdatePropertyTypeUseCase implements UseCase<bool, UpdatePropertyTypeParams> {
  final PropertyTypesRepository repository;
  
  UpdatePropertyTypeUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(UpdatePropertyTypeParams params) async {
    return await repository.updatePropertyType(params.propertyTypeId, params.toJson());
  }
}