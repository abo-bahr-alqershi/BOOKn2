// lib/features/admin_properties/data/repositories/properties_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/network/network_info.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/properties_repository.dart';
import '../datasources/properties_remote_datasource.dart';
import '../datasources/properties_local_datasource.dart';
import '../models/property_model.dart';

class PropertiesRepositoryImpl implements PropertiesRepository {
  final PropertiesRemoteDataSource remoteDataSource;
  final PropertiesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  
  PropertiesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });
  
  @override
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
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAllProperties(
          pageNumber: pageNumber,
          pageSize: pageSize,
          searchTerm: searchTerm,
          propertyTypeId: propertyTypeId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          sortBy: sortBy,
          isAscending: isAscending,
          amenityIds: amenityIds,
          starRatings: starRatings,
          minAverageRating: minAverageRating,
          isApproved: isApproved,
          hasActiveBookings: hasActiveBookings,
        );
        
        // Cache the first page for offline access
        if (pageNumber == 1 || pageNumber == null) {
          await localDataSource.cacheProperties(result.items as List<PropertyModel>);
        }
        
        return Right(result as PaginatedResult<Property>);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final cachedProperties = await localDataSource.getCachedProperties();
        // Create a paginated result from cached data
        final paginatedResult = PaginatedResult<Property>(
          items: cachedProperties,
          pageNumber: 1,
          pageSize: cachedProperties.length == 0 ? 1 : cachedProperties.length,
          totalCount: cachedProperties.length,
        );
        return Right(paginatedResult);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }
  
  @override
  Future<Either<Failure, Property>> getPropertyById(String propertyId) async {
    if (await networkInfo.isConnected) {
      try {
        final property = await remoteDataSource.getPropertyById(propertyId);
        await localDataSource.cacheProperty(property);
        return Right(property);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final cachedProperty = await localDataSource.getCachedPropertyById(propertyId);
        if (cachedProperty != null) {
          return Right(cachedProperty);
        } else {
          return Left(CacheFailure('Property not found in cache'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }
  
  @override
  Future<Either<Failure, Property>> getPropertyDetails(
    String propertyId, {
    bool includeUnits = false,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final property = await remoteDataSource.getPropertyDetails(
          propertyId,
          includeUnits: includeUnits,
        );
        return Right(property);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Property>> getPropertyDetailsPublic(String propertyId, {bool includeUnits = false}) async {
    if (await networkInfo.isConnected) {
      try {
        final property = await remoteDataSource.getPropertyDetailsPublic(
          propertyId,
          includeUnits: includeUnits,
        );
        return Right(property);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, String>> createProperty(Map<String, dynamic> propertyData) async {
    if (await networkInfo.isConnected) {
      try {
        final propertyId = await remoteDataSource.createProperty(propertyData);
        return Right(propertyId);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> updateProperty(
    String propertyId,
    Map<String, dynamic> propertyData,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.updateProperty(propertyId, propertyData);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> updatePropertyAsOwner(String propertyId, Map<String, dynamic> propertyData) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.updatePropertyAsOwner(propertyId, propertyData);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> deleteProperty(String propertyId) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.deleteProperty(propertyId);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> approveProperty(String propertyId) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.approveProperty(propertyId);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> rejectProperty(String propertyId) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.rejectProperty(propertyId);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, PaginatedResult<Property>>> getPendingProperties({
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPendingProperties(
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
        return Right(result as PaginatedResult<Property>);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> addPropertyToSections(
    String propertyId,
    List<String> sectionIds,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.addPropertyToSections(propertyId, sectionIds);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
}