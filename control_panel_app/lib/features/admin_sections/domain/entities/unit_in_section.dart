import 'package:equatable/equatable.dart';
import 'section_image.dart';

class UnitInSection extends Equatable {
  final String id;
  final String sectionId;
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
  final List<SectionImage> additionalImages;
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

  const UnitInSection({
    required this.id,
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

  @override
  List<Object?> get props => [
        id,
        sectionId,
        unitId,
        propertyId,
        unitName,
        propertyName,
        unitTypeId,
        unitTypeName,
        unitTypeIcon,
        maxCapacity,
        basePrice,
        currency,
        pricingMethod,
        adultsCapacity,
        childrenCapacity,
        mainImageUrl,
        additionalImages,
        primaryFieldValues,
        propertyAddress,
        propertyCity,
        latitude,
        longitude,
        propertyStarRating,
        propertyAverageRating,
        mainAmenities,
        customFeatures,
        displayOrder,
        isFeatured,
        discountPercentage,
        discountedPrice,
        promotionalText,
        badge,
        badgeColor,
        isAvailable,
        nextAvailableDates,
      ];
}

