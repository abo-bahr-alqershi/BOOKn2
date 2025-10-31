import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/amenity.dart';
import '../repositories/amenities_repository.dart';

class GetAllAmenitiesUseCase
    implements UseCase<PaginatedResult<Amenity>, GetAllAmenitiesParams> {
  final AmenitiesRepository repository;

  GetAllAmenitiesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Amenity>>> call(
      GetAllAmenitiesParams params) async {
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

class GetAllAmenitiesParams extends Equatable {
  final int? pageNumber;
  final int? pageSize;
  final String? searchTerm;
  final String? propertyId;
  final bool? isAssigned;
  final bool? isFree;
  final String? propertyTypeId;

  const GetAllAmenitiesParams({
    this.pageNumber = 1,
    this.pageSize = 10,
    this.searchTerm,
    this.propertyId,
    this.isAssigned,
    this.isFree,
    this.propertyTypeId,
  });

  @override
  List<Object?> get props => [
        pageNumber,
        pageSize,
        searchTerm,
        propertyId,
        isAssigned,
        isFree,
        propertyTypeId,
      ];
}