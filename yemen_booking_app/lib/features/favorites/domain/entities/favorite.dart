import 'package:equatable/equatable.dart';

class Favorite extends Equatable {
  final String id;
  final String userId;
  final String propertyId;
  final String propertyName;
  final String propertyImage;
  final String propertyLocation;
  final String typeId;
  final String typeName;
  final String ownerName;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final int starRating;
  final double averageRating;
  final int reviewsCount;
  final double minPrice;
  final String currency;
  final List<PropertyImage> images;
  final List<Amenity> amenities;
  final DateTime createdAt;

  const Favorite({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.propertyName,
    required this.propertyImage,
    required this.propertyLocation,
    required this.typeId,
    required this.typeName,
    required this.ownerName,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.starRating,
    required this.averageRating,
    required this.reviewsCount,
    this.minPrice = 0,
    this.currency = 'YER',
    required this.images,
    required this.amenities,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        propertyId,
        propertyName,
        propertyImage,
        propertyLocation,
        typeId,
        typeName,
        ownerName,
        address,
        city,
        latitude,
        longitude,
        starRating,
        averageRating,
        reviewsCount,
        minPrice,
        currency,
        images,
        amenities,
        createdAt,
      ];
}

class PropertyImage extends Equatable {
  final String id;
  final String? propertyId;
  final String? unitId;
  final String name;
  final String url;
  final int sizeBytes;
  final String type;
  final String category;
  final String caption;
  final String altText;
  final String tags;
  final String sizes;
  final bool isMain;
  final int displayOrder;
  final DateTime uploadedAt;
  final String status;
  final String associationType;

  const PropertyImage({
    required this.id,
    this.propertyId,
    this.unitId,
    required this.name,
    required this.url,
    required this.sizeBytes,
    required this.type,
    required this.category,
    required this.caption,
    required this.altText,
    required this.tags,
    required this.sizes,
    required this.isMain,
    required this.displayOrder,
    required this.uploadedAt,
    required this.status,
    required this.associationType,
  });

  @override
  List<Object?> get props => [
        id,
        propertyId,
        unitId,
        name,
        url,
        sizeBytes,
        type,
        category,
        caption,
        altText,
        tags,
        sizes,
        isMain,
        displayOrder,
        uploadedAt,
        status,
        associationType,
      ];
}

class Amenity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String category;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;

  const Amenity({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconUrl,
        category,
        isActive,
        displayOrder,
        createdAt,
      ];
}