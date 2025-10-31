import 'package:yemen_booking_app/features/search/data/models/search_result_model.dart';
import 'package:yemen_booking_app/features/search/data/models/search_filter_model.dart';
import 'package:yemen_booking_app/features/search/data/models/search_statistics_model.dart';

class SearchPropertiesResponseModel {
  final List<SearchResultModel> properties;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final SearchFiltersModel appliedFilters;
  final int searchTimeMs;
  final SearchStatisticsModel statistics;

  const SearchPropertiesResponseModel({
    required this.properties,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.appliedFilters,
    required this.searchTimeMs,
    required this.statistics,
  });

  factory SearchPropertiesResponseModel.fromJson(Map<String, dynamic> json) {
    return SearchPropertiesResponseModel(
      properties: (json['properties'] as List?)
              ?.map((e) => SearchResultModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalPages: json['totalPages'] ?? 0,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      hasNextPage: json['hasNextPage'] ?? false,
      appliedFilters: SearchFiltersModel.fromJson(
          json['appliedFilters'] as Map<String, dynamic>? ?? {}),
      searchTimeMs: json['searchTimeMs'] ?? 0,
      statistics: SearchStatisticsModel.fromJson(
          json['statistics'] as Map<String, dynamic>? ?? {}),
    );
  }
}