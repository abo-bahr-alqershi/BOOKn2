// lib/features/admin_availability_pricing/domain/entities/pricing_rule.dart

import 'package:equatable/equatable.dart';
import 'pricing.dart';

class PricingRule extends Equatable {
  final String id;
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime;
  final String? endTime;
  final double priceAmount;
  final String priceType;
  final String pricingTier;
  final double? percentageChange;
  final double? minPrice;
  final double? maxPrice;
  final String? description;
  final String currency;

  const PricingRule({
    required this.id,
    required this.unitId,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    required this.priceAmount,
    required this.priceType,
    required this.pricingTier,
    this.percentageChange,
    this.minPrice,
    this.maxPrice,
    this.description,
    required this.currency,
  });

  @override
  List<Object?> get props => [
        id,
        unitId,
        startDate,
        endDate,
        startTime,
        endTime,
        priceAmount,
        priceType,
        pricingTier,
        percentageChange,
        minPrice,
        maxPrice,
        description,
        currency,
      ];
}

class UnitPricing extends Equatable {
  final String unitId;
  final String unitName;
  final double basePrice;
  final String currency;
  final Map<String, PricingDay> calendar;
  final List<PricingRule> rules;
  final PricingStats stats;

  const UnitPricing({
    required this.unitId,
    required this.unitName,
    required this.basePrice,
    required this.currency,
    required this.calendar,
    required this.rules,
    required this.stats,
  });

  @override
  List<Object> get props => [
        unitId,
        unitName,
        basePrice,
        currency,
        calendar,
        rules,
        stats,
      ];
}

class PricingDay extends Equatable {
  final double price;
  final PriceType priceType;
  final String colorCode;
  final double? percentageChange;
  final String? pricingTier;

  const PricingDay({
    required this.price,
    required this.priceType,
    required this.colorCode,
    this.percentageChange,
    this.pricingTier,
  });

  @override
  List<Object?> get props => [price, priceType, colorCode, percentageChange, pricingTier];
}

class PricingStats extends Equatable {
  final double averagePrice;
  final double minPrice;
  final double maxPrice;
  final int daysWithSpecialPricing;
  final double potentialRevenue;

  const PricingStats({
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.daysWithSpecialPricing,
    required this.potentialRevenue,
  });

  @override
  List<Object> get props => [
        averagePrice,
        minPrice,
        maxPrice,
        daysWithSpecialPricing,
        potentialRevenue,
      ];
}