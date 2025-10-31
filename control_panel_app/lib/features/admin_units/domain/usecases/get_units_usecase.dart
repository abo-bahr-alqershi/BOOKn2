import 'package:dartz/dartz.dart' hide Unit;
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/unit.dart';
import '../repositories/units_repository.dart';

class GetUnitsUseCase implements UseCase<PaginatedResult<Unit>, GetUnitsParams> {
  final UnitsRepository repository;

  GetUnitsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Unit>>> call(GetUnitsParams params) async {
    return await repository.getUnits(
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      propertyId: params.propertyId,
      unitTypeId: params.unitTypeId,
      isAvailable: params.isAvailable,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      searchQuery: params.searchQuery,
      pricingMethod: params.pricingMethod,
      checkInDate: params.checkInDate,
      checkOutDate: params.checkOutDate,
      numberOfGuests: params.numberOfGuests,
      hasActiveBookings: params.hasActiveBookings,
      location: params.location,
      sortBy: params.sortBy,
      latitude: params.latitude,
      longitude: params.longitude,
      radiusKm: params.radiusKm,
    );
  }
}

class GetUnitsParams extends Equatable {
  final int? pageNumber;
  final int? pageSize;
  final String? propertyId;
  final String? unitTypeId;
  final bool? isAvailable;
  final double? minPrice;
  final double? maxPrice;
  final String? searchQuery;
  final String? pricingMethod;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int? numberOfGuests;
  final bool? hasActiveBookings;
  final String? location;
  final String? sortBy;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;

  const GetUnitsParams({
    this.pageNumber,
    this.pageSize,
    this.propertyId,
    this.unitTypeId,
    this.isAvailable,
    this.minPrice,
    this.maxPrice,
    this.searchQuery,
    this.pricingMethod,
    this.checkInDate,
    this.checkOutDate,
    this.numberOfGuests,
    this.hasActiveBookings,
    this.location,
    this.sortBy,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  @override
  List<Object?> get props => [
        pageNumber,
        pageSize,
        propertyId,
        unitTypeId,
        isAvailable,
        minPrice,
        maxPrice,
        searchQuery,
      pricingMethod,
      checkInDate,
      checkOutDate,
      numberOfGuests,
      hasActiveBookings,
      location,
      sortBy,
      latitude,
      longitude,
      radiusKm,
      ];
}