import 'package:equatable/equatable.dart';

/// 🏢 Entity للمرافق
class Amenity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isActive;
  final int? propertiesCount;
  final double? averageExtraCost;

  const Amenity({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.propertiesCount = 0,
    this.averageExtraCost = 0,
  });

  Amenity copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? propertiesCount,
    double? averageExtraCost,
  }) {
    return Amenity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      propertiesCount: propertiesCount ?? this.propertiesCount,
      averageExtraCost: averageExtraCost ?? this.averageExtraCost,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        createdAt,
        updatedAt,
        isActive,
        propertiesCount,
        averageExtraCost,
      ];
}

/// 📊 Entity لإحصائيات المرافق
class AmenityStats {
  final int totalAmenities;
  final int activeAmenities;
  final int totalAssignments;
  final double totalRevenue;
  final Map<String, int> popularAmenities;
  final Map<String, double> revenueByAmenity;

  const AmenityStats({
    required this.totalAmenities,
    required this.activeAmenities,
    required this.totalAssignments,
    required this.totalRevenue,
    required this.popularAmenities,
    required this.revenueByAmenity,
  });
}