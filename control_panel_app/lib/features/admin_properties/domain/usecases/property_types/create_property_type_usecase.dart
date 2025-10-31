// lib/features/admin_properties/domain/usecases/property_types/create_property_type_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/property_types_repository.dart';

class CreatePropertyTypeParams {
  final String name;
  final String description;
  final String defaultAmenities;
  final String icon;
  
  CreatePropertyTypeParams({
    required this.name,
    required this.description,
    required this.defaultAmenities,
    required this.icon,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'defaultAmenities': defaultAmenities,
    'icon': icon,
  };
}

class CreatePropertyTypeUseCase implements UseCase<String, CreatePropertyTypeParams> {
  final PropertyTypesRepository repository;
  
  CreatePropertyTypeUseCase(this.repository);
  
  @override
  Future<Either<Failure, String>> call(CreatePropertyTypeParams params) async {
    return await repository.createPropertyType(params.toJson());
  }
}