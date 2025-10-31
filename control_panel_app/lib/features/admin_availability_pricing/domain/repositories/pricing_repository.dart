// lib/features/admin_availability_pricing/domain/repositories/pricing_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pricing.dart';
import '../entities/pricing_rule.dart';
import '../entities/seasonal_pricing.dart';

abstract class PricingRepository {
  Future<Either<Failure, UnitPricing>> getMonthlyPricing(
    String unitId,
    int year,
    int month,
  );

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
  });

  Future<Either<Failure, void>> bulkUpdatePricing({
    required String unitId,
    required List<PricingPeriod> periods,
    required bool overwriteExisting,
  });

  Future<Either<Failure, void>> copyPricing({
    required String unitId,
    required DateTime sourceStartDate,
    required DateTime sourceEndDate,
    required DateTime targetStartDate,
    required int repeatCount,
    required String adjustmentType,
    required double adjustmentValue,
    required bool overwriteExisting,
  });

  Future<Either<Failure, void>> deletePricing({
    required String unitId,
    String? pricingId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, List<SeasonalPricing>>> getSeasonalPricing(
    String unitId,
  );

  Future<Either<Failure, void>> applySeasonalPricing({
    required String unitId,
    required List<SeasonalPricing> seasons,
    required String currency,
  });

  Future<Either<Failure, PricingBreakdown>> getPricingBreakdown({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });
}

class PricingPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final PriceType priceType;
  final double price;
  final String? currency;
  final PricingTier tier;
  final double? percentageChange;
  final double? minPrice;
  final double? maxPrice;
  final String? description;
  final bool overwriteExisting;

  PricingPeriod({
    required this.startDate,
    required this.endDate,
    required this.priceType,
    required this.price,
    this.currency,
    required this.tier,
    this.percentageChange,
    this.minPrice,
    this.maxPrice,
    this.description,
    required this.overwriteExisting,
  });
}

class PricingBreakdown {
  final DateTime checkIn;
  final DateTime checkOut;
  final String currency;
  final List<DayPrice> days;
  final int totalNights;
  final double subTotal;
  final double? discount;
  final double? taxes;
  final double total;

  PricingBreakdown({
    required this.checkIn,
    required this.checkOut,
    required this.currency,
    required this.days,
    required this.totalNights,
    required this.subTotal,
    this.discount,
    this.taxes,
    required this.total,
  });
}

class DayPrice {
  final DateTime date;
  final double price;
  final PriceType priceType;
  final String? description;

  DayPrice({
    required this.date,
    required this.price,
    required this.priceType,
    this.description,
  });
}
