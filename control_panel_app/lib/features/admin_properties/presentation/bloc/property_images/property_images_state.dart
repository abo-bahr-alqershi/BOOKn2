// lib/features/admin_properties/presentation/bloc/property_images/property_images_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/property_image.dart';

abstract class PropertyImagesState extends Equatable {
  const PropertyImagesState();

  @override
  List<Object?> get props => [];
}

class PropertyImagesInitial extends PropertyImagesState {
  const PropertyImagesInitial();
}

class PropertyImagesLoading extends PropertyImagesState {
  final String? message;

  const PropertyImagesLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class PropertyImagesLoaded extends PropertyImagesState {
  final List<PropertyImage> images;
  final Set<String> selectedImageIds;
  final String? currentPropertyId;
  final bool isSelectionMode;

  const PropertyImagesLoaded({
    required this.images,
    this.selectedImageIds = const {},
    this.currentPropertyId,
    this.isSelectionMode = false,
  });

  PropertyImagesLoaded copyWith({
    List<PropertyImage>? images,
    Set<String>? selectedImageIds,
    String? currentPropertyId,
    bool? isSelectionMode,
  }) {
    return PropertyImagesLoaded(
      images: images ?? this.images,
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      currentPropertyId: currentPropertyId ?? this.currentPropertyId,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  @override
  List<Object?> get props =>
      [images, selectedImageIds, currentPropertyId, isSelectionMode];
}

class PropertyImagesError extends PropertyImagesState {
  final String message;
  final List<PropertyImage>? previousImages;

  const PropertyImagesError({
    required this.message,
    this.previousImages,
  });

  @override
  List<Object?> get props => [message, previousImages];
}

class PropertyImageUploading extends PropertyImagesState {
  final List<PropertyImage> currentImages;
  final double? uploadProgress;
  final String? uploadingFileName;
  final int? currentFileIndex;
  final int? totalFiles;

  const PropertyImageUploading({
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

class PropertyImageUploaded extends PropertyImagesState {
  final PropertyImage uploadedImage;
  final List<PropertyImage> allImages;
  final String successMessage;

  const PropertyImageUploaded({
    required this.uploadedImage,
    required this.allImages,
    this.successMessage = 'Image uploaded successfully',
  });

  @override
  List<Object?> get props => [uploadedImage, allImages, successMessage];
}

class MultipleImagesUploaded extends PropertyImagesState {
  final List<PropertyImage> uploadedImages;
  final List<PropertyImage> allImages;
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

class PropertyImageDeleting extends PropertyImagesState {
  final List<PropertyImage> currentImages;
  final String imageId;

  const PropertyImageDeleting({
    required this.currentImages,
    required this.imageId,
  });

  @override
  List<Object?> get props => [currentImages, imageId];
}

class PropertyImageDeleted extends PropertyImagesState {
  final List<PropertyImage> remainingImages;
  final String successMessage;

  const PropertyImageDeleted({
    required this.remainingImages,
    this.successMessage = 'Image deleted successfully',
  });

  @override
  List<Object?> get props => [remainingImages, successMessage];
}

class MultipleImagesDeleted extends PropertyImagesState {
  final List<PropertyImage> remainingImages;
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

class PropertyImageUpdating extends PropertyImagesState {
  final List<PropertyImage> currentImages;
  final String imageId;

  const PropertyImageUpdating({
    required this.currentImages,
    required this.imageId,
  });

  @override
  List<Object?> get props => [currentImages, imageId];
}

class PropertyImageUpdated extends PropertyImagesState {
  final List<PropertyImage> updatedImages;
  final String successMessage;

  const PropertyImageUpdated({
    required this.updatedImages,
    this.successMessage = 'Image updated successfully',
  });

  @override
  List<Object?> get props => [updatedImages, successMessage];
}

class ImagesReordering extends PropertyImagesState {
  final List<PropertyImage> currentImages;

  const ImagesReordering({required this.currentImages});

  @override
  List<Object?> get props => [currentImages];
}

class ImagesReordered extends PropertyImagesState {
  final List<PropertyImage> reorderedImages;
  final String successMessage;

  const ImagesReordered({
    required this.reorderedImages,
    this.successMessage = 'Images reordered successfully',
  });

  @override
  List<Object?> get props => [reorderedImages, successMessage];
}

class PrimaryImageSet extends PropertyImagesState {
  final List<PropertyImage> updatedImages;
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
