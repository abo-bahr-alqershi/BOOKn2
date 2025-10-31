// lib/features/admin_properties/domain/repositories/properties_repository.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../entities/property.dart';

abstract class PropertiesRepository {
  Future<Either<Failure, PaginatedResult<Property>>> getAllProperties({
    int? pageNumber,
    int? pageSize,
    String? searchTerm,
    String? propertyTypeId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool? isAscending,
    List<String>? amenityIds,
    List<int>? starRatings,
    double? minAverageRating,
    bool? isApproved,
    bool? hasActiveBookings,
  });
  
  Future<Either<Failure, Property>> getPropertyById(String propertyId);
  Future<Either<Failure, Property>> getPropertyDetails(String propertyId, {bool includeUnits = false});
  Future<Either<Failure, Property>> getPropertyDetailsPublic(String propertyId, {bool includeUnits = false});
  Future<Either<Failure, String>> createProperty(Map<String, dynamic> propertyData);
  Future<Either<Failure, bool>> updateProperty(String propertyId, Map<String, dynamic> propertyData);
  Future<Either<Failure, bool>> updatePropertyAsOwner(String propertyId, Map<String, dynamic> propertyData);
  Future<Either<Failure, bool>> deleteProperty(String propertyId);
  Future<Either<Failure, bool>> approveProperty(String propertyId);
  Future<Either<Failure, bool>> rejectProperty(String propertyId);
  Future<Either<Failure, PaginatedResult<Property>>> getPendingProperties({int? pageNumber, int? pageSize});
  Future<Either<Failure, bool>> addPropertyToSections(String propertyId, List<String> sectionIds);

}