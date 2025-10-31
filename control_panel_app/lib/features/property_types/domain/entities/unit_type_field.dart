import 'package:equatable/equatable.dart';

/// 📝 كيان حقل نوع الوحدة الديناميكي
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
    required this.description,
    required this.fieldOptions,
    required this.validationRules,
    required this.isRequired,
    required this.isSearchable,
    required this.isPublic,
    required this.sortOrder,
    required this.category,
    this.groupId,
    required this.isForUnits,
    required this.showInCards,
    required this.isPrimaryFilter,
    required this.priority,
  });

  UnitTypeField copyWith({
    String? fieldId,
    String? unitTypeId,
    String? fieldTypeId,
    String? fieldName,
    String? displayName,
    String? description,
    Map<String, dynamic>? fieldOptions,
    Map<String, dynamic>? validationRules,
    bool? isRequired,
    bool? isSearchable,
    bool? isPublic,
    int? sortOrder,
    String? category,
    String? groupId,
    bool? isForUnits,
    bool? showInCards,
    bool? isPrimaryFilter,
    int? priority,
  }) {
    return UnitTypeField(
      fieldId: fieldId ?? this.fieldId,
      unitTypeId: unitTypeId ?? this.unitTypeId,
      fieldTypeId: fieldTypeId ?? this.fieldTypeId,
      fieldName: fieldName ?? this.fieldName,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      fieldOptions: fieldOptions ?? this.fieldOptions,
      validationRules: validationRules ?? this.validationRules,
      isRequired: isRequired ?? this.isRequired,
      isSearchable: isSearchable ?? this.isSearchable,
      isPublic: isPublic ?? this.isPublic,
      sortOrder: sortOrder ?? this.sortOrder,
      category: category ?? this.category,
      groupId: groupId ?? this.groupId,
      isForUnits: isForUnits ?? this.isForUnits,
      showInCards: showInCards ?? this.showInCards,
      isPrimaryFilter: isPrimaryFilter ?? this.isPrimaryFilter,
      priority: priority ?? this.priority,
    );
  }

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