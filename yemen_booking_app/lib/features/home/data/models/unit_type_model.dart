import 'package:yemen_booking_app/features/search/data/models/search_filter_model.dart';
import '../../domain/entities/unit_type.dart' as domain;

class UnitTypeModel {
  final String id;
  final String propertyTypeId;
  final String name;
  final String description;
  final int maxCapacity;
  final String icon;
  final bool isHasAdults;
  final bool isHasChildren;
  final bool isMultiDays;
  final bool isRequiredToDetermineTheHour;
  final List<UnitTypeFieldModel> fields;

  const UnitTypeModel({
    required this.id,
    required this.propertyTypeId,
    required this.name,
    required this.description,
    required this.maxCapacity,
    required this.icon,
    required this.isHasAdults,
    required this.isHasChildren,
    required this.isMultiDays,  
    required this.isRequiredToDetermineTheHour,
    this.fields = const [],
  });

  factory UnitTypeModel.fromJson(Map<String, dynamic> json) {
    return UnitTypeModel(
      id: json['id'] ?? '',
      propertyTypeId: json['propertyTypeId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      maxCapacity: json['maxCapacity'] ?? 0,
      icon: json['icon'] ?? "",
      isHasAdults: json['isHasAdults'] ?? false,
      isHasChildren: json['isHasChildren'] ?? false,
      isMultiDays: json['isMultiDays'] ?? false,
      isRequiredToDetermineTheHour: json['isRequiredToDetermineTheHour'] ?? false,
      fields: (json['fields'] as List?)
              ?.map((e) => UnitTypeFieldModel.fromJson(e))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyTypeId': propertyTypeId,
      'name': name,
      'description': description,
      'maxCapacity': maxCapacity,
      'icon': icon,
      'isHasAdults': isHasAdults,
      'isHasChildren': isHasChildren,
      'isMultiDays': isMultiDays,
      'isRequiredToDetermineTheHour': isRequiredToDetermineTheHour,
      'fields': fields.map((e) => e.toJson()).toList(),
    };
  }

  domain.UnitType toEntity() => domain.UnitType(
        id: id,
        propertyTypeId: propertyTypeId,
        name: name,
        description: description,
        maxCapacity: maxCapacity,
        icon: icon,
        isHasAdults: isHasAdults,
        isHasChildren: isHasChildren,
        isMultiDays: isMultiDays,
        isRequiredToDetermineTheHour: isRequiredToDetermineTheHour,
        fields: fields.map((e) => e).toList(),
      );
}