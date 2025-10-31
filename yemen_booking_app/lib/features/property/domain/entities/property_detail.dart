import 'package:equatable/equatable.dart';
import 'property_policy.dart';
import 'amenity.dart';
import 'unit.dart';

class PropertyDetail extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String typeId;
  final String typeName;
  final String ownerName;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final int starRating;
  final String description;
  final double averageRating;
  final int reviewsCount;
  final int viewCount;
  final int bookingCount;
  final bool isFavorite;
  final bool isApproved;
  final DateTime createdAt;
  final List<PropertyImage> images;
  final List<Amenity> amenities;
  final List<PropertyService> services;
  final List<PropertyPolicy> policies;
  final List<Unit> units;

  const PropertyDetail({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.typeId,
    required this.typeName,
    required this.ownerName,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.starRating,
    required this.description,
    required this.averageRating,
    required this.reviewsCount,
    required this.viewCount,
    required this.bookingCount,
    required this.isFavorite,
    required this.isApproved,
    required this.createdAt,
    required this.images,
    required this.amenities,
    required this.services,
    required this.policies,
    required this.units,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        ownerId,
        typeId,
        typeName,
        ownerName,
        address,
        city,
        latitude,
        longitude,
        starRating,
        description,
        averageRating,
        reviewsCount,
        viewCount,
        bookingCount,
        isFavorite,
        isApproved,
        createdAt,
        images,
        amenities,
        services,
        policies,
        units,
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

class PropertyService extends Equatable {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String pricingModel;
  final String icon;

  const PropertyService({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.pricingModel,
    required this.icon,
  });

  @override
  List<Object?> get props => [id, name, price, currency, pricingModel, icon];
}

class PropertyType extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int count;

  const PropertyType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.count,
  });

  @override
  List<Object?> get props => [id, name, description, icon, count];
}
