import 'package:equatable/equatable.dart';
import 'unit_type_field.dart';

/// 🏠 كيان نوع الوحدة
class UnitType extends Equatable {
  final String id;
  final String propertyTypeId;
  final String name;
  final String description;
  final String icon;
  final int maxCapacity;
  final double? systemCommissionRate;
  final bool isHasAdults;
  final bool isHasChildren;
  final bool isMultiDays;
  final bool isRequiredToDetermineTheHour;
  final List<UnitTypeField> fields;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UnitType({
    required this.id,
    required this.propertyTypeId,
    required this.name,
    required this.description,
    required this.icon,
    this.systemCommissionRate,
    required this.maxCapacity,
    required this.isHasAdults,
    required this.isHasChildren,
    required this.isMultiDays,
    required this.isRequiredToDetermineTheHour,
    this.fields = const [],
    this.createdAt,
    this.updatedAt,
  });

  UnitType copyWith({
    String? id,
    String? propertyTypeId,
    String? name,
    String? description,
    String? icon,
    double? systemCommissionRate,
    int? maxCapacity,
    bool? isHasAdults,
    bool? isHasChildren,
    bool? isMultiDays,
    bool? isRequiredToDetermineTheHour,
    List<UnitTypeField>? fields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnitType(
      id: id ?? this.id,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      systemCommissionRate: systemCommissionRate ?? this.systemCommissionRate,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      isHasAdults: isHasAdults ?? this.isHasAdults,
      isHasChildren: isHasChildren ?? this.isHasChildren,
      isMultiDays: isMultiDays ?? this.isMultiDays,
      isRequiredToDetermineTheHour: 
          isRequiredToDetermineTheHour ?? this.isRequiredToDetermineTheHour,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        propertyTypeId,
        name,
        description,
        icon,
        systemCommissionRate,
        maxCapacity,
        isHasAdults,
        isHasChildren,
        isMultiDays,
        isRequiredToDetermineTheHour,
        fields,
        createdAt,
        updatedAt,
      ];
}