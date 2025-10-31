// lib/features/admin_properties/data/repositories/amenities_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/network/network_info.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../domain/entities/amenity.dart';
import '../../domain/repositories/amenities_repository.dart';
import '../datasources/amenities_remote_datasource.dart';

class AmenitiesRepositoryImpl implements AmenitiesRepository {
  final AmenitiesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  
  AmenitiesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });
  
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
    if (await networkInfo.isConnected) {
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
        return Right(result as PaginatedResult<Amenity>);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, Amenity>> getAmenityById(String amenityId) async {
    if (await networkInfo.isConnected) {
      try {
        final amenity = await remoteDataSource.getAmenityById(amenityId);
        return Right(amenity);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, String>> createAmenity(Map<String, dynamic> data) async {
    if (await networkInfo.isConnected) {
      try {
        final id = await remoteDataSource.createAmenity(data);
        return Right(id);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> updateAmenity(String amenityId, Map<String, dynamic> data) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.updateAmenity(amenityId, data);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> deleteAmenity(String amenityId) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.deleteAmenity(amenityId);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> assignAmenityToProperty(
    String amenityId,
    String propertyId,
    Map<String, dynamic> data,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.assignAmenityToProperty(amenityId, propertyId, data);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> unassignAmenityFromProperty(
    String amenityId,
    String propertyId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.unassignAmenityFromProperty(amenityId, propertyId);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }
  
  @override
  Future<Either<Failure, List<Amenity>>> getPropertyAmenities(String propertyId) async {
    if (await networkInfo.isConnected) {
      try {
        final amenities = await remoteDataSource.getPropertyAmenities(propertyId);
        return Right(amenities);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
}