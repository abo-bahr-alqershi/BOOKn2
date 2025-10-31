// lib/features/admin_sections/presentation/bloc/property_in_section_images/property_in_section_images_event.dart

import 'package:equatable/equatable.dart';

abstract class PropertyInSectionImagesEvent extends Equatable {
  const PropertyInSectionImagesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPropertyInSectionImagesEvent extends PropertyInSectionImagesEvent {
  final String? propertyInSectionId;
  final String? tempKey;
  final int? page;
  final int? limit;

  const LoadPropertyInSectionImagesEvent({
    this.propertyInSectionId,
    this.tempKey,
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [propertyInSectionId, tempKey, page, limit];
}

class UploadPropertyInSectionImageEvent extends PropertyInSectionImagesEvent {
  final String? propertyInSectionId;
  final String? tempKey;
  final String filePath;
  final String? category;
  final String? alt;
  final bool isPrimary;
  final int? order;
  final List<String>? tags;

  const UploadPropertyInSectionImageEvent({
    this.propertyInSectionId,
    this.tempKey,
    required this.filePath,
    this.category,
    this.alt,
    this.isPrimary = false,
    this.order,
    this.tags,
  });

  @override
  List<Object?> get props => [
        propertyInSectionId,
        tempKey,
        filePath,
        category,
        alt,
        isPrimary,
        order,
        tags
      ];
}

class UploadMultiplePropertyInSectionImagesEvent
    extends PropertyInSectionImagesEvent {
  final String? propertyInSectionId;
  final String? tempKey;
  final List<String> filePaths;
  final String? category;
  final List<String>? tags;

  const UploadMultiplePropertyInSectionImagesEvent({
    this.propertyInSectionId,
    this.tempKey,
    required this.filePaths,
    this.category,
    this.tags,
  });

  @override
  List<Object?> get props =>
      [propertyInSectionId, tempKey, filePaths, category, tags];
}

class UpdatePropertyInSectionImageEvent extends PropertyInSectionImagesEvent {
  final String imageId;
  final Map<String, dynamic> data;

  const UpdatePropertyInSectionImageEvent({
    required this.imageId,
    required this.data,
  });

  @override
  List<Object?> get props => [imageId, data];
}

class DeletePropertyInSectionImageEvent extends PropertyInSectionImagesEvent {
  final String imageId;
  final bool permanent;

  const DeletePropertyInSectionImageEvent({
    required this.imageId,
    this.permanent = false,
  });

  @override
  List<Object?> get props => [imageId, permanent];
}

class DeleteMultiplePropertyInSectionImagesEvent
    extends PropertyInSectionImagesEvent {
  final List<String> imageIds;

  const DeleteMultiplePropertyInSectionImagesEvent({required this.imageIds});

  @override
  List<Object?> get props => [imageIds];
}

class ReorderPropertyInSectionImagesEvent extends PropertyInSectionImagesEvent {
  final String? propertyInSectionId;
  final String? tempKey;
  final List<String> imageIds;

  const ReorderPropertyInSectionImagesEvent({
    this.propertyInSectionId,
    this.tempKey,
    required this.imageIds,
  });

  @override
  List<Object?> get props => [propertyInSectionId, tempKey, imageIds];
}

class SetPrimaryPropertyInSectionImageEvent
    extends PropertyInSectionImagesEvent {
  final String? propertyInSectionId;
  final String? tempKey;
  final String imageId;

  const SetPrimaryPropertyInSectionImageEvent({
    this.propertyInSectionId,
    this.tempKey,
    required this.imageId,
  });

  @override
  List<Object?> get props => [propertyInSectionId, tempKey, imageId];
}

class ClearPropertyInSectionImagesEvent extends PropertyInSectionImagesEvent {
  const ClearPropertyInSectionImagesEvent();
}

class RefreshPropertyInSectionImagesEvent extends PropertyInSectionImagesEvent {
  final String? propertyInSectionId;
  final String? tempKey;

  const RefreshPropertyInSectionImagesEvent({
    this.propertyInSectionId,
    this.tempKey,
  });

  @override
  List<Object?> get props => [propertyInSectionId, tempKey];
}

class ToggleSelectPropertyInSectionImageEvent
    extends PropertyInSectionImagesEvent {
  final String imageId;

  const ToggleSelectPropertyInSectionImageEvent({required this.imageId});

  @override
  List<Object?> get props => [imageId];
}

class SelectAllPropertyInSectionImagesEvent
    extends PropertyInSectionImagesEvent {
  const SelectAllPropertyInSectionImagesEvent();
}

class ClearPropertyInSectionSelectionEvent
    extends PropertyInSectionImagesEvent {
  const ClearPropertyInSectionSelectionEvent();
}

class DeselectAllPropertyInSectionImagesEvent
    extends PropertyInSectionImagesEvent {
  const DeselectAllPropertyInSectionImagesEvent();
}
