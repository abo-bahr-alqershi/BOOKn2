import 'package:equatable/equatable.dart';
import 'section_image.dart';

class PropertyInSection extends Equatable {
  final String id;
  final String sectionId;
  final String propertyId;
  final String propertyName;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String propertyType;
  final int starRating;
  final double averageRating;
  final int reviewsCount;
  final double basePrice;
  final String currency;
  final String? mainImageUrl;
  final List<SectionImage> additionalImages;
  final String? shortDescription;
  final int displayOrder;
  final bool isFeatured;
  final double? discountPercentage;
  final String? promotionalText;
  final String? badge;
  final String? badgeColor;
  final DateTime? displayFrom;
  final DateTime? displayUntil;
  final int priority;
  final int viewsFromSection;
  final int clickCount;
  final double? conversionRate;
  final Map<String, dynamic>? metadata;

  const PropertyInSection({
    required this.id,
    required this.sectionId,
    required this.propertyId,
    required this.propertyName,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.propertyType,
    required this.starRating,
    required this.averageRating,
    required this.reviewsCount,
    required this.basePrice,
    required this.currency,
    this.mainImageUrl,
    this.additionalImages = const [],
    this.shortDescription,
    required this.displayOrder,
    this.isFeatured = false,
    this.discountPercentage,
    this.promotionalText,
    this.badge,
    this.badgeColor,
    this.displayFrom,
    this.displayUntil,
    this.priority = 0,
    this.viewsFromSection = 0,
    this.clickCount = 0,
    this.conversionRate,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        sectionId,
        propertyId,
        propertyName,
        address,
        city,
        latitude,
        longitude,
        propertyType,
        starRating,
        averageRating,
        reviewsCount,
        basePrice,
        currency,
        mainImageUrl,
        additionalImages,
        shortDescription,
        displayOrder,
        isFeatured,
        discountPercentage,
        promotionalText,
        badge,
        badgeColor,
        displayFrom,
        displayUntil,
        priority,
        viewsFromSection,
        clickCount,
        conversionRate,
        metadata,
      ];
}

