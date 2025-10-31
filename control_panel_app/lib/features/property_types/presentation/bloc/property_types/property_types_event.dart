import 'package:equatable/equatable.dart';

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
    this.pageSize = 1000,
  });

  @override
  List<Object> get props => [pageNumber, pageSize];
}

class CreatePropertyTypeEvent extends PropertyTypesEvent {
  final String name;
  final String description;
  final List<String> defaultAmenities;
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
  final String name;
  final String description;
  final List<String> defaultAmenities;
  final String icon;

  const UpdatePropertyTypeEvent({
    required this.propertyTypeId,
    required this.name,
    required this.description,
    required this.defaultAmenities,
    required this.icon,
  });

  @override
  List<Object> get props => [propertyTypeId, name, description, defaultAmenities, icon];
}

class DeletePropertyTypeEvent extends PropertyTypesEvent {
  final String propertyTypeId;

  const DeletePropertyTypeEvent({required this.propertyTypeId});

  @override
  List<Object> get props => [propertyTypeId];
}

class SelectPropertyTypeEvent extends PropertyTypesEvent {
  final String? propertyTypeId;

  const SelectPropertyTypeEvent({this.propertyTypeId});

  @override
  List<Object?> get props => [propertyTypeId];
}