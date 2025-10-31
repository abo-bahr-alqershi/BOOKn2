// lib/features/home/presentation/bloc/home_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/section.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/entities/unit_type.dart';
import '../../../home/data/models/section_item_models.dart';
import '../../../search/data/models/search_result_model.dart';
import '../../../../core/models/paginated_result.dart' as core;

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<Section> sections;
  final Map<String, core.PaginatedResult<SectionPropertyItemModel>> sectionData;
  final List<PropertyType> propertyTypes;
  final Map<String, List<UnitType>> unitTypes;
  final bool combinedUnitsPreloaded;
  final String? selectedPropertyTypeId;
  final String? selectedUnitTypeId;
  final Map<String, dynamic> dynamicFieldValues;
  final String searchQuery;
  final bool isRefreshing;
  final bool hasReachedMax;
  final Map<String, bool> sectionsLoadingMore;

  const HomeLoaded({
    required this.sections,
    required this.sectionData,
    required this.propertyTypes,
    required this.unitTypes,
    this.combinedUnitsPreloaded = false,
    this.selectedPropertyTypeId,
    this.selectedUnitTypeId,
    this.dynamicFieldValues = const {},
    this.searchQuery = '',
    this.isRefreshing = false,
    this.hasReachedMax = false,
    required this.sectionsLoadingMore,
  });

  @override
  List<Object?> get props => [
        sections,
        sectionData,
        propertyTypes,
        unitTypes,
        combinedUnitsPreloaded,
        selectedPropertyTypeId,
        selectedUnitTypeId,
        dynamicFieldValues,
        searchQuery,
        isRefreshing,
        hasReachedMax,
        sectionsLoadingMore,
      ];

  HomeLoaded copyWith({
    List<Section>? sections,
    Map<String, core.PaginatedResult<SectionPropertyItemModel>>? sectionData,
    List<PropertyType>? propertyTypes,
    Map<String, List<UnitType>>? unitTypes,
    bool? combinedUnitsPreloaded,
    String? selectedPropertyTypeId,
    String? selectedUnitTypeId,
    Map<String, dynamic>? dynamicFieldValues,
    String? searchQuery,
    bool? isRefreshing,
    bool? hasReachedMax,
    Map<String, bool>? sectionsLoadingMore,
  }) {
    return HomeLoaded(
      sections: sections ?? this.sections,
      sectionData: sectionData ?? this.sectionData,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      unitTypes: unitTypes ?? this.unitTypes,
      combinedUnitsPreloaded: combinedUnitsPreloaded ?? this.combinedUnitsPreloaded,
      selectedPropertyTypeId: selectedPropertyTypeId ?? this.selectedPropertyTypeId,
      selectedUnitTypeId: selectedUnitTypeId ?? this.selectedUnitTypeId,
      dynamicFieldValues: dynamicFieldValues ?? this.dynamicFieldValues,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      sectionsLoadingMore: sectionsLoadingMore ?? this.sectionsLoadingMore,
    );
  }
}

class SectionLoading extends HomeState {
  final String sectionId;
  
  const SectionLoading({required this.sectionId});
  
  @override
  List<Object?> get props => [sectionId];
}

class SectionDataLoaded extends HomeState {
  final String sectionId;
  final core.PaginatedResult<SectionPropertyItemModel> data;
  
  const SectionDataLoaded({
    required this.sectionId,
    required this.data,
  });
  
  @override
  List<Object?> get props => [sectionId, data];
}

class PropertyTypesLoaded extends HomeState {
  final List<PropertyType> propertyTypes;
  
  const PropertyTypesLoaded({required this.propertyTypes});
  
  @override
  List<Object?> get props => [propertyTypes];
}

class UnitTypesLoaded extends HomeState {
  final String propertyTypeId;
  final List<UnitType> unitTypes;
  
  const UnitTypesLoaded({
    required this.propertyTypeId,
    required this.unitTypes,
  });
  
  @override
  List<Object?> get props => [propertyTypeId, unitTypes];
}

class HomeError extends HomeState {
  final String message;
  final String? errorCode;
  
  const HomeError({
    required this.message,
    this.errorCode,
  });
  
  @override
  List<Object?> get props => [message, errorCode];
}

class SectionError extends HomeState {
  final String sectionId;
  final String message;
  
  const SectionError({
    required this.sectionId,
    required this.message,
  });
  
  @override
  List<Object?> get props => [sectionId, message];
}

class SearchState extends HomeState {
  final String query;
  final List<SearchResultModel> results;
  final bool isLoading;
  
  const SearchState({
    required this.query,
    required this.results,
    this.isLoading = false,
  });
  
  @override
  List<Object?> get props => [query, results, isLoading];
}