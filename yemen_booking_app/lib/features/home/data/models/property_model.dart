// lib/features/home/data/models/property_model.dart

import 'package:equatable/equatable.dart';

class PropertyModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final int starRating;
  final String description;
  final bool isApproved;
  final DateTime createdAt;
  final int viewCount;
  final int bookingCount;
  final double averageRating;
  final List<String> images;
  final double? basePrice;
  final String? currency;
  final List<String> amenities;
  final String? mainImageUrl;
  final bool isFeatured;
  final bool isSponsored;
  final double? discountPercentage;
  final String? propertyType;

  const PropertyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.starRating,
    required this.description,
    required this.isApproved,
    required this.createdAt,
    required this.viewCount,
    required this.bookingCount,
    required this.averageRating,
    required this.images,
    this.basePrice,
    this.currency,
    required this.amenities,
    this.mainImageUrl,
    this.isFeatured = false,
    this.isSponsored = false,
    this.discountPercentage,
    this.propertyType,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      starRating: json['starRating'] as int,
      description: json['description'] as String,
      isApproved: json['isApproved'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      viewCount: json['viewCount'] as int,
      bookingCount: json['bookingCount'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      basePrice: json['basePrice'] != null
          ? (json['basePrice'] as num).toDouble()
          : null,
      currency: json['currency'] as String?,
      amenities: (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [],
      mainImageUrl: json['mainImageUrl'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isSponsored: json['isSponsored'] as bool? ?? false,
      discountPercentage: json['discountPercentage'] != null
          ? (json['discountPercentage'] as num).toDouble()
          : null,
      propertyType: json['propertyType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'starRating': starRating,
      'description': description,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
      'viewCount': viewCount,
      'bookingCount': bookingCount,
      'averageRating': averageRating,
      'images': images,
      'basePrice': basePrice,
      'currency': currency,
      'amenities': amenities,
      'mainImageUrl': mainImageUrl,
      'isFeatured': isFeatured,
      'isSponsored': isSponsored,
      'discountPercentage': discountPercentage,
      'propertyType': propertyType,
    };
  }

  PropertyModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    int? starRating,
    String? description,
    bool? isApproved,
    DateTime? createdAt,
    int? viewCount,
    int? bookingCount,
    double? averageRating,
    List<String>? images,
    double? basePrice,
    String? currency,
    List<String>? amenities,
    String? mainImageUrl,
    bool? isFeatured,
    bool? isSponsored,
    double? discountPercentage,
    String? propertyType,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      starRating: starRating ?? this.starRating,
      description: description ?? this.description,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
      bookingCount: bookingCount ?? this.bookingCount,
      averageRating: averageRating ?? this.averageRating,
      images: images ?? this.images,
      basePrice: basePrice ?? this.basePrice,
      currency: currency ?? this.currency,
      amenities: amenities ?? this.amenities,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      isSponsored: isSponsored ?? this.isSponsored,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      propertyType: propertyType ?? this.propertyType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        city,
        latitude,
        longitude,
        starRating,
        description,
        isApproved,
        createdAt,
        viewCount,
        bookingCount,
        averageRating,
        images,
        basePrice,
        currency,
        amenities,
        mainImageUrl,
        isFeatured,
        isSponsored,
        discountPercentage,
        propertyType,
      ];
}
