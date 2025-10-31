// lib/features/admin_properties/domain/entities/property_type.dart

import 'package:equatable/equatable.dart';

class PropertyType extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> defaultAmenities;
  final String icon;
  final int propertiesCount;
  final bool isActive;
  
  const PropertyType({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultAmenities,
    required this.icon,
    this.propertiesCount = 0,
    this.isActive = true,
  });
  
  @override
  List<Object> get props => [
    id, name, description, defaultAmenities,
    icon, propertiesCount, isActive,
  ];
}