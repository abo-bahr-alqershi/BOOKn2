import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/unit_type.dart';
import '../../domain/repositories/unit_types_repository.dart';
import '../datasources/unit_types_remote_datasource.dart';

class UnitTypesRepositoryImpl implements UnitTypesRepository {
  final UnitTypesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UnitTypesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PaginatedResult<UnitType>>> getUnitTypesByPropertyType({
    required String propertyTypeId,
    required int pageNumber,
    required int pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getUnitTypesByPropertyType(
          propertyTypeId: propertyTypeId,
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
  Future<Either<Failure, UnitType>> getUnitTypeById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getUnitTypeById(id);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, String>> createUnitType({
    required String propertyTypeId,
    required String name,
    required int maxCapacity,
    required String icon,
    double? systemCommissionRate,
    required bool isHasAdults,
    required bool isHasChildren,
    required bool isMultiDays,
    required bool isRequiredToDetermineTheHour,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.createUnitType(
          propertyTypeId: propertyTypeId,
          name: name,
          maxCapacity: maxCapacity,
          icon: icon,
          systemCommissionRate: systemCommissionRate,
          isHasAdults: isHasAdults,
          isHasChildren: isHasChildren,
          isMultiDays: isMultiDays,
          isRequiredToDetermineTheHour: isRequiredToDetermineTheHour,
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
  Future<Either<Failure, bool>> updateUnitType({
    required String unitTypeId,
    required String name,
    required int maxCapacity,
    required String icon,
    double? systemCommissionRate,
    required bool isHasAdults,
    required bool isHasChildren,
    required bool isMultiDays,
    required bool isRequiredToDetermineTheHour,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateUnitType(
          unitTypeId: unitTypeId,
          name: name,
          maxCapacity: maxCapacity,
          icon: icon,
          systemCommissionRate: systemCommissionRate,
          isHasAdults: isHasAdults,
          isHasChildren: isHasChildren,
          isMultiDays: isMultiDays,
          isRequiredToDetermineTheHour: isRequiredToDetermineTheHour,
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
  Future<Either<Failure, bool>> deleteUnitType(String unitTypeId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteUnitType(unitTypeId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}