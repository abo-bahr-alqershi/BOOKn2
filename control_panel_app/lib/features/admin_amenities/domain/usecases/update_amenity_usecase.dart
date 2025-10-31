import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/amenities_repository.dart';

class UpdateAmenityUseCase implements UseCase<bool, UpdateAmenityParams> {
  final AmenitiesRepository repository;

  UpdateAmenityUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateAmenityParams params) async {
    return await repository.updateAmenity(
      amenityId: params.amenityId,
      name: params.name,
      description: params.description,
      icon: params.icon,
    );
  }
}

class UpdateAmenityParams extends Equatable {
  final String amenityId;
  final String? name;
  final String? description;
  final String? icon;

  const UpdateAmenityParams({
    required this.amenityId,
    this.name,
    this.description,
    this.icon,
  });

  @override
  List<Object?> get props => [amenityId, name, description, icon];
}