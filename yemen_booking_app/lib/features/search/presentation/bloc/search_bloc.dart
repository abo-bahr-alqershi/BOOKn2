import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yemen_booking_app/core/usecases/usecase.dart';
import 'dart:convert';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/get_search_filters_usecase.dart';
import '../../domain/usecases/get_search_suggestions_usecase.dart';
import '../../domain/usecases/search_properties_usecase.dart';
import '../../domain/repositories/search_repository.dart';
import '../../../../services/data_sync_service.dart';
import '../../../../services/filter_storage_service.dart';
import 'package:yemen_booking_app/features/home/data/models/unit_type_model.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchPropertiesUseCase searchPropertiesUseCase;
  final GetSearchFiltersUseCase getSearchFiltersUseCase;
  final GetSearchSuggestionsUseCase getSearchSuggestionsUseCase;
  final SearchRepository searchRepository;
  final SharedPreferences sharedPreferences;
  final DataSyncService dataSyncService;
  final FilterStorageService filterStorageService;

  static const String _recentSearchesKey = 'recent_searches';
  static const String _savedSearchesKey = 'saved_searches';
  static const int _maxRecentSearches = 10;

  Map<String, dynamic> _currentFilters = {};
  PaginatedResult<SearchResult>? _currentSearchResults;

  SearchBloc({
    required this.searchPropertiesUseCase,
    required this.getSearchFiltersUseCase,
    required this.getSearchSuggestionsUseCase,
    required this.searchRepository,
    required this.sharedPreferences,
    required this.dataSyncService,
    required this.filterStorageService,
  }) : super(const SearchCombinedState()) {
    on<SearchPropertiesEvent>(_onSearchProperties);
    on<LoadMoreSearchResultsEvent>(_onLoadMoreSearchResults);
    on<GetSearchFiltersEvent>(_onGetSearchFilters);
    on<GetSearchSuggestionsEvent>(_onGetSearchSuggestions);
    on<ClearSearchSuggestionsEvent>(_onClearSearchSuggestions);
    on<GetRecommendedPropertiesEvent>(_onGetRecommendedProperties);
    on<GetPopularDestinationsEvent>(_onGetPopularDestinations);
    on<UpdateSearchFiltersEvent>(_onUpdateSearchFilters);
    on<ClearSearchResultsEvent>(_onClearSearchResults);
    on<AddToRecentSearchesEvent>(_onAddToRecentSearches);
    on<LoadRecentSearchesEvent>(_onLoadRecentSearches);
    on<ClearRecentSearchesEvent>(_onClearRecentSearches);
    on<SaveSearchEvent>(_onSaveSearch);
    on<LoadSavedSearchesEvent>(_onLoadSavedSearches);
    on<DeleteSavedSearchEvent>(_onDeleteSavedSearch);
    on<ApplySavedSearchEvent>(_onApplySavedSearch);
    on<ToggleViewModeEvent>(_onToggleViewMode);
  }

  void _onToggleViewMode(
    ToggleViewModeEvent event,
    Emitter<SearchState> emit,
  ) {
    final currentState = state as SearchCombinedState;
    final resultsState = currentState.searchResultsState;
    if (resultsState is SearchSuccess) {
      final currentMode = resultsState.viewMode;
      final nextMode = event.mode ??
          (currentMode == ViewMode.list
              ? ViewMode.grid
              : currentMode == ViewMode.grid
                  ? ViewMode.map
                  : ViewMode.list);

      emit(currentState.copyWith(
        searchResultsState: resultsState.copyWith(viewMode: nextMode),
      ));
    }
  }

  void _onSearchProperties(
    SearchPropertiesEvent event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state as SearchCombinedState;

    if (event.isNewSearch) {
      emit(currentState.copyWith(
        searchResultsState: const SearchLoading(),
      ));
      _currentSearchResults = null;
    } else {
      emit(currentState.copyWith(
        searchResultsState: SearchLoadingMore(
          currentResults: _currentSearchResults!,
        ),
      ));
    }

    // Determine if selected unit type supports guests (adults/children)
    int? effectiveGuestsCount = event.guestsCount;
    int? effectiveAdults = event.adults;
    int? effectiveChildren = event.children;
    try {
      if (event.propertyTypeId != null && event.unitTypeId != null) {
        final List<UnitTypeModel> unitTypes = await dataSyncService.getUnitTypes(
          propertyTypeId: event.propertyTypeId!,
        );
        final UnitTypeModel selectedUnit = unitTypes.firstWhere(
          (u) => u.id == event.unitTypeId,
          orElse: () => UnitTypeModel(
            id: '',
            propertyTypeId: '',
            name: '',
            description: '',
            maxCapacity: 0,
            icon: '',
            isHasAdults: false,
            isHasChildren: false,
            isMultiDays: false,
            isRequiredToDetermineTheHour: false,
          ),
        );
        final bool supportsGuests = (selectedUnit.id.isNotEmpty) && (selectedUnit.isHasAdults || selectedUnit.isHasChildren);
        // Derive guestsCount from adults+children when provided
        if (effectiveGuestsCount == null && (effectiveAdults != null || effectiveChildren != null)) {
          effectiveGuestsCount = (effectiveAdults ?? 0) + (effectiveChildren ?? 0);
        }
        if (!supportsGuests) {
          effectiveGuestsCount = null;
          effectiveAdults = null;
          effectiveChildren = null;
        }
      }
    } catch (_) {
      // Ignore lookup errors; fallback to provided guestsCount
    }

    final String preferredCurrency = sharedPreferences.getString('selected_currency') ?? 'YER';

    final params = SearchPropertiesParams(
      searchTerm: event.searchTerm,
      city: event.city,
      propertyTypeId: event.propertyTypeId,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      minStarRating: event.minStarRating,
      requiredAmenities: event.requiredAmenities,
      unitTypeId: event.unitTypeId,
      serviceIds: event.serviceIds,
      dynamicFieldFilters: event.dynamicFieldFilters,
      checkIn: event.checkIn,
      checkOut: event.checkOut,
      adults: effectiveAdults,
      children: effectiveChildren,
      guestsCount: effectiveGuestsCount,
      latitude: event.latitude,
      longitude: event.longitude,
      radiusKm: event.radiusKm,
      preferredCurrency: preferredCurrency,
      sortBy: event.sortBy,
      pageNumber: event.pageNumber,
      pageSize: event.pageSize,
    );

    final result = await searchPropertiesUseCase(params);

    result.fold(
      (failure) {
        emit((state as SearchCombinedState).copyWith(
          searchResultsState: SearchError(message: failure.message),
        ));
      },
      (paginatedResult) {
        if (event.isNewSearch) {
          _currentSearchResults = paginatedResult;
          _currentFilters = _buildFiltersMap(event);
          // Sanitize guests fields for non-guest unit types
          if (effectiveGuestsCount == null) {
            _currentFilters.remove('guestsCount');
          } else {
            _currentFilters['guestsCount'] = effectiveGuestsCount;
          }
          if (effectiveAdults == null) {
            _currentFilters.remove('adults');
          } else {
            _currentFilters['adults'] = effectiveAdults;
          }
          if (effectiveChildren == null) {
            _currentFilters.remove('children');
          } else {
            _currentFilters['children'] = effectiveChildren;
          }
          // Ensure default city/currency are propagated for subsequent loads
          _currentFilters['city'] = _currentFilters['city'] ?? (sharedPreferences.getString('selected_city') ?? '');
          _currentFilters['preferredCurrency'] = preferredCurrency;
          // Persist current filters
          filterStorageService.saveCurrentFilters(_currentFilters);
        } else {
          // Append new results to existing ones
          final updatedItems = [
            ..._currentSearchResults!.items,
            ...paginatedResult.items,
          ];
          _currentSearchResults = PaginatedResult(
            items: updatedItems,
            pageNumber: paginatedResult.pageNumber,
            pageSize: paginatedResult.pageSize,
            totalCount: paginatedResult.totalCount,
            metadata: paginatedResult.metadata,
          );
        }

        final hasReachedMax = _currentSearchResults!.items.length >= 
            _currentSearchResults!.totalCount;

        emit((state as SearchCombinedState).copyWith(
          searchResultsState: SearchSuccess(
            searchResults: _currentSearchResults!,
            currentFilters: _currentFilters,
            hasReachedMax: hasReachedMax,
          ),
        ));

        // Add to recent searches if it's a new search with query
        if (event.isNewSearch && event.searchTerm != null && event.searchTerm!.isNotEmpty) {
          add(AddToRecentSearchesEvent(suggestion: event.searchTerm!));
        }
      },
    );
  }

  void _onLoadMoreSearchResults(
    LoadMoreSearchResultsEvent event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state as SearchCombinedState;
    if (currentState.searchResultsState is SearchSuccess) {
      final successState = currentState.searchResultsState as SearchSuccess;
      
      if (!successState.hasReachedMax) {
        final nextPage = successState.searchResults.pageNumber + 1;
        
        add(SearchPropertiesEvent(
          searchTerm: _currentFilters['searchTerm'] as String?,
          city: _currentFilters['city'] as String?,
          propertyTypeId: _currentFilters['propertyTypeId'] as String?,
          minPrice: _currentFilters['minPrice'] as double?,
          maxPrice: _currentFilters['maxPrice'] as double?,
          minStarRating: _currentFilters['minStarRating'] as int?,
          requiredAmenities: _currentFilters['requiredAmenities'] as List<String>?,
          unitTypeId: _currentFilters['unitTypeId'] as String?,
          serviceIds: _currentFilters['serviceIds'] as List<String>?,
          dynamicFieldFilters: _currentFilters['dynamicFieldFilters'] as Map<String, dynamic>?,
          checkIn: _currentFilters['checkIn'] as DateTime?,
          checkOut: _currentFilters['checkOut'] as DateTime?,
          adults: _currentFilters['adults'] as int?,
          children: _currentFilters['children'] as int?,
          guestsCount: _currentFilters['guestsCount'] as int?,
          latitude: _currentFilters['latitude'] as double?,
          longitude: _currentFilters['longitude'] as double?,
          radiusKm: _currentFilters['radiusKm'] as double?,
          sortBy: _currentFilters['sortBy'] as String?,
          pageNumber: nextPage,
          pageSize: successState.searchResults.pageSize,
        ));
      }
    }
  }

  void _onGetSearchFilters(
    GetSearchFiltersEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit((state as SearchCombinedState).copyWith(
      filtersState: const SearchFiltersLoading(),
    ));

    try {
      // محاولة جلب الفلاتر من الباك اند
      final result = await getSearchFiltersUseCase(NoParams());

      result.fold(
        (failure) {
          // في حالة الفشل، محاولة استخدام البيانات المحفوظة محلياً
          _loadFiltersFromLocalData(emit);
        },
        (filters) {
          emit((state as SearchCombinedState).copyWith(
            filtersState: SearchFiltersLoaded(filters: filters),
          ));
          // Try preload saved filters for continuity
          final saved = filterStorageService.getCurrentFilters();
          if (saved != null && saved.isNotEmpty) {
            _currentFilters = saved;
          }
        },
      );
    } catch (e) {
      // في حالة الخطأ، محاولة استخدام البيانات المحفوظة محلياً
      _loadFiltersFromLocalData(emit);
    }
  }

  void _loadFiltersFromLocalData(Emitter<SearchState> emit) async {
    try {
      // جلب أنواع العقارات المحفوظة (تُعاد كـ Future لذلك نستخدم await)
      final propertyTypes = await dataSyncService.getPropertyTypes();
      
      // إنشاء فلاتر بسيطة من البيانات المحفوظة
      final localFilters = SearchFilters(
        propertyTypes: propertyTypes.map((pt) => PropertyTypeFilter(
          id: pt.id,
          name: pt.name,
          propertiesCount: pt.propertiesCount,
        )).toList(),
        unitTypes: [],
        amenities: [],
        priceRange: const PriceRange(minPrice: 0.0, maxPrice: 1000000.0, averagePrice: 500000.0),
        cities: [],
        services: [],
        // القيم المضافة لتلبية المعاملات المطلوبة الجديدة
        starRatings: const [1, 2, 3, 4, 5],
        availableCities: const [],
        maxGuestCapacity: 0,
        distanceRange: const DistanceRange(minDistance: 0, maxDistance: 0),
        supportedCurrencies: const [],
        dynamicFieldValues: const [],
      );

      emit((state as SearchCombinedState).copyWith(
        filtersState: SearchFiltersLoaded(filters: localFilters),
      ));
    } catch (e) {
      emit((state as SearchCombinedState).copyWith(
        filtersState: SearchFiltersError(message: 'لا يمكن تحميل الفلاتر'),
      ));
    }
  }

  void _onGetSearchSuggestions(
    GetSearchSuggestionsEvent event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit((state as SearchCombinedState).copyWith(
        suggestionsState: const SearchSuggestionsLoaded(suggestions: []),
      ));
      return;
    }

    emit((state as SearchCombinedState).copyWith(
      suggestionsState: const SearchSuggestionsLoading(),
    ));

    final params = SearchSuggestionsParams(
      query: event.query,
      limit: event.limit,
    );

    final result = await getSearchSuggestionsUseCase(params);

    result.fold(
      (failure) {
        emit((state as SearchCombinedState).copyWith(
          suggestionsState: SearchSuggestionsError(message: failure.message),
        ));
      },
      (suggestions) {
        emit((state as SearchCombinedState).copyWith(
          suggestionsState: SearchSuggestionsLoaded(suggestions: suggestions),
        ));
      },
    );
  }

  void _onClearSearchSuggestions(
    ClearSearchSuggestionsEvent event,
    Emitter<SearchState> emit,
  ) {
    final currentState = state as SearchCombinedState;
    emit((state as SearchCombinedState).copyWith(
      suggestionsState: const SearchSuggestionsLoaded(suggestions: []),
    ));
  }

  void _onGetRecommendedProperties(
    GetRecommendedPropertiesEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit((state as SearchCombinedState).copyWith(
      recommendedState: const RecommendedPropertiesLoading(),
    ));

    final result = await searchRepository.getRecommendedProperties(
      userId: event.userId,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        emit((state as SearchCombinedState).copyWith(
          recommendedState: RecommendedPropertiesError(message: failure.message),
        ));
      },
      (properties) {
        emit((state as SearchCombinedState).copyWith(
          recommendedState: RecommendedPropertiesLoaded(properties: properties),
        ));
      },
    );
  }

  void _onGetPopularDestinations(
    GetPopularDestinationsEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit((state as SearchCombinedState).copyWith(
      popularDestinationsState: const PopularDestinationsLoading(),
    ));

    final result = await searchRepository.getPopularDestinations(
      limit: event.limit,
    );

    result.fold(
      (failure) {
        emit((state as SearchCombinedState).copyWith(
          popularDestinationsState: PopularDestinationsError(message: failure.message),
        ));
      },
      (destinations) {
        emit((state as SearchCombinedState).copyWith(
          popularDestinationsState: PopularDestinationsLoaded(destinations: destinations),
        ));
      },
    );
  }

  void _onUpdateSearchFilters(
    UpdateSearchFiltersEvent event,
    Emitter<SearchState> emit,
  ) {
    _currentFilters = _buildFiltersMap(event);
    filterStorageService.saveCurrentFilters(_currentFilters);
  }

  void _onClearSearchResults(
    ClearSearchResultsEvent event,
    Emitter<SearchState> emit,
  ) {
    final currentState = state as SearchCombinedState;
    _currentSearchResults = null;
    _currentFilters = {};
    emit((state as SearchCombinedState).copyWith(
      searchResultsState: const SearchInitial(),
    ));
  }

  void _onAddToRecentSearches(
    AddToRecentSearchesEvent event,
    Emitter<SearchState> emit,
  ) async {
    final recentSearches = List<String>.from((state as SearchCombinedState).recentSearches);
    
    // Remove if already exists
    recentSearches.remove(event.suggestion);
    
    // Add to beginning
    recentSearches.insert(0, event.suggestion);
    
    // Keep only max allowed
    if (recentSearches.length > _maxRecentSearches) {
      recentSearches.removeRange(_maxRecentSearches, recentSearches.length);
    }
    
    // Save to local storage
    await sharedPreferences.setStringList(_recentSearchesKey, recentSearches);
    
    emit((state as SearchCombinedState).copyWith(recentSearches: recentSearches));
  }

  void _onLoadRecentSearches(
    LoadRecentSearchesEvent event,
    Emitter<SearchState> emit,
  ) {
    final recentSearches = sharedPreferences.getStringList(_recentSearchesKey) ?? [];
    emit((state as SearchCombinedState).copyWith(recentSearches: recentSearches));
  }

  void _onClearRecentSearches(
    ClearRecentSearchesEvent event,
    Emitter<SearchState> emit,
  ) async {
    await sharedPreferences.remove(_recentSearchesKey);
    emit((state as SearchCombinedState).copyWith(recentSearches: []));
  }

  void _onSaveSearch(
    SaveSearchEvent event,
    Emitter<SearchState> emit,
  ) async {
    final savedSearches = List<SavedSearch>.from((state as SearchCombinedState).savedSearches);
    
    final newSearch = SavedSearch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: event.name,
      searchParams: event.searchParams,
      createdAt: DateTime.now(),
    );
    
    savedSearches.add(newSearch);
    
    // Save to local storage
    final savedSearchesJson = savedSearches.map((search) => {
      'id': search.id,
      'name': search.name,
      'searchParams': search.searchParams,
      'createdAt': search.createdAt.toIso8601String(),
    }).toList();
    
    await sharedPreferences.setString(
      _savedSearchesKey,
      json.encode(savedSearchesJson),
    );
    
    emit((state as SearchCombinedState).copyWith(savedSearches: savedSearches));
  }

  void _onLoadSavedSearches(
    LoadSavedSearchesEvent event,
    Emitter<SearchState> emit,
  ) {
    final savedSearchesJson = sharedPreferences.getString(_savedSearchesKey);
    
    if (savedSearchesJson != null) {
      final decoded = json.decode(savedSearchesJson) as List;
      final savedSearches = decoded.map((item) => SavedSearch(
        id: item['id'],
        name: item['name'],
        searchParams: Map<String, dynamic>.from(item['searchParams']),
        createdAt: DateTime.parse(item['createdAt']),
      )).toList();
      
      emit((state as SearchCombinedState).copyWith(savedSearches: savedSearches));
    }
  }

  void _onDeleteSavedSearch(
    DeleteSavedSearchEvent event,
    Emitter<SearchState> emit,
  ) async {
    final savedSearches = (state as SearchCombinedState).savedSearches
        .where((search) => search.id != event.searchId)
        .toList();
    
    // Save updated list to local storage
    final savedSearchesJson = savedSearches.map((search) => {
      'id': search.id,
      'name': search.name,
      'searchParams': search.searchParams,
      'createdAt': search.createdAt.toIso8601String(),
    }).toList();
    
    await sharedPreferences.setString(
      _savedSearchesKey,
      json.encode(savedSearchesJson),
    );
    
    emit((state as SearchCombinedState).copyWith(savedSearches: savedSearches));
  }

  void _onApplySavedSearch(
    ApplySavedSearchEvent event,
    Emitter<SearchState> emit,
  ) {
    add(SearchPropertiesEvent(
      searchTerm: event.searchParams['searchTerm'] as String?,
      city: event.searchParams['city'] as String?,
      propertyTypeId: event.searchParams['propertyTypeId'] as String?,
      minPrice: event.searchParams['minPrice'] as double?,
      maxPrice: event.searchParams['maxPrice'] as double?,
      minStarRating: event.searchParams['minStarRating'] as int?,
      requiredAmenities: event.searchParams['requiredAmenities'] != null
          ? List<String>.from(event.searchParams['requiredAmenities'])
          : null,
      unitTypeId: event.searchParams['unitTypeId'] as String?,
      serviceIds: event.searchParams['serviceIds'] != null
          ? List<String>.from(event.searchParams['serviceIds'])
          : null,
      dynamicFieldFilters: event.searchParams['dynamicFieldFilters'] != null
          ? Map<String, dynamic>.from(event.searchParams['dynamicFieldFilters'])
          : null,
      checkIn: event.searchParams['checkIn'] != null
          ? DateTime.parse(event.searchParams['checkIn'])
          : null,
      checkOut: event.searchParams['checkOut'] != null
          ? DateTime.parse(event.searchParams['checkOut'])
          : null,
      guestsCount: event.searchParams['guestsCount'] as int?,
      latitude: event.searchParams['latitude'] as double?,
      longitude: event.searchParams['longitude'] as double?,
      radiusKm: event.searchParams['radiusKm'] as double?,
      sortBy: event.searchParams['sortBy'] as String?,
    ));
  }

  Map<String, dynamic> _buildFiltersMap(dynamic event) {
    final filters = <String, dynamic>{};
    
    if (event is SearchPropertiesEvent) {
      if (event.searchTerm != null) filters['searchTerm'] = event.searchTerm;
      if (event.city != null) filters['city'] = event.city;
      if (event.propertyTypeId != null) filters['propertyTypeId'] = event.propertyTypeId;
      if (event.minPrice != null) filters['minPrice'] = event.minPrice;
      if (event.maxPrice != null) filters['maxPrice'] = event.maxPrice;
      if (event.minStarRating != null) filters['minStarRating'] = event.minStarRating;
      if (event.requiredAmenities != null) filters['requiredAmenities'] = event.requiredAmenities;
      if (event.unitTypeId != null) filters['unitTypeId'] = event.unitTypeId;
      if (event.serviceIds != null) filters['serviceIds'] = event.serviceIds;
      if (event.dynamicFieldFilters != null) filters['dynamicFieldFilters'] = event.dynamicFieldFilters;
      if (event.checkIn != null) filters['checkIn'] = event.checkIn;
      if (event.checkOut != null) filters['checkOut'] = event.checkOut;
      if (event.adults != null) filters['adults'] = event.adults;
      if (event.children != null) filters['children'] = event.children;
      if (event.guestsCount != null) filters['guestsCount'] = event.guestsCount;
      if (event.latitude != null) filters['latitude'] = event.latitude;
      if (event.longitude != null) filters['longitude'] = event.longitude;
      if (event.radiusKm != null) filters['radiusKm'] = event.radiusKm;
      if (event.sortBy != null) filters['sortBy'] = event.sortBy;
    } else if (event is UpdateSearchFiltersEvent) {
      // Merge new filters into current filters
      filters.addAll(event.filters);
    }
    
    return filters;
  }
}