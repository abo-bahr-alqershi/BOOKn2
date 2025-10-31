import 'package:yemen_booking_app/features/property/domain/entities/property_policy.dart';

import '../../domain/entities/property_detail.dart';
import 'amenity_model.dart';
import 'unit_model.dart';

class PropertyDetailModel extends PropertyDetail {
  const PropertyDetailModel({
    required super.id,
    required super.name,
    required super.ownerId,
    required super.typeId,
    required super.typeName,
    required super.ownerName,
    required super.address,
    required super.city,
    required super.latitude,
    required super.longitude,
    required super.starRating,
    required super.description,
    required super.averageRating,
    required super.reviewsCount,
    required super.viewCount,
    required super.bookingCount,
    required super.isFavorite,
    required super.isApproved,
    required super.createdAt,
    required super.images,
    required super.amenities,
    required super.services,
    required super.policies,
    required super.units,
  });

  factory PropertyDetailModel.fromJson(Map<String, dynamic> json) {
    return PropertyDetailModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      ownerId: json['ownerId'] ?? '',
      // propertyType is nested object: fallback to its id and name
      typeId: json['typeId'] ?? json['propertyType']?['id']?.toString() ?? '',
      typeName: json['typeName'] ?? json['propertyType']?['name'] ?? '',
      ownerName: json['ownerName'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      starRating: json['starRating'] ?? 0,
      description: json['description'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      bookingCount: json['bookingCount'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      isApproved: json['isApproved'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      images: (json['images'] as List?)
              ?.map((e) => PropertyImageModel.fromJson(e))
              .toList() ??
          [],
      amenities: (json['amenities'] as List?)
              ?.map((e) => AmenityModel.fromJson(e))
              .toList() ??
          [],
      services: (json['services'] as List?)
              ?.map((e) => PropertyServiceModel.fromJson(e))
              .toList() ??
          [],
      policies: (json['policies'] as List?)
              ?.map((e) => PropertyPolicyModel.fromJson(e))
              .toList() ??
          [],
      units: (json['units'] as List?)
              ?.map((e) => UnitModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'typeId': typeId,
      'typeName': typeName,
      'ownerName': ownerName,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'starRating': starRating,
      'description': description,
      'averageRating': averageRating,
      'reviewsCount': reviewsCount,
      'viewCount': viewCount,
      'bookingCount': bookingCount,
      'isFavorite': isFavorite,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
      'images': images.map((e) => (e as PropertyImageModel).toJson()).toList(),
      'amenities': amenities.map((e) => (e as AmenityModel).toJson()).toList(),
      'services': services.map((e) => (e as PropertyServiceModel).toJson()).toList(),
      'policies': policies.map((e) => (e as PropertyPolicyModel).toJson()).toList(),
      'units': units.map((e) => (e as UnitModel).toJson()).toList(),
    };
  }
}

class PropertyImageModel extends PropertyImage {
  const PropertyImageModel({
    required super.id,
    super.propertyId,
    super.unitId,
    required super.name,
    required super.url,
    required super.sizeBytes,
    required super.type,
    required super.category,
    required super.caption,
    required super.altText,
    required super.tags,
    required super.sizes,
    required super.isMain,
    required super.displayOrder,
    required super.uploadedAt,
    required super.status,
    required super.associationType,
  });

  factory PropertyImageModel.fromJson(Map<String, dynamic> json) {
    return PropertyImageModel(
      id: json['id'] ?? '',
      propertyId: json['propertyId'],
      unitId: json['unitId'],
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      sizeBytes: json['sizeBytes'] ?? 0,
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      caption: json['caption'] ?? '',
      altText: json['altText'] ?? '',
      tags: json['tags'] ?? '',
      sizes: json['sizes'] ?? '',
      isMain: json['isMain'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? '',
      associationType: json['associationType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'unitId': unitId,
      'name': name,
      'url': url,
      'sizeBytes': sizeBytes,
      'type': type,
      'category': category,
      'caption': caption,
      'altText': altText,
      'tags': tags,
      'sizes': sizes,
      'isMain': isMain,
      'displayOrder': displayOrder,
      'uploadedAt': uploadedAt.toIso8601String(),
      'status': status,
      'associationType': associationType,
    };
  }
}

class PropertyServiceModel extends PropertyService {
  const PropertyServiceModel({
    required super.id,
    required super.name,
    required super.price,
    required super.currency,
    required super.pricingModel,
    required super.icon,
  });

  factory PropertyServiceModel.fromJson(Map<String, dynamic> json) {
    return PropertyServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'YER',
      pricingModel: json['pricingModel'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'currency': currency,
      'pricingModel': pricingModel,
      'icon': icon,
    };
  }
}

class PropertyPolicyModel extends PropertyPolicy {
  const PropertyPolicyModel({
    required super.id,
    required super.policyType,
    required super.policyContent,
    required super.isActive,
    required super.type,
    required super.description,
    required super.rules,
  });

  factory PropertyPolicyModel.fromJson(Map<String, dynamic> json) {
    return PropertyPolicyModel(
      id: json['id'] ?? '',
      policyType: json['policyType'] ?? '',
      policyContent: json['policyContent'] ?? '',
      isActive: json['isActive'] ?? true,
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      rules: Map<String, dynamic>.from(json['rules'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'policyType': policyType,
      'policyContent': policyContent,
      'isActive': isActive,
      'type': type,
      'description': description,
      'rules': rules,
    };
  }
}