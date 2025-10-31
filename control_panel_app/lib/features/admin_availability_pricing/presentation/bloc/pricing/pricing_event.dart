// lib/features/admin_availability_pricing/presentation/bloc/pricing/pricing_event.dart

part of 'pricing_bloc.dart';

abstract class PricingEvent extends Equatable {
  const PricingEvent();

  @override
  List<Object?> get props => [];
}

class LoadMonthlyPricing extends PricingEvent {
  final String unitId;
  final int year;
  final int month;

  const LoadMonthlyPricing({
    required this.unitId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [unitId, year, month];
}

class UpdatePricing extends PricingEvent {
  final UpdatePricingParams params;

  const UpdatePricing({required this.params});

  @override
  List<Object> get props => [params];
}

class UpdateSingleDayPricing extends PricingEvent {
  final String unitId;
  final DateTime date;
  final double price;
  final PriceType? priceType;
  final PricingTier? pricingTier;
  final String? currency;
  final bool overwriteExisting;

  const UpdateSingleDayPricing({
    required this.unitId,
    required this.date,
    required this.price,
    this.priceType,
    this.pricingTier,
    this.currency,
    this.overwriteExisting = true,
  });

  @override
  List<Object?> get props =>
      [unitId, date, price, priceType, pricingTier, currency, overwriteExisting];
}

class UpdateDateRangePricing extends PricingEvent {
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final PriceType? priceType;
  final PricingTier? pricingTier;
  final String? currency;
  final bool overwriteExisting;

  const UpdateDateRangePricing({
    required this.unitId,
    required this.startDate,
    required this.endDate,
    required this.price,
    this.priceType,
    this.pricingTier,
    this.currency,
    this.overwriteExisting = false,
  });

  @override
  List<Object?> get props => [
        unitId,
        startDate,
        endDate,
        price,
        priceType,
        pricingTier,
        currency,
        overwriteExisting,
      ];
}

class BulkUpdatePricing extends PricingEvent {
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final PriceType priceType;
  final PricingTier pricingTier;
  final double? percentageChange;
  final List<int>? weekdays;
  final bool overwriteExisting;

  const BulkUpdatePricing({
    required this.unitId,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.priceType,
    required this.pricingTier,
    this.percentageChange,
    this.weekdays,
    this.overwriteExisting = false,
  });

  @override
  List<Object?> get props => [
        unitId,
        startDate,
        endDate,
        price,
        priceType,
        pricingTier,
        percentageChange,
        weekdays,
        overwriteExisting,
      ];
}

class ApplySeasonalPricing extends PricingEvent {
  final ApplySeasonalPricingParams params;

  const ApplySeasonalPricing({required this.params});

  @override
  List<Object> get props => [params];
}

class CopyPricing extends PricingEvent {
  final String unitId;
  final DateTime sourceStartDate;
  final DateTime sourceEndDate;
  final DateTime targetStartDate;
  final int repeatCount;
  final String adjustmentType;
  final double adjustmentValue;
  final bool overwriteExisting;

  const CopyPricing({
    required this.unitId,
    required this.sourceStartDate,
    required this.sourceEndDate,
    required this.targetStartDate,
    required this.repeatCount,
    required this.adjustmentType,
    required this.adjustmentValue,
    required this.overwriteExisting,
  });

  @override
  List<Object> get props => [
        unitId,
        sourceStartDate,
        sourceEndDate,
        targetStartDate,
        repeatCount,
        adjustmentType,
        adjustmentValue,
        overwriteExisting,
      ];
}

class DeletePricing extends PricingEvent {
  final String unitId;
  final String? pricingId;
  final DateTime? startDate;
  final DateTime? endDate;

  const DeletePricing({
    required this.unitId,
    this.pricingId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [unitId, pricingId, startDate, endDate];
}

class SelectPricingUnit extends PricingEvent {
  final String unitId;

  const SelectPricingUnit({required this.unitId});

  @override
  List<Object> get props => [unitId];
}

class ChangePricingMonth extends PricingEvent {
  final int year;
  final int month;

  const ChangePricingMonth({required this.year, required this.month});

  @override
  List<Object> get props => [year, month];
}
