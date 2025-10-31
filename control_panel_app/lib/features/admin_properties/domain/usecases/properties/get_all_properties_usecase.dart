// lib/features/admin_properties/domain/usecases/properties/get_all_properties_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../entities/property.dart';
import '../../repositories/properties_repository.dart';

class GetAllPropertiesParams {
  final int? pageNumber;
  final int? pageSize;
  final String? searchTerm;
  final String? propertyTypeId;
  final double? minPrice;
  final double? maxPrice;
  final String? sortBy;
  final bool? isAscending;
  final List<String>? amenityIds;
  final List<int>? starRatings;
  final double? minAverageRating;
  final bool? isApproved;
  final bool? hasActiveBookings;
  
  GetAllPropertiesParams({
    this.pageNumber = 1,
    this.pageSize = 1000,
    this.searchTerm,
    this.propertyTypeId,
    this.minPrice,
    this.maxPrice,
    this.sortBy,
    this.isAscending,
    this.amenityIds,
    this.starRatings,
    this.minAverageRating,
    this.isApproved,
    this.hasActiveBookings,
  });
}

class GetAllPropertiesUseCase implements UseCase<PaginatedResult<Property>, GetAllPropertiesParams> {
  final PropertiesRepository repository;
  
  GetAllPropertiesUseCase(this.repository);
  
  @override
  Future<Either<Failure, PaginatedResult<Property>>> call(GetAllPropertiesParams params) async {
    return await repository.getAllProperties(
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      searchTerm: params.searchTerm,
      propertyTypeId: params.propertyTypeId,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      sortBy: params.sortBy,
      isAscending: params.isAscending,
      amenityIds: params.amenityIds,
      starRatings: params.starRatings,
      minAverageRating: params.minAverageRating,
      isApproved: params.isApproved,
      hasActiveBookings: params.hasActiveBookings,
    );
  }
}