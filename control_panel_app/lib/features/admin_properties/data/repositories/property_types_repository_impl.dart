// lib/features/admin_properties/data/repositories/property_types_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/network/network_info.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/repositories/property_types_repository.dart';
import '../datasources/property_types_remote_datasource.dart';

class PropertyTypesRepositoryImpl implements PropertyTypesRepository {
  final PropertyTypesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  
  PropertyTypesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });
  
  @override
  Future<Either<Failure, PaginatedResult<PropertyType>>> getAllPropertyTypes({
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAllPropertyTypes(
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
        return Right(result as PaginatedResult<PropertyType>);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, PropertyType>> getPropertyTypeById(String propertyTypeId) async {
    if (await networkInfo.isConnected) {
      try {
        final propertyType = await remoteDataSource.getPropertyTypeById(propertyTypeId);
        return Right(propertyType);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, String>> createPropertyType(Map<String, dynamic> data) async {
    if (await networkInfo.isConnected) {
      try {
        final id = await remoteDataSource.createPropertyType(data);
        return Right(id);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> updatePropertyType(String propertyTypeId, Map<String, dynamic> data) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.updatePropertyType(propertyTypeId, data);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> deletePropertyType(String propertyTypeId) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.deletePropertyType(propertyTypeId);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
}