import '../../domain/entities/unit_type.dart';

class UnitTypeModel extends UnitType {
  const UnitTypeModel({
    required String id,
    required String propertyTypeId,
    required String name,
    required String description,
    required String icon,
    required bool isHasAdults,
    required bool isHasChildren,
    required bool isMultiDays,
    required bool isRequiredToDetermineTheHour,
    required int maxCapacity,
    List<UnitTypeField> fields = const [],
  }) : super(
          id: id,
          propertyTypeId: propertyTypeId,
          name: name,
          description: description,
          icon: icon,
          isHasAdults: isHasAdults,
          isHasChildren: isHasChildren,
          isMultiDays: isMultiDays,
          isRequiredToDetermineTheHour: isRequiredToDetermineTheHour,
          maxCapacity: maxCapacity,
          fields: fields,
        );

  factory UnitTypeModel.fromJson(Map<String, dynamic> json) {
    return UnitTypeModel(
      id: json['id'] as String,
      propertyTypeId: json['propertyTypeId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'apartment',
      isHasAdults: json['isHasAdults'] as bool? ?? false,
      isHasChildren: json['isHasChildren'] as bool? ?? false,
      isMultiDays: json['isMultiDays'] as bool? ?? false,
      isRequiredToDetermineTheHour: json['isRequiredToDetermineTheHour'] as bool? ?? false,
      maxCapacity: json['maxCapacity'] as int? ?? 1,
      fields: (json['fields'] as List?)
              ?.map((e) => UnitTypeFieldModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class UnitTypeFieldModel extends UnitTypeField {
  const UnitTypeFieldModel({
    required String fieldId,
    required String unitTypeId,
    required String fieldTypeId,
    required String fieldName,
    required String displayName,
    required String description,
    required Map<String, dynamic> fieldOptions,
    required Map<String, dynamic> validationRules,
    required bool isRequired,
    required bool isSearchable,
    required bool isPublic,
    required int sortOrder,
    required String category,
    required bool isForUnits,
    required bool showInCards,
    required bool isPrimaryFilter,
    required int priority,
    String? groupId,
  }) : super(
          fieldId: fieldId,
          unitTypeId: unitTypeId,
          fieldTypeId: fieldTypeId,
          fieldName: fieldName,
          displayName: displayName,
          description: description,
          fieldOptions: fieldOptions,
          validationRules: validationRules,
          isRequired: isRequired,
          isSearchable: isSearchable,
          isPublic: isPublic,
          sortOrder: sortOrder,
          category: category,
          isForUnits: isForUnits,
          showInCards: showInCards,
          isPrimaryFilter: isPrimaryFilter,
          priority: priority,
          groupId: groupId,
        );

  factory UnitTypeFieldModel.fromJson(Map<String, dynamic> json) {
    return UnitTypeFieldModel(
      fieldId: json['fieldId'] as String,
      unitTypeId: json['unitTypeId'] as String,
      fieldTypeId: json['fieldTypeId'] as String,
      fieldName: json['fieldName'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String? ?? '',
      fieldOptions: json['fieldOptions'] as Map<String, dynamic>? ?? {},
      validationRules: json['validationRules'] as Map<String, dynamic>? ?? {},
      isRequired: json['isRequired'] as bool? ?? false,
      isSearchable: json['isSearchable'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      isForUnits: json['isForUnits'] as bool? ?? true,
      showInCards: json['showInCards'] as bool? ?? false,
      isPrimaryFilter: json['isPrimaryFilter'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      groupId: json['groupId'] as String?,
    );
  }
}