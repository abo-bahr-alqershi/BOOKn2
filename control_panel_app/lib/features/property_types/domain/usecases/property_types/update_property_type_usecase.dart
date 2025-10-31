import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/property_types_repository.dart';

class UpdatePropertyTypeUseCase implements UseCase<bool, UpdatePropertyTypeParams> {
  final PropertyTypesRepository repository;

  UpdatePropertyTypeUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdatePropertyTypeParams params) async {
    return await repository.updatePropertyType(
      propertyTypeId: params.propertyTypeId,
      name: params.name,
      description: params.description,
      defaultAmenities: params.defaultAmenities,
      icon: params.icon,
    );
  }
}

class UpdatePropertyTypeParams extends Equatable {
  final String propertyTypeId;
  final String name;
  final String description;
  final List<String> defaultAmenities;
  final String icon;

  const UpdatePropertyTypeParams({
    required this.propertyTypeId,
    required this.name,
    required this.description,
    required this.defaultAmenities,
    required this.icon,
  });

  @override
  List<Object> get props => [propertyTypeId, name, description, defaultAmenities, icon];
}