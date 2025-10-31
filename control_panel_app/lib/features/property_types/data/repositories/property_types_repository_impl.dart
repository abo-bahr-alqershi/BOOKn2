import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/network_info.dart';
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
    required int pageNumber,
    required int pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAllPropertyTypes(
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PropertyType>> getPropertyTypeById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPropertyTypeById(id);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, String>> createPropertyType({
    required String name,
    required String description,
    required List<String> defaultAmenities,
    required String icon,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.createPropertyType(
          name: name,
          description: description,
          defaultAmenities: defaultAmenities,
          icon: icon,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> updatePropertyType({
    required String propertyTypeId,
    required String name,
    required String description,
    required List<String> defaultAmenities,
    required String icon,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updatePropertyType(
          propertyTypeId: propertyTypeId,
          name: name,
          description: description,
          defaultAmenities: defaultAmenities,
          icon: icon,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deletePropertyType(String propertyTypeId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deletePropertyType(propertyTypeId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}