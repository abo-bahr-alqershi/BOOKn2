// lib/features/admin_properties/domain/usecases/properties/search_properties_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../entities/property.dart';
import '../../repositories/properties_repository.dart';

class SearchPropertiesParams {
  final String? city;
  final String? checkIn;
  final String? checkOut;
  final int? guestCount;
  final String? propertyTypeId;
  final int pageNumber;
  final int pageSize;
  final String? sortBy;
  final String sortDirection;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? amenityIds;
  final List<int>? starRatings;
  final double? minAverageRating;
  final String? searchTerm;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  
  SearchPropertiesParams({
    this.city,
    this.checkIn,
    this.checkOut,
    this.guestCount,
    this.propertyTypeId,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.sortBy,
    this.sortDirection = 'asc',
    this.minPrice,
    this.maxPrice,
    this.amenityIds,
    this.starRatings,
    this.minAverageRating,
    this.searchTerm,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });
}

class SearchPropertiesUseCase implements UseCase<PaginatedResult<Property>, SearchPropertiesParams> {
  final PropertiesRepository repository;
  
  SearchPropertiesUseCase(this.repository);
  
  @override
  Future<Either<Failure, PaginatedResult<Property>>> call(SearchPropertiesParams params) async {
    return await repository.getAllProperties(
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      searchTerm: params.searchTerm ?? params.city,
      propertyTypeId: params.propertyTypeId,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      sortBy: params.sortBy,
      isAscending: params.sortDirection.toLowerCase() == 'asc',
      amenityIds: params.amenityIds,
      starRatings: params.starRatings,
      minAverageRating: params.minAverageRating,
    );
  }
}