import 'package:yemen_booking_app/features/search/data/models/search_filter_model.dart';

class SearchStatisticsModel {
  final int searchDurationMs;
  final int appliedFiltersCount;
  final int totalResultsBeforePaging;
  final List<String> suggestions;
  final PriceRangeModel? priceRange;

  const SearchStatisticsModel({
    required this.searchDurationMs,
    required this.appliedFiltersCount,
    required this.totalResultsBeforePaging,
    required this.suggestions,
    this.priceRange,
  });

  factory SearchStatisticsModel.fromJson(Map<String, dynamic> json) {
    return SearchStatisticsModel(
      searchDurationMs: json['searchDurationMs'] ?? 0,
      appliedFiltersCount: json['appliedFiltersCount'] ?? 0,
      totalResultsBeforePaging: json['totalResultsBeforePaging'] ?? 0,
      suggestions: List<String>.from(json['suggestions'] ?? []),
      priceRange: json['priceRange'] != null
          ? PriceRangeModel.fromJson(json['priceRange'] as Map<String, dynamic>)
          : null,
    );
  }
}