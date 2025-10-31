import 'package:equatable/equatable.dart';
import '../../../../../core/enums/section_type.dart';
import '../../../../../core/enums/section_target.dart';
import '../../../../../core/enums/section_content_type.dart';
import '../../../../../core/enums/section_display_style.dart';
import '../../../../../core/enums/section_class.dart';

abstract class SectionFormEvent extends Equatable {
  const SectionFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeSectionFormEvent extends SectionFormEvent {
  final String? sectionId;
  const InitializeSectionFormEvent({this.sectionId});
}

class AttachSectionTempKeyEvent extends SectionFormEvent {
  final String tempKey;
  const AttachSectionTempKeyEvent({required this.tempKey});
}

class UpdateSectionBasicInfoEvent extends SectionFormEvent {
  final String? name;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? shortDescription;
  const UpdateSectionBasicInfoEvent({
    this.name,
    this.title,
    this.subtitle,
    this.description,
    this.shortDescription,
  });
}

class UpdateSectionConfigEvent extends SectionFormEvent {
  final SectionTypeEnum? type;
  final SectionContentType? contentType;
  final SectionDisplayStyle? displayStyle;
  final SectionTarget? target;
  final int? displayOrder;
  final int? columnsCount;
  final int? itemsToShow;
  final bool? isActive;
  final SectionClass? categoryClass;
  final int? homeItemsCount;
  const UpdateSectionConfigEvent({
    this.type,
    this.contentType,
    this.displayStyle,
    this.target,
    this.displayOrder,
    this.columnsCount,
    this.itemsToShow,
    this.isActive,
    this.categoryClass,
    this.homeItemsCount,
  });
}

class UpdateSectionAppearanceEvent extends SectionFormEvent {
  final String? icon;
  final String? colorTheme;
  final String? backgroundImage;
  const UpdateSectionAppearanceEvent({this.icon, this.colorTheme, this.backgroundImage});
}

class UpdateSectionFiltersEvent extends SectionFormEvent {
  final String? filterCriteriaJson;
  final String? sortCriteriaJson;
  final String? cityName;
  final String? propertyTypeId;
  final String? unitTypeId;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  const UpdateSectionFiltersEvent({
    this.filterCriteriaJson,
    this.sortCriteriaJson,
    this.cityName,
    this.propertyTypeId,
    this.unitTypeId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
  });
}

class UpdateSectionVisibilityEvent extends SectionFormEvent {
  final bool? isVisibleToGuests;
  final bool? isVisibleToRegistered;
  final String? requiresPermission;
  final DateTime? startDate;
  final DateTime? endDate;
  const UpdateSectionVisibilityEvent({
    this.isVisibleToGuests,
    this.isVisibleToRegistered,
    this.requiresPermission,
    this.startDate,
    this.endDate,
  });
}

class UpdateSectionMetadataEvent extends SectionFormEvent {
  final String? metadataJson;
  const UpdateSectionMetadataEvent({this.metadataJson});
}

class SubmitSectionFormEvent extends SectionFormEvent {}

