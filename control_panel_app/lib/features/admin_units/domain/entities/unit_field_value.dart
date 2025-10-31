import 'package:equatable/equatable.dart';

class UnitFieldValue extends Equatable {
  final String fieldId;
  final String fieldValue;
  final String? fieldName;
  final String? displayName;
  final String? fieldTypeId;
  final bool? isPrimaryFilter; // new

  const UnitFieldValue({
    required this.fieldId,
    required this.fieldValue,
    this.fieldName,
    this.displayName,
    this.fieldTypeId,
    this.isPrimaryFilter, // new
  });

  @override
  List<Object?> get props => [
        fieldId,
        fieldValue,
        fieldName,
        displayName,
        fieldTypeId,
        isPrimaryFilter, // new
      ];
}

class FieldGroupWithValues extends Equatable {
  final String groupId;
  final String groupName;
  final String displayName;
  final String description;
  final List<UnitFieldValue> fieldValues;

  const FieldGroupWithValues({
    required this.groupId,
    required this.groupName,
    required this.displayName,
    required this.description,
    required this.fieldValues,
  });

  @override
  List<Object?> get props => [
        groupId,
        groupName,
        displayName,
        description,
        fieldValues,
      ];
}