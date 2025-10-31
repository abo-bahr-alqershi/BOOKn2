part of 'unit_form_bloc.dart';

abstract class UnitFormState extends Equatable {
  const UnitFormState();

  @override
  List<Object?> get props => [];
}

class UnitFormInitial extends UnitFormState {}

class UnitFormLoading extends UnitFormState {}

class UnitFormReady extends UnitFormState {
  final bool isEditMode;
  final String? unitId;
  final String? selectedPropertyId;
  final String? tempKey;
  final List<UnitType> availableUnitTypes;
  final UnitType? selectedUnitType;
  final List<UnitTypeField> unitTypeFields;
  final String? unitName;
  final String? description;
  final Money? basePrice;
  final PricingMethod? pricingMethod;
  final String? customFeatures;
  final Map<String, dynamic> dynamicFieldValues;
  final List<String>? images;
  final int? adultCapacity;
  final int? childrenCapacity;
  final bool isLoadingUnitTypes;
  final bool isLoadingFields;
  final bool allowsCancellation;
  final int? cancellationWindowDays;

  const UnitFormReady({
    this.isEditMode = false,
    this.unitId,
    this.selectedPropertyId,
    this.tempKey,
    this.availableUnitTypes = const [],
    this.selectedUnitType,
    this.unitTypeFields = const [],
    this.unitName,
    this.description,
    this.basePrice,
    this.pricingMethod,
    this.customFeatures,
    this.dynamicFieldValues = const {},
    this.images,
    this.adultCapacity,
    this.childrenCapacity,
    this.isLoadingUnitTypes = false,
    this.isLoadingFields = false,
    this.allowsCancellation = true,
    this.cancellationWindowDays,
  });

  UnitFormReady copyWith({
    bool? isEditMode,
    String? unitId,
    String? selectedPropertyId,
    String? tempKey,
    List<UnitType>? availableUnitTypes,
    UnitType? selectedUnitType,
    List<UnitTypeField>? unitTypeFields,
    String? unitName,
    String? description,
    Money? basePrice,
    PricingMethod? pricingMethod,
    String? customFeatures,
    Map<String, dynamic>? dynamicFieldValues,
    List<String>? images,
    int? adultCapacity,
    int? childrenCapacity,
    bool? isLoadingUnitTypes,
    bool? isLoadingFields,
    bool? allowsCancellation,
    int? cancellationWindowDays,
  }) {
    return UnitFormReady(
      isEditMode: isEditMode ?? this.isEditMode,
      unitId: unitId ?? this.unitId,
      selectedPropertyId: selectedPropertyId ?? this.selectedPropertyId,
      tempKey: tempKey ?? this.tempKey,
      availableUnitTypes: availableUnitTypes ?? this.availableUnitTypes,
      selectedUnitType: selectedUnitType ?? this.selectedUnitType,
      unitTypeFields: unitTypeFields ?? this.unitTypeFields,
      unitName: unitName ?? this.unitName,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      pricingMethod: pricingMethod ?? this.pricingMethod,
      customFeatures: customFeatures ?? this.customFeatures,
      dynamicFieldValues: dynamicFieldValues ?? this.dynamicFieldValues,
      images: images ?? this.images,
      adultCapacity: adultCapacity ?? this.adultCapacity,
      childrenCapacity: childrenCapacity ?? this.childrenCapacity,
      isLoadingUnitTypes: isLoadingUnitTypes ?? this.isLoadingUnitTypes,
      isLoadingFields: isLoadingFields ?? this.isLoadingFields,
      allowsCancellation: allowsCancellation ?? this.allowsCancellation,
      cancellationWindowDays: cancellationWindowDays ?? this.cancellationWindowDays,
    );
  }

  @override
  List<Object?> get props => [
        isEditMode,
        unitId,
        selectedPropertyId,
        tempKey,
        availableUnitTypes,
        selectedUnitType,
        unitTypeFields,
        unitName,
        description,
        basePrice,
        pricingMethod,
        customFeatures,
        dynamicFieldValues,
        images,
        adultCapacity,
        childrenCapacity,
        isLoadingUnitTypes,
        isLoadingFields,
        allowsCancellation,
        cancellationWindowDays,
      ];
}

class UnitFormSubmitted extends UnitFormState {
  final String? unitId;

  const UnitFormSubmitted({this.unitId});

  @override
  List<Object?> get props => [unitId];
}

class UnitFormError extends UnitFormState {
  final String message;

  const UnitFormError({required this.message});

  @override
  List<Object> get props => [message];
}