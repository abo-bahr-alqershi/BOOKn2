// lib/features/admin_sections/domain/usecases/property_in_section_images/usecases.dart

import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../entities/section_image.dart';
import '../../repositories/property_in_section_images_repository.dart';

// Upload PropertyInSection Image
class UploadPropertyInSectionImageParams {
  final String? propertyInSectionId;
  final String? tempKey;
  final String filePath;
  final String? category;
  final String? alt;
  final bool isPrimary;
  final int? order;
  final List<String>? tags;
  final ProgressCallback? onSendProgress;

  UploadPropertyInSectionImageParams({
    this.propertyInSectionId,
    this.tempKey,
    required this.filePath,
    this.category,
    this.alt,
    this.isPrimary = false,
    this.order,
    this.tags,
    this.onSendProgress,
  });
}

class UploadPropertyInSectionImageUseCase {
  final PropertyInSectionImagesRepository repository;

  UploadPropertyInSectionImageUseCase(this.repository);

  Future<Either<Failure, SectionImage>> call(
      UploadPropertyInSectionImageParams params) {
    return repository.uploadImage(
      propertyInSectionId: params.propertyInSectionId,
      tempKey: params.tempKey,
      filePath: params.filePath,
      category: params.category,
      alt: params.alt,
      isPrimary: params.isPrimary,
      order: params.order,
      tags: params.tags,
      onSendProgress: params.onSendProgress,
    );
  }
}

// Get PropertyInSection Images
class GetPropertyInSectionImagesParams {
  final String? propertyInSectionId;
  final String? tempKey;

  GetPropertyInSectionImagesParams({this.propertyInSectionId, this.tempKey});
}

class GetPropertyInSectionImagesUseCase {
  final PropertyInSectionImagesRepository repository;

  GetPropertyInSectionImagesUseCase(this.repository);

  Future<Either<Failure, List<SectionImage>>> call(
      GetPropertyInSectionImagesParams params) {
    return repository.getPropertyInSectionImages(
      params.propertyInSectionId,
      tempKey: params.tempKey,
    );
  }
}

// Update PropertyInSection Image
class UpdatePropertyInSectionImageParams {
  final String imageId;
  final Map<String, dynamic> data;

  UpdatePropertyInSectionImageParams({
    required this.imageId,
    required this.data,
  });
}

class UpdatePropertyInSectionImageUseCase {
  final PropertyInSectionImagesRepository repository;

  UpdatePropertyInSectionImageUseCase(this.repository);

  Future<Either<Failure, bool>> call(
      UpdatePropertyInSectionImageParams params) {
    return repository.updateImage(params.imageId, params.data);
  }
}

// Delete PropertyInSection Image
class DeletePropertyInSectionImageUseCase {
  final PropertyInSectionImagesRepository repository;

  DeletePropertyInSectionImageUseCase(this.repository);

  Future<Either<Failure, bool>> call(String imageId) {
    return repository.deleteImage(imageId);
  }
}

// Delete Multiple PropertyInSection Images
class DeleteMultiplePropertyInSectionImagesUseCase {
  final PropertyInSectionImagesRepository repository;

  DeleteMultiplePropertyInSectionImagesUseCase(this.repository);

  Future<Either<Failure, bool>> call(List<String> imageIds) {
    return repository.deleteMultipleImages(imageIds);
  }
}

// Reorder PropertyInSection Images
class ReorderPropertyInSectionImagesParams {
  final String? propertyInSectionId;
  final String? tempKey;
  final List<String> imageIds;

  ReorderPropertyInSectionImagesParams({
    this.propertyInSectionId,
    this.tempKey,
    required this.imageIds,
  });
}

class ReorderPropertyInSectionImagesUseCase {
  final PropertyInSectionImagesRepository repository;

  ReorderPropertyInSectionImagesUseCase(this.repository);

  Future<Either<Failure, bool>> call(
      ReorderPropertyInSectionImagesParams params) {
    return repository.reorderImages(
      params.propertyInSectionId,
      params.tempKey,
      params.imageIds,
    );
  }
}

// Set Primary PropertyInSection Image
class SetPrimaryPropertyInSectionImageParams {
  final String? propertyInSectionId;
  final String? tempKey;
  final String imageId;

  SetPrimaryPropertyInSectionImageParams({
    this.propertyInSectionId,
    this.tempKey,
    required this.imageId,
  });
}

class SetPrimaryPropertyInSectionImageUseCase {
  final PropertyInSectionImagesRepository repository;

  SetPrimaryPropertyInSectionImageUseCase(this.repository);

  Future<Either<Failure, bool>> call(
      SetPrimaryPropertyInSectionImageParams params) {
    return repository.setAsPrimaryImage(
      params.propertyInSectionId,
      params.tempKey,
      params.imageId,
    );
  }
}

// Upload Multiple PropertyInSection Images
class UploadMultiplePropertyInSectionImagesParams {
  final String? propertyInSectionId;
  final String? tempKey;
  final List<String> filePaths;
  final String? category;
  final List<String>? tags;
  final void Function(String filePath, int sent, int total)? onProgress;

  UploadMultiplePropertyInSectionImagesParams({
    this.propertyInSectionId,
    this.tempKey,
    required this.filePaths,
    this.category,
    this.tags,
    this.onProgress,
  });
}

class UploadMultiplePropertyInSectionImagesUseCase {
  final PropertyInSectionImagesRepository repository;

  UploadMultiplePropertyInSectionImagesUseCase(this.repository);

  Future<Either<Failure, List<SectionImage>>> call(
    UploadMultiplePropertyInSectionImagesParams params,
  ) {
    return repository.uploadMultipleImages(
      propertyInSectionId: params.propertyInSectionId,
      tempKey: params.tempKey,
      filePaths: params.filePaths,
      category: params.category,
      tags: params.tags,
      onProgress: params.onProgress,
    );
  }
}
