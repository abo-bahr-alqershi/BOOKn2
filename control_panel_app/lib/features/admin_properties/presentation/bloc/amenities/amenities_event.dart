// lib/features/admin_properties/presentation/bloc/amenities/amenities_event.dart

part of 'amenities_bloc.dart';

abstract class AmenitiesEvent extends Equatable {
  const AmenitiesEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadAmenitiesEvent extends AmenitiesEvent {
  final int pageNumber;
  final int pageSize;
  final String? searchTerm;
  final String? propertyId;
  final bool? isAssigned;
  final bool? isFree;
  
  const LoadAmenitiesEvent({
    this.pageNumber = 1,
    this.pageSize = 10,
    this.searchTerm,
    this.propertyId,
    this.isAssigned,
    this.isFree,
  });
  
  @override
  List<Object?> get props => [pageNumber, pageSize, searchTerm, propertyId, isAssigned, isFree];
}

class LoadAmenitiesEventWithType extends LoadAmenitiesEvent {
  final String propertyTypeId;

  const LoadAmenitiesEventWithType({
    this.propertyTypeId = '',
    int pageNumber = 1,
    int pageSize = 10,
    String? searchTerm,
  }) : super(pageNumber: pageNumber, pageSize: pageSize, searchTerm: searchTerm);

  @override
  List<Object?> get props => [propertyTypeId, pageNumber, pageSize, searchTerm];
}

class CreateAmenityEvent extends AmenitiesEvent {
  final String name;
  final String description;
  final String icon;
  
  const CreateAmenityEvent({
    required this.name,
    required this.description,
    required this.icon,
  });
  
  @override
  List<Object> get props => [name, description, icon];
}

class UpdateAmenityEvent extends AmenitiesEvent {
  final String amenityId;
  final String? name;
  final String? description;
  final String? icon;
  
  const UpdateAmenityEvent({
    required this.amenityId,
    this.name,
    this.description,
    this.icon,
  });
  
  @override
  List<Object?> get props => [amenityId, name, description, icon];
}

class DeleteAmenityEvent extends AmenitiesEvent {
  final String amenityId;
  
  const DeleteAmenityEvent(this.amenityId);
  
  @override
  List<Object> get props => [amenityId];
}

class AssignAmenityToPropertyEvent extends AmenitiesEvent {
  final String amenityId;
  final String propertyId;
  final bool isAvailable;
  final double? extraCost;
  final String? currency;
  final String? description;
  
  const AssignAmenityToPropertyEvent({
    required this.amenityId,
    required this.propertyId,
    this.isAvailable = true,
    this.extraCost,
    this.currency,
    this.description,
  });
  
  @override
  List<Object?> get props => [amenityId, propertyId, isAvailable, extraCost, currency, description];
}

class UnassignAmenityFromPropertyEvent extends AmenitiesEvent {
  final String amenityId;
  final String propertyId;

  const UnassignAmenityFromPropertyEvent({
    required this.amenityId,
    required this.propertyId,
  });

  @override
  List<Object> get props => [amenityId, propertyId];
}