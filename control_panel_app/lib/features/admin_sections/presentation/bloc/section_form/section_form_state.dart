import 'package:equatable/equatable.dart';
import '../../../../../core/enums/section_type.dart';
import '../../../../../core/enums/section_target.dart';
import '../../../../../core/enums/section_content_type.dart';
import '../../../../../core/enums/section_display_style.dart';
import '../../../../../core/enums/section_class.dart';

abstract class SectionFormState extends Equatable {
  const SectionFormState();

  @override
  List<Object?> get props => [];
}

class SectionFormInitial extends SectionFormState {}

class SectionFormLoading extends SectionFormState {}

class SectionFormReady extends SectionFormState {
  final String? tempKey;
  final String? sectionId;
  final String? name;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? shortDescription;
  final SectionTypeEnum? type;
  final SectionContentType? contentType;
  final SectionDisplayStyle? displayStyle;
  final SectionTarget? target;
  final int? displayOrder;
  final bool? isActive;
  final int? columnsCount;
  final int? itemsToShow;
  final SectionClass? categoryClass;
  final int? homeItemsCount;
  final String? icon;
  final String? colorTheme;
  final String? backgroundImage;
  final String? filterCriteriaJson;
  final String? sortCriteriaJson;
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
  final String? metadataJson;

  const SectionFormReady({
    this.tempKey,
    this.sectionId,
    this.name,
    this.title,
    this.subtitle,
    this.description,
    this.shortDescription,
    this.type,
    this.contentType,
    this.displayStyle,
    this.target,
    this.displayOrder,
    this.isActive,
    this.columnsCount,
    this.itemsToShow,
    this.categoryClass,
    this.homeItemsCount,
    this.icon,
    this.colorTheme,
    this.backgroundImage,
    this.filterCriteriaJson,
    this.sortCriteriaJson,
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
    this.metadataJson,
  });

  SectionFormReady copyWith({
    String? tempKey,
    String? sectionId,
    String? name,
    String? title,
    String? subtitle,
    String? description,
    String? shortDescription,
    SectionTypeEnum? type,
    SectionContentType? contentType,
    SectionDisplayStyle? displayStyle,
    SectionTarget? target,
    int? displayOrder,
    bool? isActive,
    int? columnsCount,
    int? itemsToShow,
    SectionClass? categoryClass,
    int? homeItemsCount,
    String? icon,
    String? colorTheme,
    String? backgroundImage,
    String? filterCriteriaJson,
    String? sortCriteriaJson,
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
    String? metadataJson,
  }) {
    return SectionFormReady(
      tempKey: tempKey ?? this.tempKey,
      sectionId: sectionId ?? this.sectionId,
      name: name ?? this.name,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      type: type ?? this.type,
      contentType: contentType ?? this.contentType,
      displayStyle: displayStyle ?? this.displayStyle,
      target: target ?? this.target,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      columnsCount: columnsCount ?? this.columnsCount,
      itemsToShow: itemsToShow ?? this.itemsToShow,
      categoryClass: categoryClass ?? this.categoryClass,
      homeItemsCount: homeItemsCount ?? this.homeItemsCount,
      icon: icon ?? this.icon,
      colorTheme: colorTheme ?? this.colorTheme,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      filterCriteriaJson: filterCriteriaJson ?? this.filterCriteriaJson,
      sortCriteriaJson: sortCriteriaJson ?? this.sortCriteriaJson,
      cityName: cityName ?? this.cityName,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      unitTypeId: unitTypeId ?? this.unitTypeId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      isVisibleToGuests: isVisibleToGuests ?? this.isVisibleToGuests,
      isVisibleToRegistered: isVisibleToRegistered ?? this.isVisibleToRegistered,
      requiresPermission: requiresPermission ?? this.requiresPermission,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      metadataJson: metadataJson ?? this.metadataJson,
    );
  }
}

class SectionFormSubmitted extends SectionFormState {
  final String sectionId;
  const SectionFormSubmitted({required this.sectionId});
}

class SectionFormError extends SectionFormState {
  final String message;
  const SectionFormError({required this.message});
}

