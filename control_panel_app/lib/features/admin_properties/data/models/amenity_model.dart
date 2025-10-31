// lib/features/admin_properties/data/models/amenity_model.dart

import '../../domain/entities/amenity.dart';

class AmenityModel extends Amenity {
  const AmenityModel({
    required String id,
    required String name,
    required String description,
    required String icon,
    bool isAvailable = true,
    double? extraCost,
    String? currency,
  }) : super(
    id: id,
    name: name,
    description: description,
    icon: icon,
    isAvailable: isAvailable,
    extraCost: extraCost,
    currency: currency,
  );
  
  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    double? cost;
    String? curr;
    
    if (json['extraCost'] != null) {
      if (json['extraCost'] is Map) {
        cost = (json['extraCost']['amount'] as num?)?.toDouble();
        curr = json['extraCost']['currency'] as String?;
      } else {
        cost = (json['extraCost'] as num?)?.toDouble();
      }
    }
    
    return AmenityModel(
      id: (json['id'] ?? json['amenityId'] ?? '').toString(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: (json['icon'] ?? json['iconUrl'] ?? '') as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
      extraCost: cost,
      currency: curr ?? 'YER',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'isAvailable': isAvailable,
      if (extraCost != null) 'extraCost': {
        'amount': extraCost,
        'currency': currency ?? 'YER',
      },
    };
  }
}