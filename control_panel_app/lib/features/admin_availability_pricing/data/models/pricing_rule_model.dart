// lib/features/admin_availability_pricing/data/models/pricing_rule_model.dart

import '../../domain/entities/pricing_rule.dart';
import '../../domain/entities/pricing.dart';
import 'package:intl/intl.dart';

class PricingRuleModel extends PricingRule {
  const PricingRuleModel({
    required super.id,
    required super.unitId,
    required super.startDate,
    required super.endDate,
    super.startTime,
    super.endTime,
    required super.priceAmount,
    required super.priceType,
    required super.pricingTier,
    super.percentageChange,
    super.minPrice,
    super.maxPrice,
    super.description,
    required super.currency,
  });

  factory PricingRuleModel.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['pricingId'] ?? json['PricingId'];
    final unitIdRaw = json['unitId'] ?? json['UnitId'];
    final priceTypeRaw = json['priceType'] ?? json['PriceType'] ?? 'custom';
    final tierRaw = json['pricingTier'] ?? json['tier'] ?? json['PricingTier'] ?? 'normal';
    final currencyRaw = json['currency'] ?? json['Currency'] ?? '';

    return PricingRuleModel(
      id: idRaw?.toString() ?? '',
      unitId: unitIdRaw?.toString() ?? '',
      startDate: DateTime.parse((json['startDate'] ?? json['StartDate']) as String),
      endDate: DateTime.parse((json['endDate'] ?? json['EndDate']) as String),
      startTime: (json['startTime'] ?? json['StartTime']) as String?,
      endTime: (json['endTime'] ?? json['EndTime']) as String?,
      // Backend may send either "priceAmount" or "price"
      priceAmount: ((json['priceAmount'] ?? json['price'] ?? json['PriceAmount']) as num).toDouble(),
      priceType: priceTypeRaw.toString(),
      // Backend may send either "pricingTier" or compact "tier"; default to normal
      pricingTier: tierRaw.toString(),
      percentageChange: json['percentageChange'] != null
          ? (json['percentageChange'] as num).toDouble()
          : null,
      minPrice: json['minPrice'] != null
          ? (json['minPrice'] as num).toDouble()
          : null,
      maxPrice: json['maxPrice'] != null
          ? (json['maxPrice'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      // If rule currency is missing, expect caller to inject parent currency; else fallback to empty string
      currency: currencyRaw.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitId': unitId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      'priceAmount': priceAmount,
      'priceType': priceType,
      'pricingTier': pricingTier,
      if (percentageChange != null) 'percentageChange': percentageChange,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (description != null) 'description': description,
      'currency': currency,
    };
  }

  static PriceType _parsePriceType(String type) {
    switch (type.toLowerCase()) {
      case 'base':
        return PriceType.base;
      case 'weekend':
        return PriceType.weekend;
      case 'seasonal':
        return PriceType.seasonal;
      case 'holiday':
        return PriceType.holiday;
      case 'special_event':
      case 'specialevent':
        return PriceType.specialEvent;
      default:
        return PriceType.custom;
    }
  }
}

class UnitPricingModel extends UnitPricing {
  const UnitPricingModel({
    required super.unitId,
    required super.unitName,
    required super.basePrice,
    required super.currency,
    required super.calendar,
    required super.rules,
    required super.stats,
  });

  factory UnitPricingModel.fromJson(Map<String, dynamic> json) {
    final Map<String, PricingDay> calendar = {};
    final calendarMap = (json['calendar'] ?? json['Calendar']) as Map<String, dynamic>?;
    if (calendarMap != null) {
      final dateFmt = DateFormat('yyyy-MM-dd');
      calendarMap.forEach((key, value) {
        String normalizedKey = key;
        try {
          final dt = DateTime.parse(key);
          normalizedKey = dateFmt.format(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {
          if (key.length >= 10) normalizedKey = key.substring(0, 10);
        }
        calendar[normalizedKey] = PricingDayModel.fromJson(value);
      });
    }

    final List<PricingRule> rules = [];
    final rulesList = (json['rules'] ?? json['Rules']) as List?;
    if (rulesList != null) {
      final String unitCurrency = (json['currency'] ?? json['Currency']).toString();
      final String unitId = (json['unitId'] ?? json['UnitId']).toString();
      rules.addAll(
        rulesList.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          // Ensure unitId and currency are present on each rule to satisfy domain entity
          map.putIfAbsent('unitId', () => unitId);
          map.putIfAbsent('currency', () => unitCurrency);
          // Normalize id from backend (pricingId)
          if (!map.containsKey('id')) {
            final pid = map['pricingId'] ?? map['PricingId'];
            if (pid != null) map['id'] = pid.toString();
          }
          // Normalize possible backend alias for pricing tier
          if (!map.containsKey('pricingTier') && map.containsKey('tier')) {
            map['pricingTier'] = map['tier'];
          }
          // Normalize price key if backend used "price"
          if (!map.containsKey('priceAmount') && map.containsKey('price')) {
            map['priceAmount'] = map['price'];
          }
          return PricingRuleModel.fromJson(map);
        }).toList(),
      );
    }

    return UnitPricingModel(
      unitId: (json['unitId'] ?? json['UnitId']).toString(),
      unitName: (json['unitName'] ?? json['UnitName']) as String,
      basePrice: ((json['basePrice'] ?? json['BasePrice']) as num).toDouble(),
      currency: (json['currency'] ?? json['Currency']) as String,
      calendar: calendar,
      rules: rules,
      stats: PricingStatsModel.fromJson(
        (json['stats'] ?? json['Stats']) as Map<String, dynamic>,
      ),
    );
  }
}

class PricingDayModel extends PricingDay {
  const PricingDayModel({
    required super.price,
    required super.priceType,
    required super.colorCode,
    super.percentageChange,
    super.pricingTier,
  });

  factory PricingDayModel.fromJson(Map<String, dynamic> json) {
    final priceRaw = json['price'] ?? json['Price'] ?? 0;
    final priceTypeRaw = json['priceType'] ?? json['PriceType'] ?? 'custom';
    final colorRaw = json['colorCode'] ?? json['ColorCode'] ?? '#FFFFFF';
    final pctRaw = json['percentageChange'] ?? json['PercentageChange'];
    final tierRaw = json['pricingTier'] ?? json['PricingTier'];

    return PricingDayModel(
      price: (priceRaw as num).toDouble(),
      priceType: PricingRuleModel._parsePriceType(priceTypeRaw.toString()),
      colorCode: colorRaw.toString(),
      percentageChange: pctRaw != null ? (pctRaw as num).toDouble() : null,
      pricingTier: tierRaw?.toString(),
    );
  }
}

class PricingStatsModel extends PricingStats {
  const PricingStatsModel({
    required super.averagePrice,
    required super.minPrice,
    required super.maxPrice,
    required super.daysWithSpecialPricing,
    required super.potentialRevenue,
  });

  factory PricingStatsModel.fromJson(Map<String, dynamic> json) {
    final avg = json['averagePrice'] ?? json['AveragePrice'] ?? 0;
    final min = json['minPrice'] ?? json['MinPrice'] ?? 0;
    final max = json['maxPrice'] ?? json['MaxPrice'] ?? 0;
    final days = json['daysWithSpecialPricing'] ?? json['DaysWithSpecialPricing'] ?? 0;
    final revenue = json['potentialRevenue'] ?? json['PotentialRevenue'] ?? 0;
    return PricingStatsModel(
      averagePrice: (avg as num).toDouble(),
      minPrice: (min as num).toDouble(),
      maxPrice: (max as num).toDouble(),
      daysWithSpecialPricing: days as int,
      potentialRevenue: (revenue as num).toDouble(),
    );
  }
}
