// lib/features/admin_properties/data/models/property_model.dart

import 'package:bookn_cp_app/core/constants/api_constants.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/entities/amenity.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/entities/policy.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/entities/property.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/entities/property_image.dart';
import 'property_image_model.dart';
import 'amenity_model.dart';
import 'policy_model.dart';

class PropertyModel extends Property {
  const PropertyModel({
    required super.id,
    required super.ownerId,
    required super.typeId,
    required super.name,
    super.shortDescription,
    double basePricePerNight = 0.0,
    required super.address,
    required super.city,
    super.latitude,
    super.longitude,
    required super.starRating,
    required super.description,
    required super.isApproved,
    required super.createdAt,
    super.viewCount,
    super.bookingCount,
    super.averageRating,
    super.currency,
    super.isFeatured,
    required super.ownerName,
    required super.typeName,
    super.distanceKm,
    super.images,
    super.amenities,
    super.policies,
    super.stats,
  });

  // دالة للتحقق من صحة URL
  static String _validateAndFixUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'https://via.placeholder.com/400x300?text=No+Image';
    }

    // التحقق من أن URL يبدأ بـ http أو https
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // إذا كان URL نسبي، أضف البروتوكول والدومين
      if (url.startsWith('/')) {
        // استبدل هذا بـ base URL الخاص بك
        return '${ApiConstants.imageBaseUrl}$url';
      }
      // إذا كان مجرد اسم ملف أو placeholder
      return 'https://via.placeholder.com/400x300?text=$url';
    }

    return url;
  }

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // معالجة آمنة للصور
    List<PropertyImage> parsedImages = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        parsedImages = (json['images'] as List)
            .map((e) {
              if (e is Map<String, dynamic>) {
                return PropertyImageModel.fromJson(e);
              } else if (e is String) {
                // إذا كانت الصورة عبارة عن URL string فقط
                final validUrl = _validateAndFixUrl(e);
                return PropertyImageModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  url: validUrl,
                  filename: 'image.jpg',
                  size: 0,
                  mimeType: 'image/jpeg',
                  width: 0,
                  height: 0,
                  uploadedAt: DateTime.now(),
                  uploadedBy: json['ownerId'] as String? ?? '',
                  order: parsedImages.length,
                  isPrimary: parsedImages.isEmpty,
                  category: ImageCategory.gallery,
                  processingStatus: ProcessingStatus.ready,
                  thumbnails: ImageThumbnailsModel(
                    small: validUrl,
                    medium: validUrl,
                    large: validUrl,
                    hd: validUrl,
                  ),
                );
              }
              return null;
            })
            .whereType<PropertyImage>()
            .toList();
      } else if (json['images'] is String) {
        // إذا كانت images عبارة عن URL واحد
        final imageUrl = _validateAndFixUrl(json['images'] as String);
        parsedImages = [
          PropertyImageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            url: imageUrl,
            filename: 'image.jpg',
            size: 0,
            mimeType: 'image/jpeg',
            width: 0,
            height: 0,
            uploadedAt: DateTime.now(),
            uploadedBy: json['ownerId'] as String? ?? '',
            order: 0,
            isPrimary: true,
            category: ImageCategory.gallery,
            processingStatus: ProcessingStatus.ready,
            thumbnails: ImageThumbnailsModel(
              small: imageUrl,
              medium: imageUrl,
              large: imageUrl,
              hd: imageUrl,
            ),
          ),
        ];
      }
    }

    return PropertyModel(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      typeId: json['typeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shortDescription: json['shortDescription'] as String?,
      basePricePerNight: (json['basePricePerNight'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      starRating: (json['starRating'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      bookingCount: (json['bookingCount'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'YER',
      isFeatured: json['isFeatured'] as bool? ?? false,
      ownerName: json['ownerName'] as String? ?? '',
      typeName: json['typeName'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      images: parsedImages,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return AmenityModel.fromJson(e);
                }
                return null;
              })
              .whereType<Amenity>()
              .toList() ??
          [],
      policies: (json['policies'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return PolicyModel.fromJson(e);
                }
                return null;
              })
              .whereType<Policy>()
              .toList() ??
          [],
      stats: json['stats'] != null && json['stats'] is Map<String, dynamic>
          ? PropertyStatsModel.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'typeId': typeId,
      'name': name,
      'shortDescription': shortDescription,
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
      'currency': currency,
      'isFeatured': isFeatured,
      'ownerName': ownerName,
      'typeName': typeName,
      'distanceKm': distanceKm,
      'images': images.map((e) => (e as PropertyImageModel).toJson()).toList(),
      'amenities': amenities.map((e) => (e as AmenityModel).toJson()).toList(),
      'policies': policies.map((e) => (e as PolicyModel).toJson()).toList(),
      'stats': stats != null ? (stats as PropertyStatsModel).toJson() : null,
    };
  }
}

class PropertyStatsModel extends PropertyStats {
  const PropertyStatsModel({
    required super.totalBookings,
    required super.activeBookings,
    required super.averageRating,
    required super.reviewCount,
    required super.occupancyRate,
    required super.monthlyRevenue,
  });

  factory PropertyStatsModel.fromJson(Map<String, dynamic> json) {
    return PropertyStatsModel(
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      activeBookings: (json['activeBookings'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (json['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'activeBookings': activeBookings,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'occupancyRate': occupancyRate,
      'monthlyRevenue': monthlyRevenue,
    };
  }
}
