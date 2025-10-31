// lib/features/admin_properties/presentation/bloc/property_types/property_types_state.dart

part of 'property_types_bloc.dart';

abstract class PropertyTypesState extends Equatable {
  const PropertyTypesState();
  
  @override
  List<Object?> get props => [];
}

class PropertyTypesInitial extends PropertyTypesState {}

class PropertyTypesLoading extends PropertyTypesState {}

class PropertyTypesLoaded extends PropertyTypesState {
  final List<PropertyType> propertyTypes;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  
  const PropertyTypesLoaded({
    required this.propertyTypes,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
  
  @override
  List<Object> get props => [
    propertyTypes,
    totalCount,
    currentPage,
    totalPages,
    hasNextPage,
    hasPreviousPage,
  ];
}

class PropertyTypesError extends PropertyTypesState {
  final String message;
  
  const PropertyTypesError(this.message);
  
  @override
  List<Object> get props => [message];
}

class PropertyTypeCreating extends PropertyTypesState {}

class PropertyTypeCreated extends PropertyTypesState {
  final String propertyTypeId;
  
  const PropertyTypeCreated(this.propertyTypeId);
  
  @override
  List<Object> get props => [propertyTypeId];
}

class PropertyTypeUpdating extends PropertyTypesState {}

class PropertyTypeUpdated extends PropertyTypesState {}

class PropertyTypeDeleting extends PropertyTypesState {}

class PropertyTypeDeleted extends PropertyTypesState {}