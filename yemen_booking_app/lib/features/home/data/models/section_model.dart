// lib/features/home/data/models/section_model.dart

import '../../domain/entities/section.dart' as domain;
import '../../../../core/enums/section_type_enum.dart';
import '../../../../core/enums/section_target_enum.dart';
import 'dart:convert';

class SectionModel {
  final String id;
  // UI type parsed directly from backend type string when it matches UI naming (backward-compat)
  final SectionType type;
  final int displayOrder;
  final SectionTarget target;
  final bool isActive;

  // Backend-rich fields
  final String backendType; // e.g., Featured, Discounted, Category, ...
  final String? contentType; // Properties | Units | Mixed
  final String? displayStyle; // Grid | List | Carousel | Map
  final String? name;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? shortDescription;
  final int? columnsCount;
  final int? itemsToShow;
  final int? homeItemsCount;
  final String? categoryClass; // ClassA | ClassB | ClassC | ClassD
  final String? icon;
  final String? colorTheme;
  final String? backgroundImage;
  final String? filterCriteria;
  final String? sortCriteria;
  final String? cityName;
  final String? propertyTypeId;
  final String? unitTypeId;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? isVisibleToGuests;
  final bool? isVisibleToRegistered;
  final String? requiresPermission;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? metadata; // JSON string

  const SectionModel({
    required this.id,
    required this.type,
    required this.displayOrder,
    required this.target,
    required this.isActive,
    required this.backendType,
    this.contentType,
    this.displayStyle,
    this.name,
    this.title,
    this.subtitle,
    this.description,
    this.shortDescription,
    this.columnsCount,
    this.itemsToShow,
    this.homeItemsCount,
    this.categoryClass,
    this.icon,
    this.colorTheme,
    this.backgroundImage,
    this.filterCriteria,
    this.sortCriteria,
    this.cityName,
    this.propertyTypeId,
    this.unitTypeId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.isVisibleToGuests,
    this.isVisibleToRegistered,
    this.requiresPermission,
    this.startDate,
    this.endDate,
    this.metadata,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    String asString(dynamic v) => v?.toString() ?? '';
    int parseInt(dynamic v, int def) => v is int ? v : int.tryParse(asString(v)) ?? def;
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(asString(v));
    }
    DateTime? parseDate(dynamic v) {
      if (v == null || asString(v).isEmpty) return null;
      return DateTime.tryParse(asString(v));
    }

    final rawType = asString(json['type'] ?? json['sectionType']);
    final targetStr = asString(json['target']);
    final dynamic rawIsActive = json['isActive'];
    final bool parsedIsActive = () {
      if (rawIsActive == null) return true;
      if (rawIsActive is bool) return rawIsActive;
      if (rawIsActive is num) return rawIsActive != 0;
      final String s = rawIsActive.toString().trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes' || s == 'y' || s == 'on';
    }();

    return SectionModel(
      id: asString(json['id']),
      type: SectionTypeExtension.tryFromString(rawType) ?? SectionType.horizontalPropertyList,
      displayOrder: parseInt(json['displayOrder'] ?? json['order'], 0),
      target: SectionTargetBackend.tryParse(targetStr) ?? SectionTarget.properties,
      isActive: parsedIsActive,
      backendType: rawType,
      contentType: asString(json['contentType']).isEmpty ? null : asString(json['contentType']),
      displayStyle: asString(json['displayStyle']).isEmpty ? null : asString(json['displayStyle']),
      name: json['name']?.toString(),
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      shortDescription: json['shortDescription']?.toString(),
      columnsCount: json['columnsCount'] == null ? null : parseInt(json['columnsCount'], 2),
      itemsToShow: json['itemsToShow'] == null ? null : parseInt(json['itemsToShow'], 10),
      homeItemsCount: json['homeItemsCount'] == null ? null : parseInt(json['homeItemsCount'], 0),
      categoryClass: asString(json['categoryClass']).isEmpty ? null : asString(json['categoryClass']),
      icon: json['icon']?.toString(),
      colorTheme: json['colorTheme']?.toString(),
      backgroundImage: json['backgroundImage']?.toString(),
      filterCriteria: json['filterCriteria']?.toString(),
      sortCriteria: json['sortCriteria']?.toString(),
      cityName: json['cityName']?.toString(),
      propertyTypeId: json['propertyTypeId']?.toString(),
      unitTypeId: json['unitTypeId']?.toString(),
      minPrice: parseDouble(json['minPrice']),
      maxPrice: parseDouble(json['maxPrice']),
      minRating: parseDouble(json['minRating']),
      isVisibleToGuests: json['isVisibleToGuests'] is bool ? json['isVisibleToGuests'] as bool : null,
      isVisibleToRegistered: json['isVisibleToRegistered'] is bool ? json['isVisibleToRegistered'] as bool : null,
      requiresPermission: json['requiresPermission']?.toString(),
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      metadata: json['metadata']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'displayOrder': displayOrder,
      'target': target.backendName,
      'isActive': isActive,
      'contentType': contentType,
      'displayStyle': displayStyle,
      'name': name,
      'title': title,
      'subtitle': subtitle,
      'columnsCount': columnsCount,
      'itemsToShow': itemsToShow,
      'homeItemsCount': homeItemsCount,
      'categoryClass': categoryClass,
      'metadata': metadata,
    };
  }

  Map<String, dynamic>? get metadataJson {
    if (metadata == null || metadata!.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(metadata!);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  SectionType _computeUiType() {
    // 1) Explicit UI type in metadata
    final uiTypeStr = metadataJson?['uiType']?.toString();
    final byMeta = uiTypeStr == null ? null : SectionTypeExtension.tryFromString(uiTypeStr);
    if (byMeta != null) return byMeta;

    final ds = (displayStyle ?? '').toLowerCase();
    final bt = backendType.toLowerCase();
    final tgt = target;

    // 2) Heuristics by display style and backend type
    if (ds == 'carousel') {
      if (bt == 'discounted' || bt == 'limitedtimeoffer' || metadataJson?['isFlashDeals'] == true) {
        return SectionType.flashDeals;
      }
      if (bt == 'featured' || bt == 'recommended' || bt == 'toprated') {
        return SectionType.premiumCarousel;
      }
      return SectionType.offersCarousel;
    }

    if (ds == 'grid') {
      if ((cityName != null && cityName!.isNotEmpty) || bt == 'category') {
        return SectionType.cityCardsGrid;
      }
      return SectionType.verticalPropertyGrid;
    }

    if (ds == 'list') {
      return SectionType.horizontalPropertyList;
    }

    // 3) Fallbacks
    if (tgt == SectionTarget.properties) {
      return SectionType.horizontalPropertyList;
    }
    return SectionType.verticalPropertyGrid;
  }

  domain.Section toEntity() => domain.Section(
        id: id,
        type: type,
        uiType: _computeUiType(),
        displayOrder: displayOrder,
        target: target,
        isActive: isActive,
        // Optional rich fields
        name: name,
        title: title,
        subtitle: subtitle,
        contentType: contentType,
        displayStyle: displayStyle,
        columnsCount: columnsCount ?? 2,
        itemsToShow: itemsToShow ?? 10,
        homeItemsCount: homeItemsCount,
        categoryClass: categoryClass,
        metadata: metadata,
      );
}

class SectionItemModel {
  final String id;
  final String sectionId;
  final String? propertyId;
  final String? unitId;
  final int sortOrder;

  const SectionItemModel({
    required this.id,
    required this.sectionId,
    this.propertyId,
    this.unitId,
    required this.sortOrder,
  });

  factory SectionItemModel.fromJson(Map<String, dynamic> json) {
    return SectionItemModel(
      id: json['id']?.toString() ?? '',
      sectionId: json['sectionId']?.toString() ?? '',
      propertyId: json['propertyId']?.toString(),
      unitId: json['unitId']?.toString(),
      sortOrder: json['sortOrder'] is int
          ? (json['sortOrder'] as int)
          : int.tryParse((json['sortOrder'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sectionId': sectionId,
      'propertyId': propertyId,
      'unitId': unitId,
      'sortOrder': sortOrder,
    };
  }

  domain.SectionItem toEntity() => domain.SectionItem(
        id: id,
        sectionId: sectionId,
        propertyId: propertyId,
        unitId: unitId,
        sortOrder: sortOrder,
      );
}