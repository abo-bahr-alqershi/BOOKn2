// lib/features/admin_properties/domain/entities/property.dart

import 'package:equatable/equatable.dart';
import 'property_image.dart';
import 'amenity.dart';
import 'policy.dart';

class Property extends Equatable {
  final String id;
  final String ownerId;
  final String typeId;
  final String name;
  final String? shortDescription;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final int starRating;
  final String description;
  final bool isApproved;
  final DateTime createdAt;
  final int viewCount;
  final int bookingCount;
  final double averageRating;
  final String currency;
  final bool isFeatured;
  final String ownerName;
  final String typeName;
  final double? distanceKm;
  final List<PropertyImage> images;
  final List<Amenity> amenities;
  final List<Policy> policies;
  final PropertyStats? stats;
  
  const Property({
    required this.id,
    required this.ownerId,
    required this.typeId,
    required this.name,
    this.shortDescription,
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
    required this.starRating,
    required this.description,
    required this.isApproved,
    required this.createdAt,
    this.viewCount = 0,
    this.bookingCount = 0,
    this.averageRating = 0.0,
    this.currency = 'YER',
    this.isFeatured = false,
    required this.ownerName,
    required this.typeName,
    this.distanceKm,
    this.images = const [],
    this.amenities = const [],
    this.policies = const [],
    this.stats,
  });
  
  // Helper methods
  bool get hasLocation => latitude != null && longitude != null;
  bool get isPending => !isApproved;
  String get formattedAddress => '$address, $city';
  
  @override
  List<Object?> get props => [
    id, ownerId, typeId, name, shortDescription, address, city, latitude, longitude, starRating, description,
    isApproved, createdAt, viewCount, bookingCount, averageRating,
    currency, isFeatured, ownerName, typeName, distanceKm, 
    images, amenities, policies, stats,
  ];
}

class PropertyStats extends Equatable {
  final int totalBookings;
  final int activeBookings;
  final double averageRating;
  final int reviewCount;
  final double occupancyRate;
  final double monthlyRevenue;
  
  const PropertyStats({
    required this.totalBookings,
    required this.activeBookings,
    required this.averageRating,
    required this.reviewCount,
    required this.occupancyRate,
    required this.monthlyRevenue,
  });
  
  @override
  List<Object> get props => [
    totalBookings, activeBookings, averageRating,
    reviewCount, occupancyRate, monthlyRevenue,
  ];
}