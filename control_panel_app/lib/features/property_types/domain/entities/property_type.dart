import 'package:equatable/equatable.dart';

/// 🏢 كيان نوع الملكية
class PropertyType extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> defaultAmenities;
  final String icon;
  final int propertiesCount;
  final List<String> unitTypeIds;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PropertyType({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultAmenities,
    required this.icon,
    this.propertiesCount = 0,
    this.unitTypeIds = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  PropertyType copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? defaultAmenities,
    String? icon,
    int? propertiesCount,
    List<String>? unitTypeIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultAmenities: defaultAmenities ?? this.defaultAmenities,
      icon: icon ?? this.icon,
      propertiesCount: propertiesCount ?? this.propertiesCount,
      unitTypeIds: unitTypeIds ?? this.unitTypeIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        defaultAmenities,
        icon,
        propertiesCount,
        unitTypeIds,
        isActive,
        createdAt,
        updatedAt,
      ];
}