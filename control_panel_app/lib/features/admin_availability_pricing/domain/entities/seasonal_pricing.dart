// lib/features/admin_availability_pricing/domain/entities/seasonal_pricing.dart

import 'package:equatable/equatable.dart';
import 'pricing.dart';

class SeasonalPricing extends Equatable {
  final String id;
  final String name;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final double? percentageChange;
  final String currency;
  final PricingTier pricingTier;
  final int priority;
  final String description;
  final bool isActive;
  final bool isRecurring;
  final int daysCount;
  final double totalRevenuePotential;

  const SeasonalPricing({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.price,
    this.percentageChange,
    required this.currency,
    required this.pricingTier,
    required this.priority,
    required this.description,
    this.isActive = true,
    this.isRecurring = false,
    required this.daysCount,
    required this.totalRevenuePotential,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        startDate,
        endDate,
        price,
        percentageChange,
        currency,
        pricingTier,
        priority,
        description,
        isActive,
        isRecurring,
        daysCount,
        totalRevenuePotential,
      ];
}

class SeasonalPricingStats extends Equatable {
  final int totalSeasons;
  final int activeSeasons;
  final int upcomingSeasons;
  final int expiredSeasons;
  final double averageSeasonalPrice;
  final double maxSeasonalPrice;
  final double minSeasonalPrice;
  final int totalDaysCovered;

  const SeasonalPricingStats({
    required this.totalSeasons,
    required this.activeSeasons,
    required this.upcomingSeasons,
    required this.expiredSeasons,
    required this.averageSeasonalPrice,
    required this.maxSeasonalPrice,
    required this.minSeasonalPrice,
    required this.totalDaysCovered,
  });

  @override
  List<Object> get props => [
        totalSeasons,
        activeSeasons,
        upcomingSeasons,
        expiredSeasons,
        averageSeasonalPrice,
        maxSeasonalPrice,
        minSeasonalPrice,
        totalDaysCovered,
      ];
}