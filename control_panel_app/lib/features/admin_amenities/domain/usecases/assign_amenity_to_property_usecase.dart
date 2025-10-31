import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/amenities_repository.dart';

class AssignAmenityToPropertyUseCase
    implements UseCase<bool, AssignAmenityParams> {
  final AmenitiesRepository repository;

  AssignAmenityToPropertyUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(AssignAmenityParams params) async {
    return await repository.assignAmenityToProperty(
      amenityId: params.amenityId,
      propertyId: params.propertyId,
      isAvailable: params.isAvailable,
      extraCost: params.extraCost,
      description: params.description,
    );
  }
}

class AssignAmenityParams extends Equatable {
  final String amenityId;
  final String propertyId;
  final bool isAvailable;
  final double? extraCost;
  final String? description;

  const AssignAmenityParams({
    required this.amenityId,
    required this.propertyId,
    this.isAvailable = true,
    this.extraCost,
    this.description,
  });

  @override
  List<Object?> get props => [
        amenityId,
        propertyId,
        isAvailable,
        extraCost,
        description,
      ];
}