// lib/features/admin_sections/presentation/bloc/property_in_section_images/property_in_section_images_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/section_image.dart';

abstract class PropertyInSectionImagesState extends Equatable {
  const PropertyInSectionImagesState();

  @override
  List<Object?> get props => [];
}

class PropertyInSectionImageUpdated extends PropertyInSectionImagesState {
  final List<SectionImage> updatedImages;
  final String successMessage;

  const PropertyInSectionImageUpdated({
    required this.updatedImages,
    this.successMessage = 'Image updated successfully',
  });

  @override
  List<Object?> get props => [updatedImages, successMessage];
}

class PrimaryPropertyInSectionImageSet extends PropertyInSectionImagesState {
  final List<SectionImage> updatedImages;
  final String primaryImageId;
  final String successMessage;

  const PrimaryPropertyInSectionImageSet({
    required this.updatedImages,
    required this.primaryImageId,
    this.successMessage = 'Primary image set successfully',
  });

  @override
  List<Object?> get props => [updatedImages, primaryImageId, successMessage];
}

class PropertyInSectionImagesInitial extends PropertyInSectionImagesState {
  const PropertyInSectionImagesInitial();
}

class PropertyInSectionImagesLoading extends PropertyInSectionImagesState {
  final String? message;

  const PropertyInSectionImagesLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class PropertyInSectionImagesLoaded extends PropertyInSectionImagesState {
  final List<SectionImage> images;
  final String? propertyInSectionId;
  final Set<String> selected;
  final bool isSelectionMode;

  const PropertyInSectionImagesLoaded({
    required this.images,
    this.propertyInSectionId,
    this.selected = const {},
    this.isSelectionMode = false,
  });

  @override
  List<Object?> get props =>
      [images, propertyInSectionId, selected, isSelectionMode];
}

class PropertyInSectionImagesError extends PropertyInSectionImagesState {
  final String message;
  final List<SectionImage>? previousImages;

  const PropertyInSectionImagesError(this.message, {this.previousImages});

  @override
  List<Object?> get props => [message, previousImages];
}

class PropertyInSectionImageUploading extends PropertyInSectionImagesState {
  final List<SectionImage> current;
  final String? fileName;
  final double? progress;
  final int? total;
  final int? index;

  const PropertyInSectionImageUploading({
    required this.current,
    this.fileName,
    this.progress,
    this.total,
    this.index,
  });

  @override
  List<Object?> get props => [current, fileName, progress, total, index];
}

class PropertyInSectionImageUploaded extends PropertyInSectionImagesState {
  final SectionImage uploaded;
  final List<SectionImage> all;

  const PropertyInSectionImageUploaded({
    required this.uploaded,
    required this.all,
  });

  @override
  List<Object?> get props => [uploaded, all];
}

class MultiplePropertyInSectionImagesUploaded
    extends PropertyInSectionImagesState {
  final List<SectionImage> uploadedImages;
  final List<SectionImage> allImages;
  final int successCount;
  final int failedCount;
  final String successMessage;

  const MultiplePropertyInSectionImagesUploaded({
    required this.uploadedImages,
    required this.allImages,
    required this.successCount,
    this.failedCount = 0,
    this.successMessage = 'Images uploaded successfully',
  });

  @override
  List<Object?> get props => [
        uploadedImages,
        allImages,
        successCount,
        failedCount,
        successMessage,
      ];
}

class PropertyInSectionImageUpdating extends PropertyInSectionImagesState {
  final List<SectionImage> current;
  final String imageId;

  const PropertyInSectionImageUpdating({
    required this.current,
    required this.imageId,
  });

  @override
  List<Object?> get props => [current, imageId];
}

class PropertyInSectionImageDeleting extends PropertyInSectionImagesState {
  final List<SectionImage> current;
  final String imageId;

  const PropertyInSectionImageDeleting({
    required this.current,
    required this.imageId,
  });

  @override
  List<Object?> get props => [current, imageId];
}

class PropertyInSectionImageDeleted extends PropertyInSectionImagesState {
  final List<SectionImage> remaining;

  const PropertyInSectionImageDeleted({required this.remaining});

  @override
  List<Object?> get props => [remaining];
}

class MultiplePropertyInSectionImagesDeleted
    extends PropertyInSectionImagesState {
  final List<SectionImage> remaining;

  const MultiplePropertyInSectionImagesDeleted({required this.remaining});

  @override
  List<Object?> get props => [remaining];
}

class PropertyInSectionImagesReordering extends PropertyInSectionImagesState {
  final List<SectionImage> current;

  const PropertyInSectionImagesReordering({required this.current});

  @override
  List<Object?> get props => [current];
}

class PropertyInSectionImagesReordered extends PropertyInSectionImagesState {
  final List<SectionImage> reordered;

  const PropertyInSectionImagesReordered({required this.reordered});

  @override
  List<Object?> get props => [reordered];
}
