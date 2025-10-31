import '../../domain/entities/unit_type.dart';
import 'unit_type_field_model.dart';

class UnitTypeModel extends UnitType {
  const UnitTypeModel({
    required String id,
    required String propertyTypeId,
    required String name,
    required String description,
    required String icon,
    double? systemCommissionRate,
    required int maxCapacity,
    required bool isHasAdults,
    required bool isHasChildren,
    required bool isMultiDays,
    required bool isRequiredToDetermineTheHour,
    List<UnitTypeFieldModel> fields = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          propertyTypeId: propertyTypeId,
          name: name,
          description: description,
          icon: icon,
          systemCommissionRate: systemCommissionRate,
          maxCapacity: maxCapacity,
          isHasAdults: isHasAdults,
          isHasChildren: isHasChildren,
          isMultiDays: isMultiDays,
          isRequiredToDetermineTheHour: isRequiredToDetermineTheHour,
          fields: fields,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory UnitTypeModel.fromJson(Map<String, dynamic> json) {
    return UnitTypeModel(
      id: json['id'] ?? '',
      propertyTypeId: json['propertyTypeId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'apartment',
      systemCommissionRate: json['systemCommissionRate'] == null
          ? null
          : (json['systemCommissionRate'] as num).toDouble(),
      maxCapacity: json['maxCapacity'] ?? 1,
      isHasAdults: json['isHasAdults'] ?? false,
      isHasChildren: json['isHasChildren'] ?? false,
      isMultiDays: json['isMultiDays'] ?? false,
      isRequiredToDetermineTheHour: json['isRequiredToDetermineTheHour'] ?? false,
      fields: json['fields'] != null
          ? (json['fields'] as List)
              .map((field) => UnitTypeFieldModel.fromJson(field))
              .toList()
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyTypeId': propertyTypeId,
      'name': name,
      'description': description,
      'icon': icon,
      'systemCommissionRate': systemCommissionRate,
      'maxCapacity': maxCapacity,
      'isHasAdults': isHasAdults,
      'isHasChildren': isHasChildren,
      'isMultiDays': isMultiDays,
      'isRequiredToDetermineTheHour': isRequiredToDetermineTheHour,
      'fields': fields.map((f) => (f as UnitTypeFieldModel).toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}