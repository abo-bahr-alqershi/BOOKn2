import 'package:equatable/equatable.dart';
import '../../../domain/entities/property_type.dart';

abstract class PropertyTypesState extends Equatable {
  const PropertyTypesState();

  @override
  List<Object?> get props => [];
}

class PropertyTypesInitial extends PropertyTypesState {}

class PropertyTypesLoading extends PropertyTypesState {}

class PropertyTypesLoaded extends PropertyTypesState {
  final List<PropertyType> propertyTypes;
  final PropertyType? selectedPropertyType;
  final int totalCount;
  final int currentPage;

  const PropertyTypesLoaded({
    required this.propertyTypes,
    this.selectedPropertyType,
    required this.totalCount,
    required this.currentPage,
  });

  PropertyTypesLoaded copyWith({
    List<PropertyType>? propertyTypes,
    PropertyType? selectedPropertyType,
    bool clearSelection = false,
    int? totalCount,
    int? currentPage,
  }) {
    return PropertyTypesLoaded(
      propertyTypes: propertyTypes ?? this.propertyTypes,
      selectedPropertyType: clearSelection ? null : (selectedPropertyType ?? this.selectedPropertyType),
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [propertyTypes, selectedPropertyType, totalCount, currentPage];
}

class PropertyTypesError extends PropertyTypesState {
  final String message;

  const PropertyTypesError({required this.message});

  @override
  List<Object> get props => [message];
}

class PropertyTypeOperationLoading extends PropertyTypesState {}

class PropertyTypeOperationSuccess extends PropertyTypesState {
  final String message;

  const PropertyTypeOperationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class PropertyTypeOperationError extends PropertyTypesState {
  final String message;

  const PropertyTypeOperationError({required this.message});

  @override
  List<Object> get props => [message];
}