// lib/features/admin_properties/domain/usecases/amenities/get_amenities_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../entities/amenity.dart';
import '../../repositories/amenities_repository.dart';

class GetAmenitiesParams {
  final int? pageNumber;
  final int? pageSize;
  final String? searchTerm;
  final String? propertyId;
  final bool? isAssigned;
  final bool? isFree;
  final String? propertyTypeId;
  
  GetAmenitiesParams({
    this.pageNumber = 1,
    this.pageSize = 10,
    this.searchTerm,
    this.propertyId,
    this.isAssigned,
    this.isFree,
    this.propertyTypeId,
  });
}

class GetAmenitiesUseCase implements UseCase<PaginatedResult<Amenity>, GetAmenitiesParams> {
  final AmenitiesRepository repository;
  
  GetAmenitiesUseCase(this.repository);
  
  @override
  Future<Either<Failure, PaginatedResult<Amenity>>> call(GetAmenitiesParams params) async {
    return await repository.getAllAmenities(
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      searchTerm: params.searchTerm,
      propertyId: params.propertyId,
      isAssigned: params.isAssigned,
      isFree: params.isFree,
      propertyTypeId: params.propertyTypeId,
    );
  }
}