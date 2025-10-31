// lib/features/admin_availability_pricing/data/datasources/pricing_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/pricing_rule_model.dart';
import '../models/seasonal_pricing_model.dart';
import '../../domain/repositories/pricing_repository.dart' as pricing_repo;
import '../../domain/entities/pricing.dart';

abstract class PricingRemoteDataSource {
  Future<UnitPricingModel> getMonthlyPricing(
    String unitId,
    int year,
    int month,
  );
  
  Future<void> updatePricing(Map<String, dynamic> data);
  
  Future<void> bulkUpdatePricing(
    String unitId,
    List<pricing_repo.PricingPeriod> periods,
    bool overwriteExisting,
  );
  
  Future<void> copyPricing(Map<String, dynamic> data);
  
  Future<void> deletePricing({
    required String unitId,
    String? pricingId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<List<SeasonalPricingModel>> getSeasonalPricing(String unitId);
  
  Future<void> applySeasonalPricing(Map<String, dynamic> data);
  
  Future<pricing_repo.PricingBreakdown> getPricingBreakdown({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });
}

class PricingRemoteDataSourceImpl implements PricingRemoteDataSource {
  final ApiClient apiClient;

  PricingRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UnitPricingModel> getMonthlyPricing(
    String unitId,
    int year,
    int month,
  ) async {
    try {
      final response = await apiClient.get(
        '/api/admin/units/$unitId/pricing/$year/$month',
      );
      
      final dataEnvelope = response.data;
      final data = dataEnvelope is Map && dataEnvelope['data'] != null
          ? dataEnvelope['data']
          : dataEnvelope;
      return UnitPricingModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> updatePricing(Map<String, dynamic> data) async {
    try {
      await apiClient.post(
        '/api/admin/units/${data['unitId']}/pricing',
        data: data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> bulkUpdatePricing(
    String unitId,
    List<pricing_repo.PricingPeriod> periods,
    bool overwriteExisting,
  ) async {
    try {
      final data = {
        'unitId': unitId,
        'periods': periods.map((p) => {
          'startDate': p.startDate.toIso8601String(),
          'endDate': p.endDate.toIso8601String(),
          'priceType': _priceTypeToString(p.priceType),
          // Backend accepts "price"; UpdateUnitPricingCommand expects Price; PricingRuleDto uses PriceAmount
          // Here we send the command payload (Price)
          'price': p.price,
          if (p.currency != null) 'currency': p.currency,
          // Backend BulkUpdatePricingCommand uses "Tier" while UpdateUnitPricingCommand uses "PricingTier"
          'tier': _pricingTierToString(p.tier),
          if (p.percentageChange != null) 'percentageChange': p.percentageChange,
          if (p.minPrice != null) 'minPrice': p.minPrice,
          if (p.maxPrice != null) 'maxPrice': p.maxPrice,
          if (p.description != null) 'description': p.description,
          'overwriteExisting': p.overwriteExisting,
        }).toList(),
        'overwriteExisting': overwriteExisting,
      };
      
      await apiClient.post(
        '/api/admin/units/$unitId/pricing/bulk',
        data: data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> copyPricing(Map<String, dynamic> data) async {
    try {
      await apiClient.post(
        '/api/admin/units/${data['unitId']}/pricing/copy',
        data: data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deletePricing({
    required String unitId,
    String? pricingId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (pricingId != null) {
        await apiClient.delete(
          '/api/admin/units/$unitId/pricing/$pricingId',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<SeasonalPricingModel>> getSeasonalPricing(String unitId) async {
    try {
      final response = await apiClient.get(
        '/api/admin/units/$unitId/pricing/templates',
      );
      
      final List<dynamic> seasons = response.data['seasons'] ?? [];
      return seasons
          .map((json) => SeasonalPricingModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> applySeasonalPricing(Map<String, dynamic> data) async {
    try {
      await apiClient.post(
        '/api/admin/units/${data['unitId']}/pricing/apply-template',
        data: data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<pricing_repo.PricingBreakdown> getPricingBreakdown({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // لا يوجد مسار صريح للبريك داون على الـ backend controllers، سنعيد قيمة محسوبة مبسطة
      // This fallback is not used in admin CP; set currency to default (YER)
      return PricingBreakdownModel.fromJson({
          'checkIn': checkIn.toIso8601String(),
          'checkOut': checkOut.toIso8601String(),
        'currency': 'YER',
        'days': const <Map<String, dynamic>>[],
        'totalNights': checkOut.difference(checkIn).inDays,
        'subTotal': 0,
        'total': 0,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class PricingBreakdownModel extends pricing_repo.PricingBreakdown {
  PricingBreakdownModel({
    required DateTime checkIn,
    required DateTime checkOut,
    required String currency,
    required List<pricing_repo.DayPrice> days,
    required int totalNights,
    required double subTotal,
    double? discount,
    double? taxes,
    required double total,
  }) : super(
          checkIn: checkIn,
          checkOut: checkOut,
          currency: currency,
          days: days,
          totalNights: totalNights,
          subTotal: subTotal,
          discount: discount,
          taxes: taxes,
          total: total,
        );

  factory PricingBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PricingBreakdownModel(
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      currency: json['currency'] as String,
      days: (json['days'] as List)
          .map((e) => DayPriceModel.fromJson(e))
          .toList(),
      totalNights: json['totalNights'] as int,
      subTotal: (json['subTotal'] as num).toDouble(),
      discount: json['discount'] != null
          ? (json['discount'] as num).toDouble()
          : null,
      taxes: json['taxes'] != null
          ? (json['taxes'] as num).toDouble()
          : null,
      total: (json['total'] as num).toDouble(),
    );
  }
}

class DayPriceModel extends pricing_repo.DayPrice {
  DayPriceModel({
    required DateTime date,
    required double price,
    required PriceType priceType,
    String? description,
  }) : super(
          date: date,
          price: price,
          priceType: priceType,
          description: description,
        );

  factory DayPriceModel.fromJson(Map<String, dynamic> json) {
    return DayPriceModel(
      date: DateTime.parse(json['date'] as String),
      price: (json['price'] as num).toDouble(),
      priceType: _parsePriceTypeString(json['priceType'] as String),
      description: json['description'] as String?,
    );
  }
}

// Local converters to avoid accessing private members across libraries
PriceType _parsePriceTypeString(String type) {
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