import 'package:equatable/equatable.dart';

class UnitType extends Equatable {
  final String id;
  final String propertyTypeId;
  final String name;
  final String description;
  final String icon;
  final double? systemCommissionRate;
  final bool isHasAdults;
  final bool isHasChildren;
  final bool isMultiDays;
  final bool isRequiredToDetermineTheHour;
  final int maxCapacity;
  final List<UnitTypeField> fields;

  const UnitType({
    required this.id,
    required this.propertyTypeId,
    required this.name,
    required this.description,
    required this.icon,
    this.systemCommissionRate,
    required this.isHasAdults,
    required this.isHasChildren,
    required this.isMultiDays,
    required this.isRequiredToDetermineTheHour,
    required this.maxCapacity,
    this.fields = const [],
  });

  @override
  List<Object?> get props => [
        id,
        propertyTypeId,
        name,
        description,
        icon,
        systemCommissionRate,
        isHasAdults,
        isHasChildren,
        isMultiDays,
        isRequiredToDetermineTheHour,
        maxCapacity,
        fields,
      ];
}

class UnitTypeField extends Equatable {
  final String fieldId;
  final String unitTypeId;
  final String fieldTypeId;
  final String fieldName;
  final String displayName;
  final String description;
  final Map<String, dynamic> fieldOptions;
  final Map<String, dynamic> validationRules;
  final bool isRequired;
  final bool isSearchable;
  final bool isPublic;
  final int sortOrder;
  final String category;
  final bool isForUnits;
  final bool showInCards;
  final bool isPrimaryFilter;
  final int priority;
  final String? groupId;

  const UnitTypeField({
    required this.fieldId,
    required this.unitTypeId,
    required this.fieldTypeId,
    required this.fieldName,
    required this.displayName,
    required this.description,
    required this.fieldOptions,
    required this.validationRules,
    required this.isRequired,
    required this.isSearchable,
    required this.isPublic,
    required this.sortOrder,
    required this.category,
    required this.isForUnits,
    required this.showInCards,
    required this.isPrimaryFilter,
    required this.priority,
    this.groupId,
  });

  @override
  List<Object?> get props => [
        fieldId,
        unitTypeId,
        fieldTypeId,
        fieldName,
        displayName,
        description,
        fieldOptions,
        validationRules,
        isRequired,
        isSearchable,
        isPublic,
        sortOrder,
        category,
        isForUnits,
        showInCards,
        isPrimaryFilter,
        priority,
        groupId,
      ];
}