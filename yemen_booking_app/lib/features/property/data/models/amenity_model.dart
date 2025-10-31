import '../../domain/entities/amenity.dart';

class AmenityModel extends Amenity {
  const AmenityModel({
    required super.id,
    required super.name,
    required super.description,
    required super.iconUrl,
    required super.category,
    required super.icon,
    required super.isActive,
    required super.displayOrder,
    required super.createdAt,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      // prefer property-specific amenityId, fallback to global id
      id: json['amenityId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      category: json['category'] ?? '',
      icon: json['icon'] ?? '',
      // property JSON uses isAvailable, global DTO uses isActive
      isActive: json['isAvailable'] ?? json['isActive'] ?? true,
      displayOrder: json['displayOrder'] ?? 0,
      // createdAt may be missing in property payload
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'category': category,
      'icon': icon,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AmenityModel.fromEntity(Amenity amenity) {
    return AmenityModel(
      id: amenity.id,
      name: amenity.name,
      description: amenity.description,
      iconUrl: amenity.iconUrl,
      category: amenity.category,
      icon: amenity.icon,
      isActive: amenity.isActive,
      displayOrder: amenity.displayOrder,
      createdAt: amenity.createdAt,
    );
  }
}