// lib/features/admin_properties/domain/entities/property_search_result.dart

import 'package:equatable/equatable.dart';
import 'property.dart';

class PropertySearchResult extends Equatable {
  final List<Property> properties;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final SearchStatistics? statistics;
  final PriceRange? priceRange;
  
  const PropertySearchResult({
    required this.properties,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
    this.statistics,
    this.priceRange,
  });
  
  @override
  List<Object?> get props => [
    properties,
    totalCount,
    pageNumber,
    pageSize,
    totalPages,
    hasPreviousPage,
    hasNextPage,
    statistics,
    priceRange,
  ];
}

class SearchStatistics extends Equatable {
  final int searchDurationMs;
  final int appliedFiltersCount;
  final int totalResultsBeforePaging;
  final List<String> suggestions;
  
  const SearchStatistics({
    required this.searchDurationMs,
    required this.appliedFiltersCount,
    required this.totalResultsBeforePaging,
    required this.suggestions,
  });
  
  @override
  List<Object> get props => [
    searchDurationMs,
    appliedFiltersCount,
    totalResultsBeforePaging,
    suggestions,
  ];
}

class PriceRange extends Equatable {
  final double minPrice;
  final double maxPrice;
  final double averagePrice;
  
  const PriceRange({
    required this.minPrice,
    required this.maxPrice,
    required this.averagePrice,
  });
  
  @override
  List<Object> get props => [minPrice, maxPrice, averagePrice];
}