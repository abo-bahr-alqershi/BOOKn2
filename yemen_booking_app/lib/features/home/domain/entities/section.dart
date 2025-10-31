// lib/features/home/domain/entities/section.dart

import 'package:equatable/equatable.dart';
import '../../../../core/enums/section_type_enum.dart';
import '../../../../core/enums/section_target_enum.dart';

class Section extends Equatable {
  final String id;
  // Original type (kept for backward compatibility)
  final SectionType type;
  // Computed UI type used by presentation layer
  final SectionType uiType;
  final int displayOrder;
  final SectionTarget target;
  final bool isActive;

  // Optional rich fields coming from backend (used for headers/behaviour)
  final String? name;
  final String? title;
  final String? subtitle;
  final String? contentType; // 'Properties' | 'Units' | 'Mixed'
  final String? displayStyle; // 'Grid' | 'List' | 'Carousel' | 'Map'
  final int columnsCount;
  final int itemsToShow;
  final int? homeItemsCount; // overrides itemsToShow on home if provided
  final String? categoryClass; // ClassA | ClassB | ClassC | ClassD
  final String? metadata; // JSON string

  const Section({
    required this.id,
    required this.type,
    required this.uiType,
    required this.displayOrder,
    required this.target,
    required this.isActive,
    this.name,
    this.title,
    this.subtitle,
    this.contentType,
    this.displayStyle,
    this.columnsCount = 2,
    this.itemsToShow = 10,
    this.homeItemsCount,
    this.categoryClass,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        uiType,
        displayOrder,
        target,
        isActive,
        name,
        title,
        subtitle,
        contentType,
        displayStyle,
        columnsCount,
        itemsToShow,
        homeItemsCount,
        categoryClass,
        metadata,
      ];
}

class SectionItem extends Equatable {
  final String id;
  final String sectionId;
  final String? propertyId;
  final String? unitId;
  final int sortOrder;

  const SectionItem({
    required this.id,
    required this.sectionId,
    this.propertyId,
    this.unitId,
    required this.sortOrder,
  });

  @override
  List<Object?> get props => [id, sectionId, propertyId, unitId, sortOrder];
}