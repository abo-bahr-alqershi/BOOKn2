// lib/features/admin_availability_pricing/data/repositories/pricing_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/pricing.dart';
import '../../domain/entities/pricing_rule.dart';
import '../../domain/entities/seasonal_pricing.dart';
import '../../domain/repositories/pricing_repository.dart';
import '../datasources/pricing_remote_datasource.dart';

class PricingRepositoryImpl implements PricingRepository {
  final PricingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PricingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UnitPricing>> getMonthlyPricing(
    String unitId,
    int year,
    int month,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final pricing = await remoteDataSource.getMonthlyPricing(
          unitId,
          year,
          month,
        );
        return Right(pricing);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePricing({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
    required PriceType priceType,
    required String currency,
    required PricingTier pricingTier,
    double? percentageChange,
    double? minPrice,
    double? maxPrice,
    String? description,
    bool overwriteExisting = false,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updatePricing({
          'unitId': unitId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'price': price,
          'priceType': _priceTypeToString(priceType),
          'currency': currency,
          'pricingTier': _pricingTierToString(pricingTier),
          if (percentageChange != null) 'percentageChange': percentageChange,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
          if (description != null) 'description': description,
          'overwriteExisting': overwriteExisting,
        });
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> bulkUpdatePricing({
    required String unitId,
    required List<PricingPeriod> periods,
    required bool overwriteExisting,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.bulkUpdatePricing(
          unitId,
          periods,
          overwriteExisting,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> copyPricing({
    required String unitId,
    required DateTime sourceStartDate,
    required DateTime sourceEndDate,
    required DateTime targetStartDate,
    required int repeatCount,
    required String adjustmentType,
    required double adjustmentValue,
    required bool overwriteExisting,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.copyPricing({
          'unitId': unitId,
          'sourceStartDate': sourceStartDate.toIso8601String(),
          'sourceEndDate': sourceEndDate.toIso8601String(),
          'targetStartDate': targetStartDate.toIso8601String(),
          'repeatCount': repeatCount,
          'adjustmentType': adjustmentType,
          'adjustmentValue': adjustmentValue,
          'overwriteExisting': overwriteExisting,
        });
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePricing({
    required String unitId,
    String? pricingId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePricing(
          unitId: unitId,
          pricingId: pricingId,
          startDate: startDate,
          endDate: endDate,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<SeasonalPricing>>> getSeasonalPricing(
    String unitId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final seasons = await remoteDataSource.getSeasonalPricing(unitId);
        return Right(seasons);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> applySeasonalPricing({
    required String unitId,
    required List<SeasonalPricing> seasons,
    required String currency,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.applySeasonalPricing({
          'unitId': unitId,
          'seasons': seasons.map((s) => {
            'name': s.name,
            'type': s.type,
            'startDate': s.startDate.toIso8601String(),
            'endDate': s.endDate.toIso8601String(),
            'price': s.price,
            if (s.percentageChange != null) 'percentageChange': s.percentageChange,
            'priority': s.priority,
            'description': s.description,
          }).toList(),
          'currency': currency,
        });
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PricingBreakdown>> getPricingBreakdown({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final breakdown = await remoteDataSource.getPricingBreakdown(
          unitId: unitId,
          checkIn: checkIn,
          checkOut: checkOut,
        );
        return Right(breakdown);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  String _priceTypeToString(PriceType type) {
    switch (type) {
      case PriceType.base:
        return 'base';
      case PriceType.weekend:
        return 'weekend';
      case PriceType.seasonal:
        return 'seasonal';
      case PriceType.holiday:
        return 'holiday';
      case PriceType.specialEvent:
        return 'special_event';
      case PriceType.custom:
        return 'custom';
    }
  }

  String _pricingTierToString(PricingTier tier) {
    switch (tier) {
      case PricingTier.normal:
        return 'normal';
      case PricingTier.high:
        return 'high';
      case PricingTier.peak:
        return 'peak';
      case PricingTier.discount:
        return 'discount';
      case PricingTier.custom:
        return 'custom';
    }
  }
}