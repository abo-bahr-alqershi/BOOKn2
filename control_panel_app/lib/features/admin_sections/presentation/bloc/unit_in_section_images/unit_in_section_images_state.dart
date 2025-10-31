// lib/features/admin_sections/presentation/bloc/unit_in_section_images/unit_in_section_images_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/section_image.dart';

abstract class UnitInSectionImagesState extends Equatable {
  const UnitInSectionImagesState();

  @override
  List<Object?> get props => [];
}

class UnitInSectionImagesInitial extends UnitInSectionImagesState {
  const UnitInSectionImagesInitial();
}

class UnitInSectionImagesLoading extends UnitInSectionImagesState {
  const UnitInSectionImagesLoading();
}

class UnitInSectionImagesError extends UnitInSectionImagesState {
  final String message;
  final List<SectionImage>? previousImages;

  const UnitInSectionImagesError(this.message, {this.previousImages});

  @override
  List<Object?> get props => [message, previousImages];
}

class UnitInSectionImagesLoaded extends UnitInSectionImagesState {
  final List<SectionImage> images;
  final String? unitInSectionId;
  final Set<String> selected;
  final bool isSelectionMode;

  const UnitInSectionImagesLoaded({
    required this.images,
    this.unitInSectionId,
    this.selected = const {},
    this.isSelectionMode = false,
  });

  @override
  List<Object?> get props =>
      [images, unitInSectionId, selected, isSelectionMode];
}

class UnitInSectionImageUploading extends UnitInSectionImagesState {
  final List<SectionImage> current;
  final String? fileName;
  final double? progress;
  final int? total;
  final int? index;

  const UnitInSectionImageUploading({
    required this.current,
    this.fileName,
    this.progress,
    this.total,
    this.index,
  });

  @override
  List<Object?> get props => [current, fileName, progress, total, index];
}

class UnitInSectionImageUploaded extends UnitInSectionImagesState {
  final SectionImage uploaded;
  final List<SectionImage> all;

  const UnitInSectionImageUploaded({
    required this.uploaded,
    required this.all,
  });

  @override
  List<Object?> get props => [uploaded, all];
}

class MultipleUnitInSectionImagesUploaded extends UnitInSectionImagesState {
  final List<SectionImage> uploadedImages;
  final List<SectionImage> allImages;
  final int successCount;
  final int failedCount;
  final String successMessage;

  const MultipleUnitInSectionImagesUploaded({
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

class UnitInSectionImageUpdating extends UnitInSectionImagesState {
  final List<SectionImage> current;
  final String imageId;

  const UnitInSectionImageUpdating({
    required this.current,
    required this.imageId,
  });

  @override
  List<Object?> get props => [current, imageId];
}

class UnitInSectionImageDeleting extends UnitInSectionImagesState {
  final List<SectionImage> current;
  final String imageId;

  const UnitInSectionImageDeleting({
    required this.current,
    required this.imageId,
  });

  @override
  List<Object?> get props => [current, imageId];
}

class UnitInSectionImageUpdated extends UnitInSectionImagesState {
  final List<SectionImage> updatedImages;
  final String successMessage;

  const UnitInSectionImageUpdated({
    required this.updatedImages,
    this.successMessage = 'Image updated successfully',
  });

  @override
  List<Object?> get props => [updatedImages, successMessage];
}

class PrimaryUnitInSectionImageSet extends UnitInSectionImagesState {
  final List<SectionImage> updatedImages;
  final String primaryImageId;
  final String successMessage;

  const PrimaryUnitInSectionImageSet({
    required this.updatedImages,
    required this.primaryImageId,
    this.successMessage = 'Primary image set successfully',
  });

  @override
  List<Object?> get props => [updatedImages, primaryImageId, successMessage];
}

class UnitInSectionImageDeleted extends UnitInSectionImagesState {
  final List<SectionImage> remaining;

  const UnitInSectionImageDeleted({required this.remaining});
}

class MultipleUnitInSectionImagesDeleted extends UnitInSectionImagesState {
  final List<SectionImage> remaining;

  const MultipleUnitInSectionImagesDeleted({required this.remaining});
}

class UnitInSectionImagesReordering extends UnitInSectionImagesState {
  final List<SectionImage> current;

  const UnitInSectionImagesReordering({required this.current});
}

class UnitInSectionImagesReordered extends UnitInSectionImagesState {
  final List<SectionImage> reordered;

  const UnitInSectionImagesReordered({required this.reordered});
}
