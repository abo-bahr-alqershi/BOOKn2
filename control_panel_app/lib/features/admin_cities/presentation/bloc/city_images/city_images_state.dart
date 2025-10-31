// lib/features/admin_citys/presentation/bloc/city_images/city_images_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/city_image.dart';

abstract class CityImagesState extends Equatable {
  const CityImagesState();

  @override
  List<Object?> get props => [];
}

class CityImagesInitial extends CityImagesState {
  const CityImagesInitial();
}

class CityImagesLoading extends CityImagesState {
  final String? message;

  const CityImagesLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class CityImagesLoaded extends CityImagesState {
  final List<CityImage> images;
  final Set<String> selectedImageIds;
  final String? currentCityId;
  final bool isSelectionMode;

  const CityImagesLoaded({
    required this.images,
    this.selectedImageIds = const {},
    this.currentCityId,
    this.isSelectionMode = false,
  });

  CityImagesLoaded copyWith({
    List<CityImage>? images,
    Set<String>? selectedImageIds,
    String? currentCityId,
    bool? isSelectionMode,
  }) {
    return CityImagesLoaded(
      images: images ?? this.images,
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      currentCityId: currentCityId ?? this.currentCityId,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  @override
  List<Object?> get props =>
      [images, selectedImageIds, currentCityId, isSelectionMode];
}

class CityImagesError extends CityImagesState {
  final String message;
  final List<CityImage>? previousImages;

  const CityImagesError({
    required this.message,
    this.previousImages,
  });

  @override
  List<Object?> get props => [message, previousImages];
}

class CityImageUploading extends CityImagesState {
  final List<CityImage> currentImages;
  final double? uploadProgress;
  final String? uploadingFileName;
  final int? currentFileIndex;
  final int? totalFiles;

  const CityImageUploading({
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

class CityImageUploaded extends CityImagesState {
  final CityImage uploadedImage;
  final List<CityImage> allImages;
  final String successMessage;

  const CityImageUploaded({
    required this.uploadedImage,
    required this.allImages,
    this.successMessage = 'Image uploaded successfully',
  });

  @override
  List<Object?> get props => [uploadedImage, allImages, successMessage];
}

class MultipleImagesUploaded extends CityImagesState {
  final List<CityImage> uploadedImages;
  final List<CityImage> allImages;
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

class CityImageDeleting extends CityImagesState {
  final List<CityImage> currentImages;
  final String imageId;

  const CityImageDeleting({
    required this.currentImages,
    required this.imageId,
  });

  @override
  List<Object?> get props => [currentImages, imageId];
}

class CityImageDeleted extends CityImagesState {
  final List<CityImage> remainingImages;
  final String successMessage;

  const CityImageDeleted({
    required this.remainingImages,
    this.successMessage = 'Image deleted successfully',
  });

  @override
  List<Object?> get props => [remainingImages, successMessage];
}

class MultipleImagesDeleted extends CityImagesState {
  final List<CityImage> remainingImages;
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

class CityImageUpdating extends CityImagesState {
  final List<CityImage> currentImages;
  final String imageId;

  const CityImageUpdating({
    required this.currentImages,
    required this.imageId,
  });

  @override
  List<Object?> get props => [currentImages, imageId];
}

class CityImageUpdated extends CityImagesState {
  final List<CityImage> updatedImages;
  final String successMessage;

  const CityImageUpdated({
    required this.updatedImages,
    this.successMessage = 'Image updated successfully',
  });

  @override
  List<Object?> get props => [updatedImages, successMessage];
}

class ImagesReordering extends CityImagesState {
  final List<CityImage> currentImages;

  const ImagesReordering({required this.currentImages});

  @override
  List<Object?> get props => [currentImages];
}

class ImagesReordered extends CityImagesState {
  final List<CityImage> reorderedImages;
  final String successMessage;

  const ImagesReordered({
    required this.reorderedImages,
    this.successMessage = 'Images reordered successfully',
  });

  @override
  List<Object?> get props => [reorderedImages, successMessage];
}

class PrimaryImageSet extends CityImagesState {
  final List<CityImage> updatedImages;
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
