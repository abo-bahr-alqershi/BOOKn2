import 'package:equatable/equatable.dart';

class SearchFilter extends Equatable {
  final String filterId;
  final String fieldId;
  final String filterType;
  final String displayName;
  final Map<String, dynamic> filterOptions;
  final bool isActive;
  final int sortOrder;
  final UnitTypeField? field;

  const SearchFilter({
    required this.filterId,
    required this.fieldId,
    required this.filterType,
    required this.displayName,
    required this.filterOptions,
    required this.isActive,
    required this.sortOrder,
    this.field,
  });

  @override
  List<Object?> get props => [
        filterId,
        fieldId,
        filterType,
        displayName,
        filterOptions,
        isActive,
        sortOrder,
        field,
      ];
}

class UnitTypeField extends Equatable {
  final String fieldId;
  final String unitTypeId;
  final String fieldTypeId;
  final String fieldName;
  final String displayName;
  final String? description;
  final Map<String, dynamic> fieldOptions;
  final Map<String, dynamic> validationRules;
  final bool isRequired;
  final bool isSearchable;
  final bool isPublic;
  final int sortOrder;
  final String? category;
  final String? groupId;
  final bool isForUnits;
  final bool showInCards;
  final bool isPrimaryFilter;
  final int priority;

  const UnitTypeField({
    required this.fieldId,
    required this.unitTypeId,
    required this.fieldTypeId,
    required this.fieldName,
    required this.displayName,
    this.description,
    required this.fieldOptions,
    required this.validationRules,
    required this.isRequired,
    required this.isSearchable,
    required this.isPublic,
    required this.sortOrder,
    this.category,
    this.groupId,
    required this.isForUnits,
    required this.showInCards,
    required this.isPrimaryFilter,
    required this.priority,
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
        groupId,
        isForUnits,
        showInCards,
        isPrimaryFilter,
        priority,
      ];
}