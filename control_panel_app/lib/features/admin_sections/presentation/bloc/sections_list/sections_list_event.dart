import 'package:equatable/equatable.dart';
import '../../../../../core/enums/section_target.dart';
import '../../../../../core/enums/section_type.dart';
import '../../../../../core/enums/section_content_type.dart';

abstract class SectionsListEvent extends Equatable {
  const SectionsListEvent();

  @override
  List<Object?> get props => [];
}

class LoadSectionsEvent extends SectionsListEvent {
  final int? pageNumber;
  final int? pageSize;
  final SectionTarget? target;
  final SectionTypeEnum? type;
  final SectionContentType? contentType;

  const LoadSectionsEvent({
    this.pageNumber,
    this.pageSize,
    this.target,
    this.type,
    this.contentType,
  });

  @override
  List<Object?> get props => [pageNumber, pageSize, target, type, contentType];
}

class ChangeSectionsPageEvent extends SectionsListEvent {
  final int pageNumber;
  const ChangeSectionsPageEvent(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

class ApplySectionsFiltersEvent extends SectionsListEvent {
  final SectionTarget? target;
  final SectionTypeEnum? type;
  final SectionContentType? contentType;

  const ApplySectionsFiltersEvent({this.target, this.type, this.contentType});

  @override
  List<Object?> get props => [target, type, contentType];
}

class ToggleSectionStatusEvent extends SectionsListEvent {
  final String sectionId;
  final bool isActive;
  const ToggleSectionStatusEvent({required this.sectionId, required this.isActive});

  @override
  List<Object?> get props => [sectionId, isActive];
}

class DeleteSectionEvent extends SectionsListEvent {
  final String sectionId;
  const DeleteSectionEvent(this.sectionId);

  @override
  List<Object?> get props => [sectionId];
}

class RefreshSectionsEvent extends SectionsListEvent {}

