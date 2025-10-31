import '../../domain/entities/unit_type_field.dart';

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
    String? groupId,
    required bool isForUnits,
    required bool showInCards,
    required bool isPrimaryFilter,
    required int priority,
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
          groupId: groupId,
          isForUnits: isForUnits,
          showInCards: showInCards,
          isPrimaryFilter: isPrimaryFilter,
          priority: priority,
        );

  factory UnitTypeFieldModel.fromJson(Map<String, dynamic> json) {
    return UnitTypeFieldModel(
      fieldId: json['fieldId'] ?? '',
      unitTypeId: json['unitTypeId'] ?? '',
      fieldTypeId: json['fieldTypeId'] ?? '',
      fieldName: json['fieldName'] ?? '',
      displayName: json['displayName'] ?? '',
      description: json['description'] ?? '',
      fieldOptions: json['fieldOptions'] ?? {},
      validationRules: json['validationRules'] ?? {},
      isRequired: json['isRequired'] ?? false,
      isSearchable: json['isSearchable'] ?? false,
      isPublic: json['isPublic'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
      category: json['category'] ?? '',
      groupId: json['groupId'],
      isForUnits: json['isForUnits'] ?? true,
      showInCards: json['showInCards'] ?? false,
      isPrimaryFilter: json['isPrimaryFilter'] ?? false,
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'unitTypeId': unitTypeId,
      'fieldTypeId': fieldTypeId,
      'fieldName': fieldName,
      'displayName': displayName,
      'description': description,
      'fieldOptions': fieldOptions,
      'validationRules': validationRules,
      'isRequired': isRequired,
      'isSearchable': isSearchable,
      'isPublic': isPublic,
      'sortOrder': sortOrder,
      'category': category,
      'groupId': groupId,
      'isForUnits': isForUnits,
      'showInCards': showInCards,
      'isPrimaryFilter': isPrimaryFilter,
      'priority': priority,
    };
  }
}