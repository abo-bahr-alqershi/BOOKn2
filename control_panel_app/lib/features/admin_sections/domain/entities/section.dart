import 'package:equatable/equatable.dart';
import '../../../../core/enums/section_type.dart';
import '../../../../core/enums/section_target.dart';
import '../../../../core/enums/section_content_type.dart';
import '../../../../core/enums/section_display_style.dart';
import '../../../../core/enums/section_class.dart';

class Section extends Equatable {
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

  const Section({
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

  Section copyWith({
    String? id,
    SectionTypeEnum? type,
    SectionContentType? contentType,
    SectionDisplayStyle? displayStyle,
    String? name,
    String? title,
    String? subtitle,
    String? description,
    String? shortDescription,
    int? displayOrder,
    SectionTarget? target,
    bool? isActive,
    int? columnsCount,
    int? itemsToShow,
    String? icon,
    String? colorTheme,
    String? backgroundImage,
    String? filterCriteria,
    String? sortCriteria,
    String? cityName,
    String? propertyTypeId,
    String? unitTypeId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? isVisibleToGuests,
    bool? isVisibleToRegistered,
    String? requiresPermission,
    DateTime? startDate,
    DateTime? endDate,
    String? metadata,
    SectionClass? categoryClass,
    int? homeItemsCount,
  }) {
    return Section(
      id: id ?? this.id,
      type: type ?? this.type,
      contentType: contentType ?? this.contentType,
      displayStyle: displayStyle ?? this.displayStyle,
      name: name ?? this.name,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      displayOrder: displayOrder ?? this.displayOrder,
      target: target ?? this.target,
      isActive: isActive ?? this.isActive,
      columnsCount: columnsCount ?? this.columnsCount,
      itemsToShow: itemsToShow ?? this.itemsToShow,
      icon: icon ?? this.icon,
      colorTheme: colorTheme ?? this.colorTheme,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      sortCriteria: sortCriteria ?? this.sortCriteria,
      cityName: cityName ?? this.cityName,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      unitTypeId: unitTypeId ?? this.unitTypeId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      isVisibleToGuests: isVisibleToGuests ?? this.isVisibleToGuests,
      isVisibleToRegistered:
          isVisibleToRegistered ?? this.isVisibleToRegistered,
      requiresPermission: requiresPermission ?? this.requiresPermission,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      metadata: metadata ?? this.metadata,
      categoryClass: categoryClass ?? this.categoryClass,
      homeItemsCount: homeItemsCount ?? this.homeItemsCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        contentType,
        displayStyle,
        name,
        title,
        subtitle,
        description,
        shortDescription,
        displayOrder,
        target,
        isActive,
        columnsCount,
        itemsToShow,
        icon,
        colorTheme,
        backgroundImage,
        filterCriteria,
        sortCriteria,
        cityName,
        propertyTypeId,
        unitTypeId,
        minPrice,
        maxPrice,
        minRating,
        isVisibleToGuests,
        isVisibleToRegistered,
        requiresPermission,
        startDate,
        endDate,
        metadata,
        categoryClass,
        homeItemsCount,
      ];
}
