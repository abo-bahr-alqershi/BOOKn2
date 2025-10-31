import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yemen_booking_app/core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

class SearchPropertiesUseCase implements UseCase<PaginatedResult<SearchResult>, SearchPropertiesParams> {
  final SearchRepository repository;

  SearchPropertiesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<SearchResult>>> call(SearchPropertiesParams params) async {
    return await repository.searchProperties(
      searchTerm: params.searchTerm,
      city: params.city,
      propertyTypeId: params.propertyTypeId,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      minStarRating: params.minStarRating,
      requiredAmenities: params.requiredAmenities,
      unitTypeId: params.unitTypeId,
      serviceIds: params.serviceIds,
      dynamicFieldFilters: params.dynamicFieldFilters,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      guestsCount: params.guestsCount,
      latitude: params.latitude,
      longitude: params.longitude,
      radiusKm: params.radiusKm,
      preferredCurrency: params.preferredCurrency,
      sortBy: params.sortBy,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class SearchPropertiesParams extends Equatable {
  final String? searchTerm;
  final String? city;
  final String? propertyTypeId;
  final double? minPrice;
  final double? maxPrice;
  final int? minStarRating;
  final List<String>? requiredAmenities;
  final String? unitTypeId;
  final List<String>? serviceIds;
  final Map<String, dynamic>? dynamicFieldFilters;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guestsCount;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final String? preferredCurrency;
  final String? sortBy;
  final int pageNumber;
  final int pageSize;

  const SearchPropertiesParams({
    this.searchTerm,
    this.city,
    this.propertyTypeId,
    this.minPrice,
    this.maxPrice,
    this.minStarRating,
    this.requiredAmenities,
    this.unitTypeId,
    this.serviceIds,
    this.dynamicFieldFilters,
    this.checkIn,
    this.checkOut,
    this.guestsCount,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.preferredCurrency,
    this.sortBy,
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [
        searchTerm,
        city,
        propertyTypeId,
        minPrice,
        maxPrice,
        minStarRating,
        requiredAmenities,
        unitTypeId,
        serviceIds,
        dynamicFieldFilters,
        checkIn,
        checkOut,
        guestsCount,
        latitude,
        longitude,
        radiusKm,
        preferredCurrency,
        sortBy,
        pageNumber,
        pageSize,
      ];
}