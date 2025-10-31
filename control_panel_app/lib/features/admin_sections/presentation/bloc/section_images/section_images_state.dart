// lib/features/admin_sections/presentation/bloc/section_images/section_images_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/section_image.dart';

abstract class SectionImagesState extends Equatable {
  const SectionImagesState();

  @override
  List<Object?> get props => [];
}

class SectionImagesInitial extends SectionImagesState {
  const SectionImagesInitial();
}

class SectionImagesLoading extends SectionImagesState {
  final String? message;

  const SectionImagesLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class SectionImagesLoaded extends SectionImagesState {
  final List<SectionImage> images;
  final Set<String> selectedImageIds;
  final String? currentSectionId;
  final bool isSelectionMode;

  const SectionImagesLoaded({
    required this.images,
    this.selectedImageIds = const {},
    this.currentSectionId,
    this.isSelectionMode = false,
  });

  SectionImagesLoaded copyWith({
    List<SectionImage>? images,
    Set<String>? selectedImageIds,
    String? currentSectionId,
    bool? isSelectionMode,
  }) {
    return SectionImagesLoaded(
      images: images ?? this.images,
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      currentSectionId: currentSectionId ?? this.currentSectionId,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  @override
  List<Object?> get props =>
      [images, selectedImageIds, currentSectionId, isSelectionMode];
}

class SectionImagesError extends SectionImagesState {
  final String message;
  final List<SectionImage>? previousImages;

  const SectionImagesError({
    required this.message,
    this.previousImages,
  });

  @override
  List<Object?> get props => [message, previousImages];
}

class SectionImageUploading extends SectionImagesState {
  final List<SectionImage> currentImages;
  final double? uploadProgress;
  final String? uploadingFileName;
  final int? currentFileIndex;
  final int? totalFiles;

  const SectionImageUploading({
    required this.currentImages,
    this.uploadProgress,
    this.uploadingFileName,
    this.currentFileIndex,
    this.totalFiles,
  });

  @override
  List<Object?> get props => [
        currentImages,
        uploadProgress,
        uploadingFileName,
        currentFileIndex,
        totalFiles,
      ];
}

class SectionImageUploaded extends SectionImagesState {
  final SectionImage uploadedImage;
  final List<SectionImage> allImages;
  final String successMessage;

  const SectionImageUploaded({
    required this.uploadedImage,
    required this.allImages,
    this.successMessage = 'Image uploaded successfully',
  });

  @override
  List<Object?> get props => [uploadedImage, allImages, successMessage];
}

class MultipleSectionImagesUploaded extends SectionImagesState {
  final List<SectionImage> uploadedImages;
  final List<SectionImage> allImages;
  final int successCount;
  final int failedCount;
  final String successMessage;

  const MultipleSectionImagesUploaded({
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

class SectionImageDeleting extends SectionImagesState {
  final List<SectionImage> currentImages;
  final String imageId;

  const SectionImageDeleting({
    required this.currentImages,
    required this.imageId,
  });

  @override
  List<Object?> get props => [currentImages, imageId];
}

class SectionImageDeleted extends SectionImagesState {
  final List<SectionImage> remainingImages;
  final String successMessage;

  const SectionImageDeleted({
    required this.remainingImages,
    this.successMessage = 'Image deleted successfully',
  });

  @override
  List<Object?> get props => [remainingImages, successMessage];
}

class MultipleSectionImagesDeleted extends SectionImagesState {
  final List<SectionImage> remainingImages;
  final int deletedCount;
  final String successMessage;

  const MultipleSectionImagesDeleted({
    required this.remainingImages,
    required this.deletedCount,
    this.successMessage = 'Images deleted successfully',
  });

  @override
  List<Object?> get props => [remainingImages, deletedCount, successMessage];
}

class SectionImageUpdating extends SectionImagesState {
  final List<SectionImage> currentImages;
  final String imageId;

  const SectionImageUpdating({
    required this.currentImages,
    required this.imageId,
  });

  @override
  List<Object?> get props => [currentImages, imageId];
}

class SectionImageUpdated extends SectionImagesState {
  final List<SectionImage> updatedImages;
  final String successMessage;

  const SectionImageUpdated({
    required this.updatedImages,
    this.successMessage = 'Image updated successfully',
  });

  @override
  List<Object?> get props => [updatedImages, successMessage];
}

class SectionImagesReordering extends SectionImagesState {
  final List<SectionImage> currentImages;

  const SectionImagesReordering({required this.currentImages});

  @override
  List<Object?> get props => [currentImages];
}

class SectionImagesReordered extends SectionImagesState {
  final List<SectionImage> reorderedImages;
  final String successMessage;

  const SectionImagesReordered({
    required this.reorderedImages,
    this.successMessage = 'Images reordered successfully',
  });

  @override
  List<Object?> get props => [reorderedImages, successMessage];
}

class PrimarySectionImageSet extends SectionImagesState {
  final List<SectionImage> updatedImages;
  final String primaryImageId;
  final String successMessage;

  const PrimarySectionImageSet({
    required this.updatedImages,
    required this.primaryImageId,
    this.successMessage = 'Primary image set successfully',
  });

  @override
  List<Object?> get props => [updatedImages, primaryImageId, successMessage];
}
