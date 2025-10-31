// lib/features/admin_properties/domain/usecases/amenities/delete_amenity_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/amenities_repository.dart';

class DeleteAmenityUseCase implements UseCase<bool, String> {
  final AmenitiesRepository repository;
  
  DeleteAmenityUseCase(this.repository);
  
  @override
  Future<Either<Failure, bool>> call(String amenityId) async {
    return await repository.deleteAmenity(amenityId);
  }
}