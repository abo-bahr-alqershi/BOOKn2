import 'package:equatable/equatable.dart';

class SearchResult extends Equatable {
  final String id;
  final String name;
  final String description;
  final String address;
  final String city;
  final int starRating;
  final double averageRating;
  final int reviewsCount;
  final double minPrice;
  final double discountedPrice;
  final String currency;
  final String? mainImageUrl;
  final bool isRecommended;
  final double? distanceKm;
  final double latitude;
  final double longitude;
  final String? unitId;
  final String? unitName;
  final Map<String, dynamic> dynamicFieldValues;
  final bool isAvailable;
  final int availableUnitsCount;
  final String propertyType;
  final bool isFeatured;
  final List<String> mainAmenities;
  final List<Review> reviews;
  final bool isFavorite;
  final int matchPercentage;
  final int maxCapacity;
  final DateTime lastUpdated;
  final List<String> imageUrls;

  const SearchResult({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.starRating,
    required this.averageRating,
    required this.reviewsCount,
    required this.minPrice,
    required this.discountedPrice,
    required this.currency,
    this.mainImageUrl,
    required this.isRecommended,
    this.distanceKm,
    required this.latitude,
    required this.longitude,
    this.unitId,
    this.unitName,
    required this.dynamicFieldValues,
    required this.isAvailable,
    required this.availableUnitsCount,
    required this.propertyType,
    required this.isFeatured,
    required this.mainAmenities,
    required this.reviews,
    required this.isFavorite,
    required this.matchPercentage,
    required this.maxCapacity,
    required this.lastUpdated,
    required this.imageUrls,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        address,
        city,
        starRating,
        averageRating,
        reviewsCount,
        minPrice,
        discountedPrice,
        currency,
        mainImageUrl,
        isRecommended,
        distanceKm,
        latitude,
        longitude,
        unitId,
        unitName,
        dynamicFieldValues,
        isAvailable,
        availableUnitsCount,
        propertyType,
        isFeatured,
        mainAmenities,
        reviews,
        isFavorite,
        matchPercentage,
        maxCapacity,
        lastUpdated,
        imageUrls,
      ];
}

class Review extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, userName, rating, comment, createdAt];
}

class SearchFilters extends Equatable {
  final List<CityFilter> cities;
  final List<PropertyTypeFilter> propertyTypes;
  final PriceRange priceRange;
  final List<AmenityFilter> amenities;
  final List<int> starRatings;
  final List<String> availableCities;
  final int maxGuestCapacity;
  final List<UnitTypeFilter> unitTypes;
  final DistanceRange distanceRange;
  final List<String> supportedCurrencies;
  final List<ServiceFilter> services;
  final List<DynamicFieldValueFilter> dynamicFieldValues;

  const SearchFilters({
    required this.cities,
    required this.propertyTypes,
    required this.priceRange,
    required this.amenities,
    required this.starRatings,
    required this.availableCities,
    required this.maxGuestCapacity,
    required this.unitTypes,
    required this.distanceRange,
    required this.supportedCurrencies,
    required this.services,
    required this.dynamicFieldValues,
  });

  @override
  List<Object> get props => [
        cities,
        propertyTypes,
        priceRange,
        amenities,
        starRatings,
        availableCities,
        maxGuestCapacity,
        unitTypes,
        distanceRange,
        supportedCurrencies,
        services,
        dynamicFieldValues,
      ];
}

class CityFilter extends Equatable {
  final String id;
  final String name;
  final int propertiesCount;

  const CityFilter({
    required this.id,
    required this.name,
    required this.propertiesCount,
  });

  @override
  List<Object> get props => [id, name, propertiesCount];
}

class PropertyTypeFilter extends Equatable {
  final String id;
  final String name;
  final int propertiesCount;

  const PropertyTypeFilter({
    required this.id,
    required this.name,
    required this.propertiesCount,
  });

  @override
  List<Object> get props => [id, name, propertiesCount];
}

class PriceRange extends Equatable {
  final double minPrice;
  final double maxPrice;
  final double averagePrice;

  const PriceRange({
    required this.minPrice,
    required this.maxPrice,
    required this.averagePrice,
  });

  @override
  List<Object> get props => [minPrice, maxPrice, averagePrice];
}

class AmenityFilter extends Equatable {
  final String id;
  final String name;
  final String category;
  final int propertiesCount;
  final String icon;

  const AmenityFilter({
    required this.id,
    required this.name,
    required this.category,
    required this.propertiesCount,
    required this.icon,
  });

  @override
  List<Object> get props => [id, name, category, propertiesCount, icon];
}

class UnitTypeFilter extends Equatable {
  final String id;
  final String name;
  final int unitsCount;
  final bool isHasAdults;
  final bool isHasChildren;
  final bool isMultiDays;
  final bool isRequiredToDetermineTheHour;
  const UnitTypeFilter({
    required this.id,
    required this.name,
    required this.unitsCount,
    required this.isHasAdults,
    required this.isHasChildren,
    required this.isMultiDays,
    required this.isRequiredToDetermineTheHour,
  });

  @override
  List<Object> get props => [id, name, unitsCount, isHasAdults, isHasChildren, isMultiDays, isRequiredToDetermineTheHour];
}

class DistanceRange extends Equatable {
  final double minDistance;
  final double maxDistance;

  const DistanceRange({
    required this.minDistance,
    required this.maxDistance,
  });

  @override
  List<Object> get props => [minDistance, maxDistance];
}

class ServiceFilter extends Equatable {
  final String id;
  final String name;
  final int propertiesCount;
  final String icon;

  const ServiceFilter({
    required this.id,
    required this.name,
    required this.propertiesCount,
    required this.icon,
  });

  @override
  List<Object> get props => [id, name, propertiesCount, icon];
}

class DynamicFieldValueFilter extends Equatable {
  final String fieldName;
  final String value;
  final int count;

  const DynamicFieldValueFilter({
    required this.fieldName,
    required this.value,
    required this.count,
  });

  @override
  List<Object> get props => [fieldName, value, count];
}