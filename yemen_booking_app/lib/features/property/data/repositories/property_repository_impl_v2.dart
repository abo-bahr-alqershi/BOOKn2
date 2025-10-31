import 'package:dartz/dartz.dart';
import 'package:yemen_booking_app/core/error/error_handler.dart';
import 'package:yemen_booking_app/core/error/failures.dart';
import 'package:yemen_booking_app/core/network/network_info.dart';
import 'package:yemen_booking_app/features/property/domain/entities/property_detail.dart';
import '../../domain/repositories/property_repository.dart';
import '../../domain/entities/unit.dart' as entity;
import '../datasources/property_remote_datasource.dart' as ds;

class PropertyRepositoryImpl implements PropertyRepository {
  final ds.PropertyRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PropertyRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, bool>> addToFavorites({
    required String propertyId,
    required String userId,
    String? notes,
    DateTime? desiredVisitDate,
    double? expectedBudget,
    String currency = 'YER',
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.addToFavorites(
          propertyId: propertyId,
          userId: userId,
          notes: notes,
          desiredVisitDate: desiredVisitDate,
          expectedBudget: expectedBudget,
          currency: currency,
        );
        return Right(result);
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, bool>> removeFromFavorites({
    required String propertyId,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.removeFromFavorites(
          propertyId: propertyId,
          userId: userId,
        );
        return Right(result);
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateViewCount({
    required String propertyId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateViewCount(propertyId: propertyId);
        return Right(result);
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, List<PropertyReview>>> getPropertyReviews({
    required String propertyId,
    int pageNumber = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    bool withImagesOnly = false,
    String? userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPropertyReviews(
          propertyId: propertyId,
          pageNumber: pageNumber,
          pageSize: pageSize,
          sortBy: sortBy,
          sortDirection: sortDirection,
          withImagesOnly: withImagesOnly,
          userId: userId,
        );
        // Models extend domain entities, so direct cast is safe here
        return Right(result);
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, PropertyDetail>> getPropertyDetails({
    required String propertyId,
    String? userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPropertyDetails(
          propertyId: propertyId,
          userId: userId,
        );
        return Right(result);
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, List<entity.Unit>>> getPropertyUnits({
    required String propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    required int guestsCount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPropertyUnits(
          propertyId: propertyId,
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
          guestsCount: guestsCount,
        );
        return Right(result);
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }
}