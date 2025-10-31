import '../../domain/entities/section.dart' as domain;
import '../../../../core/enums/section_type.dart';
import '../../../../core/enums/section_target.dart';
import '../../../../core/enums/section_content_type.dart';
import '../../../../core/enums/section_display_style.dart';
import '../../../../core/enums/section_class.dart';

class SectionModel {
  final String? tempKey;
  final String id;
  final SectionTypeEnum type;
  final SectionContentType contentType;
  final SectionDisplayStyle displayStyle;
  final String? name;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? shortDescription;
  final int displayOrder;
  final SectionTarget target;
  final bool isActive;
  final int columnsCount;
  final int itemsToShow;
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
  final bool isVisibleToGuests;
  final bool isVisibleToRegistered;
  final String? requiresPermission;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? metadata;
  final SectionClass? categoryClass;
  final int? homeItemsCount;

  const SectionModel({
    this.tempKey,
    required this.id,
    required this.type,
    required this.contentType,
    required this.displayStyle,
    this.name,
    this.title,
    this.subtitle,
    this.description,
    this.shortDescription,
    required this.displayOrder,
    required this.target,
    required this.isActive,
    required this.columnsCount,
    required this.itemsToShow,
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
    this.isVisibleToGuests = true,
    this.isVisibleToRegistered = true,
    this.requiresPermission,
    this.startDate,
    this.endDate,
    this.metadata,
    this.categoryClass,
    this.homeItemsCount,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    SectionTypeEnum parseType(dynamic v) {
      final s = (v ?? '').toString();
      return SectionUITypeExtension.tryFromString(s) ?? SectionTypeEnum.singlePropertyAd;
    }

    SectionContentType parseContentType(dynamic v) {
      final s = (v ?? 'Properties').toString();
      return SectionContentTypeApi.tryParse(s) ?? SectionContentType.properties;
    }

    SectionDisplayStyle parseDisplayStyle(dynamic v) {
      final s = (v ?? 'Grid').toString();
      return SectionDisplayStyleApi.tryParse(s) ?? SectionDisplayStyle.grid;
    }

    SectionTarget parseTarget(dynamic v) {
      final s = (v ?? 'Properties').toString();
      return SectionTargetApi.tryParse(s) ?? SectionTarget.properties;
    }

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    DateTime? toDate(dynamic v) {
      if (v == null || v.toString().isEmpty) return null;
      return DateTime.tryParse(v.toString());
    }

    return SectionModel(
      tempKey: json['tempKey']?.toString(),
      id: json['id']?.toString() ?? '',
      type: parseType(json['type']),
      contentType: parseContentType(json['contentType']),
      displayStyle: parseDisplayStyle(json['displayStyle']),
      name: json['name'],
      title: json['title'],
      subtitle: json['subtitle'],
      description: json['description'],
      shortDescription: json['shortDescription'],
      displayOrder: (json['displayOrder'] is int)
          ? json['displayOrder']
          : int.tryParse('${json['displayOrder'] ?? 0}') ?? 0,
      target: parseTarget(json['target']),
      isActive: json['isActive'] == null
          ? true
          : (json['isActive'] is bool
              ? (json['isActive'] as bool)
              : ['true', '1', 'yes', 'on']
                  .contains(json['isActive'].toString().toLowerCase())),
      columnsCount: (json['columnsCount'] is int)
          ? json['columnsCount']
          : int.tryParse('${json['columnsCount'] ?? 2}') ?? 2,
      itemsToShow: (json['itemsToShow'] is int)
          ? json['itemsToShow']
          : int.tryParse('${json['itemsToShow'] ?? 10}') ?? 10,
      icon: json['icon'],
      colorTheme: json['colorTheme'],
      backgroundImage: json['backgroundImage'],
      filterCriteria: json['filterCriteria'],
      sortCriteria: json['sortCriteria'],
      cityName: json['cityName'],
      propertyTypeId: json['propertyTypeId']?.toString(),
      unitTypeId: json['unitTypeId']?.toString(),
      minPrice: toDouble(json['minPrice']),
      maxPrice: toDouble(json['maxPrice']),
      minRating: toDouble(json['minRating']),
      isVisibleToGuests: json['isVisibleToGuests'] is bool
          ? json['isVisibleToGuests']
          : true,
      isVisibleToRegistered: json['isVisibleToRegistered'] is bool
          ? json['isVisibleToRegistered']
          : true,
      requiresPermission: json['requiresPermission']?.toString(),
      startDate: toDate(json['startDate']),
      endDate: toDate(json['endDate']),
      metadata: json['metadata']?.toString(),
      categoryClass: SectionClassApi.tryParse(json['categoryClass']?.toString()),
      homeItemsCount: (json['homeItemsCount'] is int)
          ? json['homeItemsCount']
          : int.tryParse('${json['homeItemsCount'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': type.value,
      'contentType': contentType.apiValue,
      'displayStyle': displayStyle.apiValue,
      'name': name,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'shortDescription': shortDescription,
      'displayOrder': displayOrder,
      'target': target.apiValue,
      'isActive': isActive,
      'columnsCount': columnsCount,
      'itemsToShow': itemsToShow,
      'icon': icon,
      'colorTheme': colorTheme,
      'backgroundImage': backgroundImage,
      'filterCriteria': filterCriteria,
      'sortCriteria': sortCriteria,
      'cityName': cityName,
      'propertyTypeId': propertyTypeId,
      'unitTypeId': unitTypeId,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minRating': minRating,
      'isVisibleToGuests': isVisibleToGuests,
      'isVisibleToRegistered': isVisibleToRegistered,
      'requiresPermission': requiresPermission,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'metadata': metadata,
      if (categoryClass != null) 'categoryClass': categoryClass!.apiValue,
      if (homeItemsCount != null) 'homeItemsCount': homeItemsCount,
    };
    if (tempKey != null && tempKey!.isNotEmpty) {
      map['tempKey'] = tempKey;
    }
    // Only include id when it's non-empty to avoid backend validation issues on create
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  domain.Section toEntity() {
    return domain.Section(
      id: id,
      type: type,
      contentType: contentType,
      displayStyle: displayStyle,
      name: name,
      title: title,
      subtitle: subtitle,
      description: description,
      shortDescription: shortDescription,
      displayOrder: displayOrder,
      target: target,
      isActive: isActive,
      columnsCount: columnsCount,
      itemsToShow: itemsToShow,
      categoryClass: categoryClass,
      homeItemsCount: homeItemsCount,
      icon: icon,
      colorTheme: colorTheme,
      backgroundImage: backgroundImage,
      filterCriteria: filterCriteria,
      sortCriteria: sortCriteria,
      cityName: cityName,
      propertyTypeId: propertyTypeId,
      unitTypeId: unitTypeId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      isVisibleToGuests: isVisibleToGuests,
      isVisibleToRegistered: isVisibleToRegistered,
      requiresPermission: requiresPermission,
      startDate: startDate,
      endDate: endDate,
      metadata: metadata,
    );
  }
}

