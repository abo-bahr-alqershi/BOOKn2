import '../../domain/entities/amenity.dart';

class AmenityModel extends Amenity {
  const AmenityModel({
    required String id,
    required String name,
    required String description,
    required String icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? propertiesCount,
    double? averageExtraCost,
  }) : super(
          id: id,
          name: name,
          description: description,
          icon: icon,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isActive: isActive,
          propertiesCount: propertiesCount,
          averageExtraCost: averageExtraCost,
        );

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      id: (json['id'] ?? json['amenityId'] ?? '').toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: (json['icon'] ?? json['iconUrl'] ?? 'star') as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isActive: json['isActive'] ?? json['active'] ?? true,
      propertiesCount: json['propertiesCount'] ?? 0,
      averageExtraCost: (json['averageExtraCost'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'isActive': isActive,
      'propertiesCount': propertiesCount,
      'averageExtraCost': averageExtraCost,
    };
  }

  factory AmenityModel.fromEntity(Amenity entity) {
    return AmenityModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      icon: entity.icon,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
      propertiesCount: entity.propertiesCount,
      averageExtraCost: entity.averageExtraCost,
    );
  }
}

/// 📊 Model لإحصائيات المرافق
class AmenityStatsModel {
  final int totalAmenities;
  final int activeAmenities;
  final int totalAssignments;
  final double totalRevenue;
  final Map<String, int> popularAmenities;
  final Map<String, double> revenueByAmenity;

  AmenityStatsModel({
    required this.totalAmenities,
    required this.activeAmenities,
    required this.totalAssignments,
    required this.totalRevenue,
    required this.popularAmenities,
    required this.revenueByAmenity,
  });

  factory AmenityStatsModel.fromJson(Map<String, dynamic> json) {
    return AmenityStatsModel(
      totalAmenities: json['totalAmenities'] ?? 0,
      activeAmenities: json['activeAmenities'] ?? 0,
      totalAssignments: json['totalAssignments'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      popularAmenities: Map<String, int>.from(json['popularAmenities'] ?? {}),
      revenueByAmenity:
          Map<String, double>.from(json['revenueByAmenity'] ?? {}),
    );
  }
}