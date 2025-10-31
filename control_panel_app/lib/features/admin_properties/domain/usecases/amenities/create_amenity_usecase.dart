// lib/features/admin_properties/domain/usecases/amenities/create_amenity_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/amenities_repository.dart';

class CreateAmenityParams {
  final String name;
  final String description;
  final String icon;
  
  CreateAmenityParams({
    required this.name,
    required this.description,
    required this.icon,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'icon': icon,
  };
}

class CreateAmenityUseCase implements UseCase<String, CreateAmenityParams> {
  final AmenitiesRepository repository;
  
  CreateAmenityUseCase(this.repository);
  
  @override
  Future<Either<Failure, String>> call(CreateAmenityParams params) async {
    return await repository.createAmenity(params.toJson());
  }
}