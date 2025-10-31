// lib/features/admin_availability_pricing/data/models/seasonal_pricing_model.dart

import '../../domain/entities/seasonal_pricing.dart';
import '../../domain/entities/pricing.dart';

class SeasonalPricingModel extends SeasonalPricing {
  const SeasonalPricingModel({
    required String id,
    required String name,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
    double? percentageChange,
    required String currency,
    required PricingTier pricingTier,
    required int priority,
    required String description,
    bool isActive = true,
    bool isRecurring = false,
    required int daysCount,
    required double totalRevenuePotential,
  }) : super(
          id: id,
          name: name,
          type: type,
          startDate: startDate,
          endDate: endDate,
          price: price,
          percentageChange: percentageChange,
          currency: currency,
          pricingTier: pricingTier,
          priority: priority,
          description: description,
          isActive: isActive,
          isRecurring: isRecurring,
          daysCount: daysCount,
          totalRevenuePotential: totalRevenuePotential,
        );

  factory SeasonalPricingModel.fromJson(Map<String, dynamic> json) {
    return SeasonalPricingModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      price: (json['price'] as num).toDouble(),
      percentageChange: json['percentageChange'] != null
          ? (json['percentageChange'] as num).toDouble()
          : null,
      currency: json['currency'] as String,
      pricingTier: _parsePricingTier(json['pricingTier'] as String),
      priority: json['priority'] as int,
      description: json['description'] as String,
      isActive: json['isActive'] as bool? ?? true,
      isRecurring: json['isRecurring'] as bool? ?? false,
      daysCount: json['daysCount'] as int,
      totalRevenuePotential: (json['totalRevenuePotential'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'price': price,
      if (percentageChange != null) 'percentageChange': percentageChange,
      'currency': currency,
      'pricingTier': _pricingTierToString(pricingTier),
      'priority': priority,
      'description': description,
      'isActive': isActive,
      'isRecurring': isRecurring,
      'daysCount': daysCount,
      'totalRevenuePotential': totalRevenuePotential,
    };
  }

  static PricingTier _parsePricingTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'normal':
        return PricingTier.normal;
      case 'high':
        return PricingTier.high;
      case 'peak':
        return PricingTier.peak;
      case 'discount':
        return PricingTier.discount;
      default:
        return PricingTier.custom;
    }
  }

  static String _pricingTierToString(PricingTier tier) {
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