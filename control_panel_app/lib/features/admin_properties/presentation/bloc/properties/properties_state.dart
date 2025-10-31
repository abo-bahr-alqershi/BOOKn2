// lib/features/admin_properties/presentation/bloc/properties/properties_state.dart

part of 'properties_bloc.dart';

abstract class PropertiesState extends Equatable {
  const PropertiesState();
  
  @override
  List<Object?> get props => [];
}

class PropertiesInitial extends PropertiesState {}

class PropertiesLoading extends PropertiesState {}

class PropertiesLoaded extends PropertiesState {
  final List<Property> properties;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? searchTerm;
  final Map<String, dynamic>? activeFilters;
  final Map<String, dynamic>? stats;
  
  const PropertiesLoaded({
    required this.properties,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.searchTerm,
    this.activeFilters,
    this.stats,
  });
  
  @override
  List<Object?> get props => [
    properties, totalCount, currentPage, totalPages,
    hasNextPage, hasPreviousPage, searchTerm, activeFilters, stats,
  ];
}

// إضافة حالات جديدة لتفاصيل العقار
class PropertyDetailsLoading extends PropertiesState {}

class PropertyDetailsLoaded extends PropertiesState {
  final Property property;
  
  const PropertyDetailsLoaded(this.property);
  
  @override
  List<Object> get props => [property];
}

class PropertyDetailsError extends PropertiesState {
  final String message;
  
  const PropertyDetailsError(this.message);
  
  @override
  List<Object> get props => [message];
}

class PropertiesError extends PropertiesState {
  final String message;
  
  const PropertiesError(this.message);
  
  @override
  List<Object> get props => [message];
}

class PropertyCreating extends PropertiesState {}

class PropertyCreated extends PropertiesState {
  final String propertyId;
  
  const PropertyCreated(this.propertyId);
  
  @override
  List<Object> get props => [propertyId];
}

class PropertyUpdating extends PropertiesState {}

class PropertyUpdated extends PropertiesState {}

class PropertyDeleting extends PropertiesState {}

class PropertyDeleted extends PropertiesState {}

class PropertyStatusUpdated extends PropertiesState {
  final String propertyId;
  final bool isApproved;
  
  const PropertyStatusUpdated(this.propertyId, this.isApproved);
  
  @override
  List<Object> get props => [propertyId, isApproved];
}