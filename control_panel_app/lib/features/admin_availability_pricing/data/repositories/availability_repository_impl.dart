// lib/features/admin_availability_pricing/data/repositories/availability_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/unit_availability.dart';
import '../../domain/entities/booking_conflict.dart';
import '../../domain/repositories/availability_repository.dart' as availability_repo;
import '../datasources/availability_remote_datasource.dart';
import '../datasources/availability_local_datasource.dart';
import '../models/availability_model.dart';

class AvailabilityRepositoryImpl implements availability_repo.AvailabilityRepository {
  final AvailabilityRemoteDataSource remoteDataSource;
  final AvailabilityLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AvailabilityRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UnitAvailability>> getMonthlyAvailability(
    String unitId,
    int year,
    int month,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteAvailability = await remoteDataSource.getMonthlyAvailability(
          unitId,
          year,
          month,
        );
        
        // Cache the data
        await localDataSource.cacheMonthlyAvailability(
          unitId,
          year,
          month,
          remoteAvailability,
        );
        
        return Right(remoteAvailability);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final localAvailability = await localDataSource.getCachedMonthlyAvailability(
          unitId,
          year,
          month,
        );
        
        if (localAvailability != null) {
          return Right(localAvailability);
        } else {
          return const Left(CacheFailure('No cached data available'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, void>> updateAvailability(
    UnitAvailabilityEntry availability,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateAvailability(
          UnitAvailabilityEntryModel(
            availabilityId: availability.availabilityId,
            unitId: availability.unitId,
            startDate: availability.startDate,
            endDate: availability.endDate,
            status: availability.status,
            reason: availability.reason,
            notes: availability.notes,
            bookingId: availability.bookingId,
            createdBy: availability.createdBy,
            createdAt: availability.createdAt,
            updatedAt: availability.updatedAt,
          ),
        );
        
        // Clear related cache
        await localDataSource.clearCache();
        
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> bulkUpdateAvailability({
    required String unitId,
    required List<availability_repo.AvailabilityPeriod> periods,
    required bool overwriteExisting,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.bulkUpdateAvailability(
          unitId,
          periods,
          overwriteExisting,
        );
        
        // Clear related cache
        await localDataSource.clearCache();
        
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> cloneAvailability({
    required String unitId,
    required DateTime sourceStartDate,
    required DateTime sourceEndDate,
    required DateTime targetStartDate,
    required int repeatCount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.cloneAvailability(
          unitId: unitId,
          sourceStartDate: sourceStartDate,
          sourceEndDate: sourceEndDate,
          targetStartDate: targetStartDate,
          repeatCount: repeatCount,
        );
        
        // Clear related cache
        await localDataSource.clearCache();
        
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAvailability({
    required String unitId,
    String? availabilityId,
    DateTime? startDate,
    DateTime? endDate,
    bool? forceDelete,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteAvailability(
          unitId: unitId,
          availabilityId: availabilityId,
          startDate: startDate,
          endDate: endDate,
          forceDelete: forceDelete,
        );
        
        // Clear related cache
        await localDataSource.clearCache();
        
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, availability_repo.CheckAvailabilityResponse>> checkAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    int? adults,
    int? children,
    bool? includePricing,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.checkAvailability(
          unitId: unitId,
          checkIn: checkIn,
          checkOut: checkOut,
          adults: adults,
          children: children,
          includePricing: includePricing,
        );
        
        return Right(response);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<BookingConflict>>> checkConflicts({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    String? startTime,
    String? endTime,
    required String checkType,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final conflicts = await remoteDataSource.checkConflicts(
          unitId: unitId,
          startDate: startDate,
          endDate: endDate,
          startTime: startTime,
          endTime: endTime,
          checkType: checkType,
        );
        
        return Right(conflicts);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}