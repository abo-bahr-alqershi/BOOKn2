// lib/features/home/presentation/bloc/home_event.dart
import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

// Load initial data
class LoadHomeDataEvent extends HomeEvent {
  final bool forceRefresh;
  
  const LoadHomeDataEvent({this.forceRefresh = false});
  
  @override
  List<Object?> get props => [forceRefresh];
}

// Load sections
class LoadSectionsEvent extends HomeEvent {
  final int pageNumber;
  final int pageSize;
  final String? target;
  final String? type;
  final bool forceRefresh;
  
  const LoadSectionsEvent({
    this.pageNumber = 1,
    this.pageSize = 10,
    this.target,
    this.type,
    this.forceRefresh = false,
  });
  
  @override
  List<Object?> get props => [pageNumber, pageSize, target, type, forceRefresh];
}

// Load section data
class LoadSectionDataEvent extends HomeEvent {
  final String sectionId;
  final int pageNumber;
  final int pageSize;
  final bool forceRefresh;
  
  const LoadSectionDataEvent({
    required this.sectionId,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.forceRefresh = false,
  });
  
  @override
  List<Object?> get props => [sectionId, pageNumber, pageSize, forceRefresh];
}

// Load property types
class LoadPropertyTypesEvent extends HomeEvent {
  const LoadPropertyTypesEvent();
}

// Load unit types
class LoadUnitTypesEvent extends HomeEvent {
  final String propertyTypeId;
  
  const LoadUnitTypesEvent({required this.propertyTypeId});
  
  @override
  List<Object?> get props => [propertyTypeId];
}

// Analytics events
class RecordSectionImpressionEvent extends HomeEvent {
  final String sectionId;
  
  const RecordSectionImpressionEvent({required this.sectionId});
  
  @override
  List<Object?> get props => [sectionId];
}

class RecordSectionInteractionEvent extends HomeEvent {
  final String sectionId;
  final String interactionType;
  final String? itemId;
  final Map<String, dynamic>? metadata;
  
  const RecordSectionInteractionEvent({
    required this.sectionId,
    required this.interactionType,
    this.itemId,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [sectionId, interactionType, itemId, metadata];
}

// Search events
class UpdateSearchQueryEvent extends HomeEvent {
  final String query;
  
  const UpdateSearchQueryEvent({required this.query});
  
  @override
  List<Object?> get props => [query];
}

class ClearSearchEvent extends HomeEvent {
  const ClearSearchEvent();
}

// Filter events
class UpdatePropertyTypeFilterEvent extends HomeEvent {
  final String? propertyTypeId;
  
  const UpdatePropertyTypeFilterEvent({this.propertyTypeId});
  
  @override
  List<Object?> get props => [propertyTypeId];
}

class UpdateUnitTypeSelectionEvent extends HomeEvent {
  final String? unitTypeId;

  const UpdateUnitTypeSelectionEvent({this.unitTypeId});

  @override
  List<Object?> get props => [unitTypeId];
}

class UpdateDynamicFieldValuesEvent extends HomeEvent {
  final Map<String, dynamic> values;

  const UpdateDynamicFieldValuesEvent({required this.values});

  @override
  List<Object?> get props => [values];
}

// Refresh events
class RefreshHomeDataEvent extends HomeEvent {
  const RefreshHomeDataEvent();
}

class LoadMoreSectionDataEvent extends HomeEvent {
  final String sectionId;
  
  const LoadMoreSectionDataEvent({required this.sectionId});
  
  @override
  List<Object?> get props => [sectionId];
}