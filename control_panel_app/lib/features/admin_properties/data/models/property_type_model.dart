// lib/features/admin_properties/data/models/property_type_model.dart

import '../../domain/entities/property_type.dart';

class PropertyTypeModel extends PropertyType {
  const PropertyTypeModel({
    required String id,
    required String name,
    required String description,
    required List<String> defaultAmenities, // تغيير من String إلى List<String>
    required String icon,
    int propertiesCount = 0,
    bool isActive = true,
  }) : super(
    id: id,
    name: name,
    description: description,
    defaultAmenities: defaultAmenities,
    icon: icon,
    propertiesCount: propertiesCount,
    isActive: isActive,
  );
  
  factory PropertyTypeModel.fromJson(Map<String, dynamic> json) {
    // معالجة defaultAmenities بشكل صحيح
    List<String> parseDefaultAmenities(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        // إذا كانت string، نحاول تحويلها لقائمة
        if (value.isEmpty) return [];
        // إذا كانت مفصولة بفاصلة
        return value.split(',').map((e) => e.trim()).toList();
      }
      return [];
    }
    
    return PropertyTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      defaultAmenities: parseDefaultAmenities(json['defaultAmenities']),
      icon: json['icon']?.toString() ?? '',
      propertiesCount: json['propertiesCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
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
      'isActive': isActive,
    };
  }
}