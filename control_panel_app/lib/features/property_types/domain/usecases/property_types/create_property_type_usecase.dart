import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/property_types_repository.dart';

class CreatePropertyTypeUseCase implements UseCase<String, CreatePropertyTypeParams> {
  final PropertyTypesRepository repository;

  CreatePropertyTypeUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreatePropertyTypeParams params) async {
    return await repository.createPropertyType(
      name: params.name,
      description: params.description,
      defaultAmenities: params.defaultAmenities,
      icon: params.icon,
    );
  }
}

class CreatePropertyTypeParams extends Equatable {
  final String name;
  final String description;
  final List<String> defaultAmenities;
  final String icon;

  const CreatePropertyTypeParams({
    required this.name,
    required this.description,
    required this.defaultAmenities,
    required this.icon,
  });

  @override
  List<Object> get props => [name, description, defaultAmenities, icon];
}