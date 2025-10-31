import '../../domain/entities/unit_in_section.dart' as domain;
import 'section_image_model.dart';
import '../../domain/entities/section_image.dart' as section_img;

class UnitInSectionModel {
  final String id;
  final String sectionId;
  final String? unitInSectionId;
  final String unitId;
  final String propertyId;
  final String unitName;
  final String propertyName;
  final String unitTypeId;
  final String unitTypeName;
  final String? unitTypeIcon;
  final int maxCapacity;
  final double basePrice;
  final String currency;
  final String pricingMethod;
  final int? adultsCapacity;
  final int? childrenCapacity;
  final String? mainImageUrl;
  final String? mainImageId;
  final List<section_img.SectionImage> additionalImages;
  final Map<String, dynamic>? primaryFieldValues;
  final String propertyAddress;
  final String propertyCity;
  final double latitude;
  final double longitude;
  final int propertyStarRating;
  final double propertyAverageRating;
  final List<String>? mainAmenities;
  final Map<String, dynamic>? customFeatures;
  final int displayOrder;
  final bool isFeatured;
  final double? discountPercentage;
  final double? discountedPrice;
  final String? promotionalText;
  final String? badge;
  final String? badgeColor;
  final bool isAvailable;
  final List<String>? nextAvailableDates;

  const UnitInSectionModel({
    required this.id,
    required this.unitInSectionId,
    required this.sectionId,
    required this.unitId,
    required this.propertyId,
    required this.unitName,
    required this.propertyName,
    required this.unitTypeId,
    required this.unitTypeName,
    this.unitTypeIcon,
    required this.maxCapacity,
    required this.basePrice,
    required this.currency,
    required this.pricingMethod,
    this.adultsCapacity,
    this.childrenCapacity,
    this.mainImageUrl,
    this.additionalImages = const [],
    this.mainImageId,
    this.primaryFieldValues,
    required this.propertyAddress,
    required this.propertyCity,
    required this.latitude,
    required this.longitude,
    required this.propertyStarRating,
    required this.propertyAverageRating,
    this.mainAmenities,
    this.customFeatures,
    required this.displayOrder,
    this.isFeatured = false,
    this.discountPercentage,
    this.discountedPrice,
    this.promotionalText,
    this.badge,
    this.badgeColor,
    this.isAvailable = true,
    this.nextAvailableDates,
  });

  static double _toDouble(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static List<section_img.SectionImage>? _toImageList(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v
          .whereType<Map<String, dynamic>>()
          .map((m) => SectionImageModel.fromJson(m))
          .toList();
    }
    return null;
  }

  factory UnitInSectionModel.fromJson(Map<String, dynamic> json) {
    return UnitInSectionModel(
      id: (json['unitInSectionId'] ?? json['id'])?.toString() ?? '',
      unitInSectionId: json['unitInSectionId']?.toString(),
      sectionId: json['sectionId']?.toString() ?? '',
      unitId: json['unitId']?.toString() ?? '',
      propertyId: json['propertyId']?.toString() ?? '',
      unitName: json['unitName']?.toString() ?? '',
      propertyName: json['propertyName']?.toString() ?? '',
      unitTypeId: json['unitTypeId']?.toString() ?? '',
      unitTypeName: json['unitTypeName']?.toString() ?? '',
      unitTypeIcon: json['unitTypeIcon']?.toString(),
      maxCapacity: (json['maxCapacity'] is int)
          ? json['maxCapacity']
          : int.tryParse('${json['maxCapacity'] ?? 0}') ?? 0,
      basePrice: _toDouble(json['basePrice']),
      currency: json['currency']?.toString() ?? '',
      pricingMethod: json['pricingMethod']?.toString() ?? 'PerNight',
      adultsCapacity:
          json['adultsCapacity'] is int ? json['adultsCapacity'] : null,
      childrenCapacity:
          json['childrenCapacity'] is int ? json['childrenCapacity'] : null,
      mainImageUrl: json['mainImageUrl']?.toString(),
      mainImageId: json['mainImageId']?.toString(),
      additionalImages: _toImageList(json['additionalImages']) ?? const [],
      primaryFieldValues: json['primaryFieldValues'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['primaryFieldValues'])
          : null,
      propertyAddress: json['propertyAddress']?.toString() ?? '',
      propertyCity: json['propertyCity']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      propertyStarRating: (json['propertyStarRating'] is int)
          ? json['propertyStarRating']
          : int.tryParse('${json['propertyStarRating'] ?? 0}') ?? 0,
      propertyAverageRating: _toDouble(json['propertyAverageRating']),
      mainAmenities: _toStringList(json['mainAmenities']),
      customFeatures: json['customFeatures'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['customFeatures'])
          : null,
      displayOrder: (json['displayOrder'] is int)
          ? json['displayOrder']
          : int.tryParse('${json['displayOrder'] ?? 0}') ?? 0,
      isFeatured: json['isFeatured'] == true,
      discountPercentage: json['discountPercentage'] == null
          ? null
          : _toDouble(json['discountPercentage']),
      discountedPrice: json['discountedPrice'] == null
          ? null
          : _toDouble(json['discountedPrice']),
      promotionalText: json['promotionalText']?.toString(),
      badge: json['badge']?.toString(),
      badgeColor: json['badgeColor']?.toString(),
      isAvailable: json['isAvailable'] is bool ? json['isAvailable'] : true,
      nextAvailableDates: _toStringList(json['nextAvailableDates']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sectionId': sectionId,
        'unitId': unitId,
        'propertyId': propertyId,
        'unitName': unitName,
        'propertyName': propertyName,
        'unitTypeId': unitTypeId,
        'unitTypeName': unitTypeName,
        'unitTypeIcon': unitTypeIcon,
        'maxCapacity': maxCapacity,
        'basePrice': basePrice,
        'currency': currency,
        'pricingMethod': pricingMethod,
        'adultsCapacity': adultsCapacity,
        'childrenCapacity': childrenCapacity,
        'mainImageUrl': mainImageUrl,
        'additionalImages': additionalImages
            .map((e) => (e is SectionImageModel)
                ? e.toJson()
                : SectionImageModel.fromJson({
                    'id': e.id,
                    'url': e.url,
                    'filename': e.filename,
                    'size': e.size,
                    'mimeType': e.mimeType,
                    'width': e.width,
                    'height': e.height,
                    'uploadedAt': e.uploadedAt.toIso8601String(),
                    'uploadedBy': e.uploadedBy,
                    'order': e.order,
                    'isPrimary': e.isPrimary,
                    'category': e.category.name,
                    'tags': e.tags,
                    'processingStatus': e.processingStatus.name,
                    'thumbnails': (e.thumbnails)
                  }).toJson())
            .toList(),
        'mainImageId': mainImageId,
        'primaryFieldValues': primaryFieldValues,
        'propertyAddress': propertyAddress,
        'propertyCity': propertyCity,
        'latitude': latitude,
        'longitude': longitude,
        'propertyStarRating': propertyStarRating,
        'propertyAverageRating': propertyAverageRating,
        'mainAmenities': mainAmenities,
        'customFeatures': customFeatures,
        'displayOrder': displayOrder,
        'isFeatured': isFeatured,
        'discountPercentage': discountPercentage,
        'discountedPrice': discountedPrice,
        'promotionalText': promotionalText,
        'badge': badge,
        'badgeColor': badgeColor,
        'isAvailable': isAvailable,
        'nextAvailableDates': nextAvailableDates,
      };

  domain.UnitInSection toEntity() => domain.UnitInSection(
        id: id,
        sectionId: sectionId,
        unitId: unitId,
        propertyId: propertyId,
        unitName: unitName,
        propertyName: propertyName,
        unitTypeId: unitTypeId,
        unitTypeName: unitTypeName,
        unitTypeIcon: unitTypeIcon,
        maxCapacity: maxCapacity,
        basePrice: basePrice,
        currency: currency,
        pricingMethod: pricingMethod,
        adultsCapacity: adultsCapacity,
        childrenCapacity: childrenCapacity,
        mainImageUrl: mainImageUrl,
        additionalImages: additionalImages,
        primaryFieldValues: primaryFieldValues,
        propertyAddress: propertyAddress,
        propertyCity: propertyCity,
        latitude: latitude,
        longitude: longitude,
        propertyStarRating: propertyStarRating,
        propertyAverageRating: propertyAverageRating,
        mainAmenities: mainAmenities,
        customFeatures: customFeatures,
        displayOrder: displayOrder,
        isFeatured: isFeatured,
        discountPercentage: discountPercentage,
        discountedPrice: discountedPrice,
        promotionalText: promotionalText,
        badge: badge,
        badgeColor: badgeColor,
        isAvailable: isAvailable,
        nextAvailableDates: nextAvailableDates,
      );

  static List<String>? _toStringList(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    if (v is String && v.isNotEmpty) {
      return v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return null;
  }
}
