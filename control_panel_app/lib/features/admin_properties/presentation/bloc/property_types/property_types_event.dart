// lib/features/admin_properties/presentation/bloc/property_types/property_types_event.dart

part of 'property_types_bloc.dart';

abstract class PropertyTypesEvent extends Equatable {
  const PropertyTypesEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadPropertyTypesEvent extends PropertyTypesEvent {
  final int pageNumber;
  final int pageSize;
  
  const LoadPropertyTypesEvent({
    this.pageNumber = 1,
    this.pageSize = 10,
  });
  
  @override
  List<Object> get props => [pageNumber, pageSize];
}

class CreatePropertyTypeEvent extends PropertyTypesEvent {
  final String name;
  final String description;
  final String defaultAmenities;
  final String icon;
  
  const CreatePropertyTypeEvent({
    required this.name,
    required this.description,
    required this.defaultAmenities,
    required this.icon,
  });
  
  @override
  List<Object> get props => [name, description, defaultAmenities, icon];
}

class UpdatePropertyTypeEvent extends PropertyTypesEvent {
  final String propertyTypeId;
  final String? name;
  final String? description;
  final String? defaultAmenities;
  final String? icon;
  
  const UpdatePropertyTypeEvent({
    required this.propertyTypeId,
    this.name,
    this.description,
    this.defaultAmenities,
    this.icon,
  });
  
  @override
  List<Object?> get props => [propertyTypeId, name, description, defaultAmenities, icon];
}

class DeletePropertyTypeEvent extends PropertyTypesEvent {
  final String propertyTypeId;
  
  const DeletePropertyTypeEvent(this.propertyTypeId);
  
  @override
  List<Object> get props => [propertyTypeId];
}