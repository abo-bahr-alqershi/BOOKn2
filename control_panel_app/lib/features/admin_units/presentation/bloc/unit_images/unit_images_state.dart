// lib/features/admin_units/presentation/bloc/unit_images/unit_images_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/unit_image.dart';

abstract class UnitImagesState extends Equatable {
  const UnitImagesState();

  @override
  List<Object?> get props => [];
}

class UnitImagesInitial extends UnitImagesState {
  const UnitImagesInitial();
}

class UnitImagesLoading extends UnitImagesState {
  final String? message;

  const UnitImagesLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class UnitImagesLoaded extends UnitImagesState {
  final List<UnitImage> images;
  final Set<String> selectedImageIds;
  final String? currentUnitId;
  final bool isSelectionMode;

  const UnitImagesLoaded({
    required this.images,
    this.selectedImageIds = const {},
    this.currentUnitId,
    this.isSelectionMode = false,
  });

  UnitImagesLoaded copyWith({
    List<UnitImage>? images,
    Set<String>? selectedImageIds,
    String? currentUnitId,
    bool? isSelectionMode,
  }) {
    return UnitImagesLoaded(
      images: images ?? this.images,
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      currentUnitId: currentUnitId ?? this.currentUnitId,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  @override
  List<Object?> get props => [images, selectedImageIds, currentUnitId, isSelectionMode];
}

class UnitImagesError extends UnitImagesState {
  final String message;
  final List<UnitImage>? previousImages;

  const UnitImagesError({
    required this.message,
    this.previousImages,
  });

  @override
  List<Object?> get props => [message, previousImages];
}

class UnitImageUploading extends UnitImagesState {
  final List<UnitImage> currentImages;
  final double? uploadProgress;
  final String? uploadingFileName;
  final int? currentFileIndex;
  final int? totalFiles;

  const UnitImageUploading({
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

class UnitImageUploaded extends UnitImagesState {
  final UnitImage uploadedImage;
  final List<UnitImage> allImages;
  final String successMessage;

  const UnitImageUploaded({
    required this.uploadedImage,
    required this.allImages,
    this.successMessage = 'Image uploaded successfully',
  });

  @override
  List<Object?> get props => [uploadedImage, allImages, successMessage];
}

class MultipleImagesUploaded extends UnitImagesState {
  final List<UnitImage> uploadedImages;
  final List<UnitImage> allImages;
  final int successCount;
  final int failedCount;
  final String successMessage;

  const MultipleImagesUploaded({
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

class UnitImageDeleting extends UnitImagesState {
  final List<UnitImage> currentImages;
  final String imageId;

  const UnitImageDeleting({
    required this.currentImages,
    required this.imageId,
  });

  @override
  List<Object?> get props => [currentImages, imageId];
}

class UnitImageDeleted extends UnitImagesState {
  final List<UnitImage> remainingImages;
  final String successMessage;

  const UnitImageDeleted({
    required this.remainingImages,
    this.successMessage = 'Image deleted successfully',
  });

  @override
  List<Object?> get props => [remainingImages, successMessage];
}

class MultipleImagesDeleted extends UnitImagesState {
  final List<UnitImage> remainingImages;
  final int deletedCount;
  final String successMessage;

  const MultipleImagesDeleted({
    required this.remainingImages,
    required this.deletedCount,
    this.successMessage = 'Images deleted successfully',
  });

  @override
  List<Object?> get props => [remainingImages, deletedCount, successMessage];
}

class UnitImageUpdating extends UnitImagesState {
  final List<UnitImage> currentImages;
  final String imageId;

  const UnitImageUpdating({
    required this.currentImages,
    required this.imageId,
  });

  @override
  List<Object?> get props => [currentImages, imageId];
}

class UnitImageUpdated extends UnitImagesState {
  final List<UnitImage> updatedImages;
  final String successMessage;

  const UnitImageUpdated({
    required this.updatedImages,
    this.successMessage = 'Image updated successfully',
  });

  @override
  List<Object?> get props => [updatedImages, successMessage];
}

class ImagesReordering extends UnitImagesState {
  final List<UnitImage> currentImages;

  const ImagesReordering({required this.currentImages});

  @override
  List<Object?> get props => [currentImages];
}

class ImagesReordered extends UnitImagesState {
  final List<UnitImage> reorderedImages;
  final String successMessage;

  const ImagesReordered({
    required this.reorderedImages,
    this.successMessage = 'Images reordered successfully',
  });

  @override
  List<Object?> get props => [reorderedImages, successMessage];
}

class PrimaryImageSet extends UnitImagesState {
  final List<UnitImage> updatedImages;
  final String primaryImageId;
  final String successMessage;

  const PrimaryImageSet({
    required this.updatedImages,
    required this.primaryImageId,
    this.successMessage = 'Primary image set successfully',
  });

  @override
  List<Object?> get props => [updatedImages, primaryImageId, successMessage];
}
