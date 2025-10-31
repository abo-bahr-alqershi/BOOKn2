import '../../domain/entities/property_type.dart';

class PropertyTypeModel extends PropertyType {
  const PropertyTypeModel({
    required String id,
    required String name,
    required String description,
    required List<String> defaultAmenities,
    required String icon,
    int propertiesCount = 0,
    List<String> unitTypeIds = const [],
    bool isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          name: name,
          description: description,
          defaultAmenities: defaultAmenities,
          icon: icon,
          propertiesCount: propertiesCount,
          unitTypeIds: unitTypeIds,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory PropertyTypeModel.fromJson(Map<String, dynamic> json) {
    return PropertyTypeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      defaultAmenities: json['defaultAmenities'] is List
          ? List<String>.from(json['defaultAmenities'])
          : [],
      icon: json['icon'] ?? 'home',
      propertiesCount: json['propertiesCount'] ?? 0,
      unitTypeIds: json['unitTypeIds'] is List
          ? List<String>.from(json['unitTypeIds'])
          : [],
      isActive: json['isActive'] ?? true,
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
      'name': name,
      'description': description,
      'defaultAmenities': defaultAmenities,
      'icon': icon,
      'propertiesCount': propertiesCount,
      'unitTypeIds': unitTypeIds,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}