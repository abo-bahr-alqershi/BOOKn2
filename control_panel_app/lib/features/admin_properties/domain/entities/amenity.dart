// lib/features/admin_properties/domain/entities/amenity.dart

import 'package:equatable/equatable.dart';

class Amenity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isAvailable;
  final double? extraCost;
  final String? currency;
  
  const Amenity({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isAvailable = true,
    this.extraCost,
    this.currency,
  });
  
  bool get isFree => extraCost == null || extraCost == 0;
  
  @override
  List<Object?> get props => [
    id, name, description, icon,
    isAvailable, extraCost, currency,
  ];
}