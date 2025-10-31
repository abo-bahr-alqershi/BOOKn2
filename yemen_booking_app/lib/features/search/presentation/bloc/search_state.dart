import 'package:equatable/equatable.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/search_result.dart';

// View modes for search results UI
enum ViewMode { list, grid, map }

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

// Search Results States
class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchSuccess extends SearchState {
  final PaginatedResult<SearchResult> searchResults;
  final Map<String, dynamic> currentFilters;
  final bool hasReachedMax;
  final ViewMode viewMode;

  const SearchSuccess({
    required this.searchResults,
    required this.currentFilters,
    this.hasReachedMax = false,
    this.viewMode = ViewMode.list,
  });

  SearchSuccess copyWith({
    PaginatedResult<SearchResult>? searchResults,
    Map<String, dynamic>? currentFilters,
    bool? hasReachedMax,
    ViewMode? viewMode,
  }) {
    return SearchSuccess(
      searchResults: searchResults ?? this.searchResults,
      currentFilters: currentFilters ?? this.currentFilters,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  List<Object?> get props => [searchResults, currentFilters, hasReachedMax, viewMode];

  PaginatedResult<SearchResult> get results => searchResults;
  Map<String, dynamic> get appliedFilters => currentFilters;
}

class SearchError extends SearchState {
  final String message;

  const SearchError({required this.message});

  @override
  List<Object> get props => [message];
}

class SearchLoadingMore extends SearchState {
  final PaginatedResult<SearchResult> currentResults;

  const SearchLoadingMore({required this.currentResults});

  @override
  List<Object> get props => [currentResults];
}

// Filters States
class SearchFiltersLoading extends SearchState {
  const SearchFiltersLoading();
}

class SearchFiltersLoaded extends SearchState {
  final SearchFilters filters;

  const SearchFiltersLoaded({required this.filters});

  @override
  List<Object> get props => [filters];
}

class SearchFiltersError extends SearchState {
  final String message;

  const SearchFiltersError({required this.message});

  @override
  List<Object> get props => [message];
}

// Suggestions States
class SearchSuggestionsLoading extends SearchState {
  const SearchSuggestionsLoading();
}

class SearchSuggestionsLoaded extends SearchState {
  final List<String> suggestions;

  const SearchSuggestionsLoaded({required this.suggestions});

  @override
  List<Object> get props => [suggestions];
}

class SearchSuggestionsError extends SearchState {
  final String message;

  const SearchSuggestionsError({required this.message});

  @override
  List<Object> get props => [message];
}

// Recommended Properties States
class RecommendedPropertiesLoading extends SearchState {
  const RecommendedPropertiesLoading();
}

class RecommendedPropertiesLoaded extends SearchState {
  final List<SearchResult> properties;

  const RecommendedPropertiesLoaded({required this.properties});

  @override
  List<Object> get props => [properties];
}

class RecommendedPropertiesError extends SearchState {
  final String message;

  const RecommendedPropertiesError({required this.message});

  @override
  List<Object> get props => [message];
}

// Popular Destinations States
class PopularDestinationsLoading extends SearchState {
  const PopularDestinationsLoading();
}

class PopularDestinationsLoaded extends SearchState {
  final List<String> destinations;

  const PopularDestinationsLoaded({required this.destinations});

  @override
  List<Object> get props => [destinations];
}

class PopularDestinationsError extends SearchState {
  final String message;

  const PopularDestinationsError({required this.message});

  @override
  List<Object> get props => [message];
}

// Combined State for managing multiple sub-states
class SearchCombinedState extends SearchState {
  final SearchState? searchResultsState;
  final SearchState? filtersState;
  final SearchState? suggestionsState;
  final SearchState? recommendedState;
  final SearchState? popularDestinationsState;
  final List<String> recentSearches;
  final List<SavedSearch> savedSearches;

  const SearchCombinedState({
    this.searchResultsState,
    this.filtersState,
    this.suggestionsState,
    this.recommendedState,
    this.popularDestinationsState,
    this.recentSearches = const [],
    this.savedSearches = const [],
  });

  SearchCombinedState copyWith({
    SearchState? searchResultsState,
    SearchState? filtersState,
    SearchState? suggestionsState,
    SearchState? recommendedState,
    SearchState? popularDestinationsState,
    List<String>? recentSearches,
    List<SavedSearch>? savedSearches,
  }) {
    return SearchCombinedState(
      searchResultsState: searchResultsState ?? this.searchResultsState,
      filtersState: filtersState ?? this.filtersState,
      suggestionsState: suggestionsState ?? this.suggestionsState,
      recommendedState: recommendedState ?? this.recommendedState,
      popularDestinationsState: popularDestinationsState ?? this.popularDestinationsState,
      recentSearches: recentSearches ?? this.recentSearches,
      savedSearches: savedSearches ?? this.savedSearches,
    );
  }

  @override
  List<Object?> get props => [
        searchResultsState,
        filtersState,
        suggestionsState,
        recommendedState,
        popularDestinationsState,
        recentSearches,
        savedSearches,
      ];
}

// Model for saved searches
class SavedSearch extends Equatable {
  final String id;
  final String name;
  final Map<String, dynamic> searchParams;
  final DateTime createdAt;

  const SavedSearch({
    required this.id,
    required this.name,
    required this.searchParams,
    required this.createdAt,
  });

  @override
  List<Object> get props => [id, name, searchParams, createdAt];
}