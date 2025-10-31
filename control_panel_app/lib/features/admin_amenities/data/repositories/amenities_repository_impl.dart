import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/amenity.dart';
import '../../domain/repositories/amenities_repository.dart';
import '../datasources/amenities_remote_datasource.dart';

class AmenitiesRepositoryImpl implements AmenitiesRepository {
  final AmenitiesRemoteDataSource remoteDataSource;

  AmenitiesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> createAmenity({
    required String name,
    required String description,
    required String icon,
    String? propertyTypeId,
    bool isDefaultForType = false,
  }) async {
    try {
      final result = await remoteDataSource.createAmenity(
        name: name,
        description: description,
        icon: icon,
        propertyTypeId: propertyTypeId,
        isDefaultForType: isDefaultForType,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateAmenity({
    required String amenityId,
    String? name,
    String? description,
    String? icon,
  }) async {
    try {
      final result = await remoteDataSource.updateAmenity(
        amenityId: amenityId,
        name: name,
        description: description,
        icon: icon,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAmenity(String amenityId) async {
    try {
      final result = await remoteDataSource.deleteAmenity(amenityId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Amenity>>> getAllAmenities({
    int? pageNumber,
    int? pageSize,
    String? searchTerm,
    String? propertyId,
    bool? isAssigned,
    bool? isFree,
    String? propertyTypeId,
  }) async {
    try {
      final result = await remoteDataSource.getAllAmenities(
        pageNumber: pageNumber,
        pageSize: pageSize,
        searchTerm: searchTerm,
        propertyId: propertyId,
        isAssigned: isAssigned,
        isFree: isFree,
        propertyTypeId: propertyTypeId,
      );

      return Right(PaginatedResult<Amenity>(
        items: result.items,
        totalCount: result.totalCount,
        pageNumber: result.pageNumber,
        pageSize: result.pageSize,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> assignAmenityToProperty({
    required String amenityId,
    required String propertyId,
    bool isAvailable = true,
    double? extraCost,
    String? description,
  }) async {
    try {
      final result = await remoteDataSource.assignAmenityToProperty(
        amenityId: amenityId,
        propertyId: propertyId,
        isAvailable: isAvailable,
        extraCost: extraCost,
        description: description,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AmenityStats>> getAmenityStats() async {
    try {
      final result = await remoteDataSource.getAmenityStats();
      return Right(AmenityStats(
        totalAmenities: result.totalAmenities,
        activeAmenities: result.activeAmenities,
        totalAssignments: result.totalAssignments,
        totalRevenue: result.totalRevenue,
        popularAmenities: result.popularAmenities,
        revenueByAmenity: result.revenueByAmenity,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleAmenityStatus(String amenityId) async {
    try {
      final result = await remoteDataSource.toggleAmenityStatus(amenityId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Amenity>>> getPopularAmenities({
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getPopularAmenities(limit: limit);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> assignAmenityToPropertyType({
    required String amenityId,
    required String propertyTypeId,
    bool isDefault = false,
  }) async {
    try {
      final result = await remoteDataSource.assignAmenityToPropertyType(
        amenityId: amenityId,
        propertyTypeId: propertyTypeId,
        isDefault: isDefault,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}