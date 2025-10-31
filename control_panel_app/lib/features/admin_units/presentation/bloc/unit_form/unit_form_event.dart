part of 'unit_form_bloc.dart';

abstract class UnitFormEvent extends Equatable {
  const UnitFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeFormEvent extends UnitFormEvent {
  final String? unitId;
  final String? tempKey;

  const InitializeFormEvent({this.unitId, this.tempKey});

  @override
  List<Object?> get props => [unitId, tempKey];
}

class PropertySelectedEvent extends UnitFormEvent {
  final String? propertyId; // physical property id (used in submission)
  final String? propertyTypeId; // used to load unit types

  const PropertySelectedEvent({this.propertyId, this.propertyTypeId});

  @override
  List<Object?> get props => [propertyId, propertyTypeId];
}

class UnitTypeSelectedEvent extends UnitFormEvent {
  final String unitTypeId;

  const UnitTypeSelectedEvent({required this.unitTypeId});

  @override
  List<Object?> get props => [unitTypeId];
}

class UpdateCapacityEvent extends UnitFormEvent {
  final int? adultCapacity;
  final int? childrenCapacity;

  const UpdateCapacityEvent({
    this.adultCapacity,
    this.childrenCapacity,
  });

  @override
  List<Object?> get props => [adultCapacity, childrenCapacity];
}

class UpdateUnitImageEvent extends UnitFormEvent {
  final List<String>? images;

  const UpdateUnitImageEvent({
    this.images,
  });

  @override
  List<Object?> get props => [images];
}

class UpdatePricingEvent extends UnitFormEvent {
  final Money basePrice;
  final PricingMethod pricingMethod;

  const UpdatePricingEvent({
    required this.basePrice,
    required this.pricingMethod,
  });

  @override
  List<Object?> get props => [basePrice, pricingMethod];
}

class UpdateFeaturesEvent extends UnitFormEvent {
  final String features;

  const UpdateFeaturesEvent({required this.features});

  @override
  List<Object?> get props => [features];
}

class UpdateDynamicFieldsEvent extends UnitFormEvent {
  final Map<String, dynamic> values;

  const UpdateDynamicFieldsEvent({required this.values});

  @override
  List<Object?> get props => [values];
}

class UpdateUnitNameEvent extends UnitFormEvent {
  final String name;

  const UpdateUnitNameEvent({required this.name});

  @override
  List<Object?> get props => [name];
}

class UpdateDescriptionEvent extends UnitFormEvent {
  final String description;

  const UpdateDescriptionEvent({required this.description});

  @override
  List<Object?> get props => [description];
}

class SubmitFormEvent extends UnitFormEvent {}

class UpdateCancellationPolicyEvent extends UnitFormEvent {
  final bool allowsCancellation;
  final int? cancellationWindowDays;

  const UpdateCancellationPolicyEvent({
    required this.allowsCancellation,
    this.cancellationWindowDays,
  });

  @override
  List<Object?> get props => [allowsCancellation, cancellationWindowDays];
}