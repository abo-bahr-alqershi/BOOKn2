// lib/features/admin_properties/data/models/property_search_model.dart

import 'package:bookn_cp_app/features/admin_properties/domain/entities/property.dart';

import '../../domain/entities/property_search_result.dart';
import 'property_model.dart';

class PropertySearchModel extends PropertySearchResult {
  const PropertySearchModel({
    required List<Property> properties,
    required int totalCount,
    required int pageNumber,
    required int pageSize,
    required int totalPages,
    required bool hasPreviousPage,
    required bool hasNextPage,
    SearchStatistics? statistics,
    PriceRange? priceRange,
  }) : super(
    properties: properties,
    totalCount: totalCount,
    pageNumber: pageNumber,
    pageSize: pageSize,
    totalPages: totalPages,
    hasPreviousPage: hasPreviousPage,
    hasNextPage: hasNextPage,
    statistics: statistics,
    priceRange: priceRange,
  );
  
  factory PropertySearchModel.fromJson(Map<String, dynamic> json) {
    return PropertySearchModel(
      properties: (json['properties'] as List<dynamic>)
          .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      pageNumber: json['pageNumber'] as int,
      pageSize: json['pageSize'] as int,
      totalPages: json['totalPages'] as int,
      hasPreviousPage: json['hasPreviousPage'] as bool,
      hasNextPage: json['hasNextPage'] as bool,
      statistics: json['statistics'] != null
          ? SearchStatisticsModel.fromJson(json['statistics'])
          : null,
      priceRange: json['priceRange'] != null
          ? PriceRangeModel.fromJson(json['priceRange'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'properties': properties.map((e) => (e as PropertyModel).toJson()).toList(),
      'totalCount': totalCount,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'totalPages': totalPages,
      'hasPreviousPage': hasPreviousPage,
      'hasNextPage': hasNextPage,
      if (statistics != null) 'statistics': (statistics as SearchStatisticsModel).toJson(),
      if (priceRange != null) 'priceRange': (priceRange as PriceRangeModel).toJson(),
    };
  }
}

class SearchStatisticsModel extends SearchStatistics {
  const SearchStatisticsModel({
    required int searchDurationMs,
    required int appliedFiltersCount,
    required int totalResultsBeforePaging,
    required List<String> suggestions,
  }) : super(
    searchDurationMs: searchDurationMs,
    appliedFiltersCount: appliedFiltersCount,
    totalResultsBeforePaging: totalResultsBeforePaging,
    suggestions: suggestions,
  );
  
  factory SearchStatisticsModel.fromJson(Map<String, dynamic> json) {
    return SearchStatisticsModel(
      searchDurationMs: json['searchDurationMs'] as int,
      appliedFiltersCount: json['appliedFiltersCount'] as int,
      totalResultsBeforePaging: json['totalResultsBeforePaging'] as int,
      suggestions: (json['suggestions'] as List<dynamic>).cast<String>(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'searchDurationMs': searchDurationMs,
      'appliedFiltersCount': appliedFiltersCount,
      'totalResultsBeforePaging': totalResultsBeforePaging,
      'suggestions': suggestions,
    };
  }
}

class PriceRangeModel extends PriceRange {
  const PriceRangeModel({
    required double minPrice,
    required double maxPrice,
    required double averagePrice,
  }) : super(
    minPrice: minPrice,
    maxPrice: maxPrice,
    averagePrice: averagePrice,
  );
  
  factory PriceRangeModel.fromJson(Map<String, dynamic> json) {
    return PriceRangeModel(
      minPrice: (json['minPrice'] as num).toDouble(),
      maxPrice: (json['maxPrice'] as num).toDouble(),
      averagePrice: (json['averagePrice'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'averagePrice': averagePrice,
    };
  }
}