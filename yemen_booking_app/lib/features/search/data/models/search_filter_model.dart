import 'package:yemen_booking_app/features/search/domain/entities/search_result.dart';

import '../../domain/entities/search_filter.dart';

class SearchFilterModel extends SearchFilter {
  const SearchFilterModel({
    required super.filterId,
    required super.fieldId,
    required super.filterType,
    required super.displayName,
    required super.filterOptions,
    required super.isActive,
    required super.sortOrder,
    super.field,
  });

  factory SearchFilterModel.fromJson(Map<String, dynamic> json) {
    return SearchFilterModel(
      filterId: json['filterId'] ?? '',
      fieldId: json['fieldId'] ?? '',
      filterType: json['filterType'] ?? '',
      displayName: json['displayName'] ?? '',
      filterOptions: Map<String, dynamic>.from(json['filterOptions'] ?? {}),
      isActive: json['isActive'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      field: json['field'] != null
          ? UnitTypeFieldModel.fromJson(json['field'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filterId': filterId,
      'fieldId': fieldId,
      'filterType': filterType,
      'displayName': displayName,
      'filterOptions': filterOptions,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'field': field != null ? (field as UnitTypeFieldModel).toJson() : null,
    };
  }
}

class UnitTypeFieldModel extends UnitTypeField {
  const UnitTypeFieldModel({
    required super.fieldId,
    required super.unitTypeId,
    required super.fieldTypeId,
    required super.fieldName,
    required super.displayName,
    super.description,
    required super.fieldOptions,
    required super.validationRules,
    required super.isRequired,
    required super.isSearchable,
    required super.isPublic,
    required super.sortOrder,
    super.category,
    super.groupId,
    required super.isForUnits,
    required super.showInCards,
    required super.isPrimaryFilter,
    required super.priority,
  });

  factory UnitTypeFieldModel.fromJson(Map<String, dynamic> json) {
    return UnitTypeFieldModel(
      fieldId: json['fieldId'] ?? '',
      unitTypeId: json['unitTypeId'] ?? '',
      fieldTypeId: json['fieldTypeId'] ?? '',
      fieldName: json['fieldName'] ?? '',
      displayName: json['displayName'] ?? '',
      description: json['description'],
      fieldOptions: Map<String, dynamic>.from(json['fieldOptions'] ?? {}),
      validationRules: Map<String, dynamic>.from(json['validationRules'] ?? {}),
      isRequired: json['isRequired'] ?? false,
      isSearchable: json['isSearchable'] ?? false,
      isPublic: json['isPublic'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      category: json['category'],
      groupId: json['groupId'],
      isForUnits: json['isForUnits'] ?? false,
      showInCards: json['showInCards'] ?? false,
      isPrimaryFilter: json['isPrimaryFilter'] ?? false,
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'unitTypeId': unitTypeId,
      'fieldTypeId': fieldTypeId,
      'fieldName': fieldName,
      'displayName': displayName,
      'description': description,
      'fieldOptions': fieldOptions,
      'validationRules': validationRules,
      'isRequired': isRequired,
      'isSearchable': isSearchable,
      'isPublic': isPublic,
      'sortOrder': sortOrder,
      'category': category,
      'groupId': groupId,
      'isForUnits': isForUnits,
      'showInCards': showInCards,
      'isPrimaryFilter': isPrimaryFilter,
      'priority': priority,
    };
  }
}

class SearchFiltersModel extends SearchFilters {
  const SearchFiltersModel({
    required super.cities,
    required super.propertyTypes,
    required super.priceRange,
    required super.amenities,
    required super.starRatings,
    required super.availableCities,
    required super.maxGuestCapacity,
    required super.unitTypes,
    required super.distanceRange,
    required super.supportedCurrencies,
    required super.services,
    required super.dynamicFieldValues,
  });

  factory SearchFiltersModel.fromJson(Map<String, dynamic> json) {
    return SearchFiltersModel(
      cities: (json['cities'] as List?)
              ?.map((e) => CityFilterModel.fromJson(e))
              .toList() ??
          [],
      propertyTypes: (json['propertyTypes'] as List?)
              ?.map((e) => PropertyTypeFilterModel.fromJson(e))
              .toList() ??
          [],
      priceRange: json['priceRange'] != null
          ? PriceRangeModel.fromJson(json['priceRange'])
          : const PriceRangeModel(minPrice: 0, maxPrice: 0, averagePrice: 0),
      amenities: (json['amenities'] as List?)
              ?.map((e) => AmenityFilterModel.fromJson(e))
              .toList() ??
          [],
      starRatings: (json['starRatings'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      availableCities: (json['availableCities'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      maxGuestCapacity: json['maxGuestCapacity'] ?? 0,
      unitTypes: (json['unitTypes'] as List?)
              ?.map((e) => UnitTypeFilterModel.fromJson(e))
              .toList() ??
          [],
      distanceRange: json['distanceRange'] != null
          ? DistanceRangeModel.fromJson(json['distanceRange'])
          : const DistanceRangeModel(minDistance: 0, maxDistance: 50),
      supportedCurrencies: (json['supportedCurrencies'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      services: (json['services'] as List?)
              ?.map((e) => ServiceFilterModel.fromJson(e))
              .toList() ??
          [],
      dynamicFieldValues: (json['dynamicFieldValues'] as List?)
              ?.map((e) => DynamicFieldValueFilterModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cities': cities.map((e) => (e as CityFilterModel).toJson()).toList(),
      'propertyTypes': propertyTypes.map((e) => (e as PropertyTypeFilterModel).toJson()).toList(),
      'priceRange': (priceRange as PriceRangeModel).toJson(),
      'amenities': amenities.map((e) => (e as AmenityFilterModel).toJson()).toList(),
      'starRatings': starRatings,
      'availableCities': availableCities,
      'maxGuestCapacity': maxGuestCapacity,
      'unitTypes': unitTypes.map((e) => (e as UnitTypeFilterModel).toJson()).toList(),
      'distanceRange': (distanceRange as DistanceRangeModel).toJson(),
      'supportedCurrencies': supportedCurrencies,
      'services': services.map((e) => (e as ServiceFilterModel).toJson()).toList(),
      'dynamicFieldValues': dynamicFieldValues.map((e) => (e as DynamicFieldValueFilterModel).toJson()).toList(),
    };
  }
}

class CityFilterModel extends CityFilter {
  const CityFilterModel({
    required super.id,
    required super.name,
    required super.propertiesCount,
  });

  factory CityFilterModel.fromJson(Map<String, dynamic> json) {
    return CityFilterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      propertiesCount: json['propertiesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'propertiesCount': propertiesCount,
    };
  }
}

class PropertyTypeFilterModel extends PropertyTypeFilter {
  final String icon;

  const PropertyTypeFilterModel({
    required super.id,
    required super.name,
    required super.propertiesCount,
    this.icon = 'home', // Default icon if not provided
  });

  factory PropertyTypeFilterModel.fromJson(Map<String, dynamic> json) {
    return PropertyTypeFilterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      propertiesCount: json['propertiesCount'] ?? 0,
      icon: json['icon'] ?? 'home', // Default icon if not provided
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'propertiesCount': propertiesCount,
      'icon': icon ?? 'home', // Default icon if not provided
    };
  }
}

class PriceRangeModel extends PriceRange {
  const PriceRangeModel({
    required super.minPrice,
    required super.maxPrice,
    required super.averagePrice,
  });

  factory PriceRangeModel.fromJson(Map<String, dynamic> json) {
    return PriceRangeModel(
      minPrice: (json['minPrice'] ?? 0).toDouble(),
      maxPrice: (json['maxPrice'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'averagePrice': averagePrice,
    };
  }
}

class AmenityFilterModel extends AmenityFilter {
  const AmenityFilterModel({
    required super.id,
    required super.name,
    required super.category,
    required super.propertiesCount,
    super.icon = '',
  });

  factory AmenityFilterModel.fromJson(Map<String, dynamic> json) {
    return AmenityFilterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      propertiesCount: json['propertiesCount'] ?? 0,
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'propertiesCount': propertiesCount,
      'icon': icon,
    };
  }
}

class UnitTypeFilterModel extends UnitTypeFilter {
  // The ID of the property type this unit type belongs to
  final String propertyTypeId;
  final String icon;

  const UnitTypeFilterModel({
    required super.id,
    required super.name,
    required super.unitsCount,
    required this.propertyTypeId,
    super.isHasAdults = false,
    super.isHasChildren = false,
    super.isMultiDays = false,
    super.isRequiredToDetermineTheHour = false,
    this.icon = 'home',
  });

  factory UnitTypeFilterModel.fromJson(Map<String, dynamic> json) {
    return UnitTypeFilterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      unitsCount: json['unitsCount'] ?? 0,
      propertyTypeId: json['propertyTypeId'] ?? '',
      icon: json['icon'] ?? 'home',
      isHasAdults: json['isHasAdults'] ?? false,
      isHasChildren: json['isHasChildren'] ?? false, 
      isMultiDays: json['isMultiDays'] ?? false,
      isRequiredToDetermineTheHour: json['isRequiredToDetermineTheHour'] ?? false
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unitsCount': unitsCount,
      'propertyTypeId': propertyTypeId,
      'icon': icon,
      'isHasAdults': isHasAdults,
      'isHasChildren': isHasChildren,
      'isMultiDays': isMultiDays,
      'isRequiredToDetermineTheHour': isRequiredToDetermineTheHour,
    };
  }
}

class DistanceRangeModel extends DistanceRange {
  const DistanceRangeModel({
    required super.minDistance,
    required super.maxDistance,
  });

  factory DistanceRangeModel.fromJson(Map<String, dynamic> json) {
    return DistanceRangeModel(
      minDistance: (json['minDistance'] ?? 0).toDouble(),
      maxDistance: (json['maxDistance'] ?? 50).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minDistance': minDistance,
      'maxDistance': maxDistance,
    };
  }
}

class ServiceFilterModel extends ServiceFilter {
  const ServiceFilterModel({
    required super.id,
    required super.name,
    required super.propertiesCount,
    super.icon = 'service',
  });

  factory ServiceFilterModel.fromJson(Map<String, dynamic> json) {
    return ServiceFilterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      propertiesCount: json['propertiesCount'] ?? 0,
      icon: json['icon'] ?? 'service',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'propertiesCount': propertiesCount,
      'icon': icon,
    };
  }
}

class DynamicFieldValueFilterModel extends DynamicFieldValueFilter {
  const DynamicFieldValueFilterModel({
    required super.fieldName,
    required super.value,
    required super.count,
  });

  factory DynamicFieldValueFilterModel.fromJson(Map<String, dynamic> json) {
    return DynamicFieldValueFilterModel(
      fieldName: json['fieldName'] ?? '',
      value: json['value'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'value': value,
      'count': count,
    };
  }
}