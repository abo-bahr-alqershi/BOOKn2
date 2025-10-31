// lib/features/admin_properties/domain/repositories/amenities_repository.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../entities/amenity.dart';

abstract class AmenitiesRepository {
  Future<Either<Failure, PaginatedResult<Amenity>>> getAllAmenities({
    int? pageNumber,
    int? pageSize,
    String? searchTerm,
    String? propertyId,
    bool? isAssigned,
    bool? isFree,
    String? propertyTypeId,
  });
  Future<Either<Failure, Amenity>> getAmenityById(String amenityId);
  Future<Either<Failure, String>> createAmenity(Map<String, dynamic> data);
  Future<Either<Failure, bool>> updateAmenity(String amenityId, Map<String, dynamic> data);
  Future<Either<Failure, bool>> deleteAmenity(String amenityId);
  Future<Either<Failure, bool>> assignAmenityToProperty(String amenityId, String propertyId, Map<String, dynamic> data);
  Future<Either<Failure, bool>> unassignAmenityFromProperty(String amenityId, String propertyId);
  Future<Either<Failure, List<Amenity>>> getPropertyAmenities(String propertyId);
}