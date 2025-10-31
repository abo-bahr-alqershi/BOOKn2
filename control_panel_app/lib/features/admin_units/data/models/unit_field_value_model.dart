import '../../domain/entities/unit_field_value.dart';

class UnitFieldValueModel extends UnitFieldValue {
  const UnitFieldValueModel({
    required super.fieldId,
    required super.fieldValue,
    super.fieldName,
    super.displayName,
    super.fieldTypeId,
    super.isPrimaryFilter,
  });

  factory UnitFieldValueModel.fromJson(Map<String, dynamic> json) {
    final fieldObj = json['field'] as Map<String, dynamic>?;

    bool? _coerceBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
        if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
      }
      return null;
    }

    String _coerceString(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    final rawIsPrimary = json.containsKey('isPrimaryFilter')
        ? json['isPrimaryFilter']
        : fieldObj?['isPrimaryFilter'];

    return UnitFieldValueModel(
      fieldId: json['fieldId'] as String,
      fieldValue: _coerceString(
        json.containsKey('fieldValue')
            ? json['fieldValue']
            : (json.containsKey('value') ? json['value'] : ''),
      ),
      fieldName:
          (json['fieldName'] as String?) ?? fieldObj?['fieldName'] as String?,
      displayName: (json['displayName'] as String?) ??
          fieldObj?['displayName'] as String?,
      fieldTypeId: (json['fieldTypeId'] as String?) ??
          (json['fieldType'] as String?) ??
          fieldObj?['fieldTypeId'] as String? ??
          fieldObj?['fieldType'] as String?,
      isPrimaryFilter: _coerceBool(rawIsPrimary),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'fieldValue': fieldValue,
      if (fieldName != null) 'fieldName': fieldName,
      if (displayName != null) 'displayName': displayName,
      if (fieldTypeId != null) 'fieldTypeId': fieldTypeId,
      if (isPrimaryFilter != null) 'isPrimaryFilter': isPrimaryFilter,
    };
  }

  factory UnitFieldValueModel.fromEntity(UnitFieldValue entity) {
    return UnitFieldValueModel(
      fieldId: entity.fieldId,
      fieldValue: entity.fieldValue,
      fieldName: entity.fieldName,
      displayName: entity.displayName,
      fieldTypeId: entity.fieldTypeId,
      isPrimaryFilter: entity.isPrimaryFilter,
    );
  }
}

class FieldGroupWithValuesModel extends FieldGroupWithValues {
  const FieldGroupWithValuesModel({
    required super.groupId,
    required super.groupName,
    required super.displayName,
    required super.description,
    required super.fieldValues,
  });

  factory FieldGroupWithValuesModel.fromJson(Map<String, dynamic> json) {
    return FieldGroupWithValuesModel(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      fieldValues: (json['fieldValues'] as List)
          .map((e) => UnitFieldValueModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'displayName': displayName,
      'description': description,
      'fieldValues': fieldValues
          .map((e) => UnitFieldValueModel.fromEntity(e).toJson())
          .toList(),
    };
  }

  factory FieldGroupWithValuesModel.fromEntity(FieldGroupWithValues entity) {
    return FieldGroupWithValuesModel(
      groupId: entity.groupId,
      groupName: entity.groupName,
      displayName: entity.displayName,
      description: entity.description,
      fieldValues: entity.fieldValues,
    );
  }
}
