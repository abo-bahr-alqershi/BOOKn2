// lib/features/admin_sections/domain/usecases/section_images/usecases.dart

import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../entities/section_image.dart';
import '../../repositories/section_images_repository.dart';

// Upload Section Image
class UploadSectionImageParams {
  final String? sectionId;
  final String? tempKey;
  final String filePath;
  final String? category;
  final String? alt;
  final bool isPrimary;
  final int? order;
  final List<String>? tags;
  final ProgressCallback? onSendProgress;

  UploadSectionImageParams({
    this.sectionId,
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

class UploadSectionImageUseCase {
  final SectionImagesRepository repository;

  UploadSectionImageUseCase(this.repository);

  Future<Either<Failure, SectionImage>> call(UploadSectionImageParams params) {
    return repository.uploadImage(
      sectionId: params.sectionId,
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

// Get Section Images
class GetSectionImagesParams {
  final String? sectionId;
  final String? tempKey;

  GetSectionImagesParams({this.sectionId, this.tempKey});
}

class GetSectionImagesUseCase {
  final SectionImagesRepository repository;

  GetSectionImagesUseCase(this.repository);

  Future<Either<Failure, List<SectionImage>>> call(
      GetSectionImagesParams params) {
    return repository.getSectionImages(params.sectionId,
        tempKey: params.tempKey);
  }
}

// Update Section Image
class UpdateSectionImageParams {
  final String imageId;
  final Map<String, dynamic> data;

  UpdateSectionImageParams({
    required this.imageId,
    required this.data,
  });
}

class UpdateSectionImageUseCase {
  final SectionImagesRepository repository;

  UpdateSectionImageUseCase(this.repository);

  Future<Either<Failure, bool>> call(UpdateSectionImageParams params) {
    return repository.updateImage(params.imageId, params.data);
  }
}

// Delete Section Image
class DeleteSectionImageUseCase {
  final SectionImagesRepository repository;

  DeleteSectionImageUseCase(this.repository);

  Future<Either<Failure, bool>> call(String imageId) {
    return repository.deleteImage(imageId);
  }
}

// Delete Multiple Section Images
class DeleteMultipleSectionImagesUseCase {
  final SectionImagesRepository repository;

  DeleteMultipleSectionImagesUseCase(this.repository);

  Future<Either<Failure, bool>> call(List<String> imageIds) {
    return repository.deleteMultipleImages(imageIds);
  }
}

// Reorder Section Images
class ReorderSectionImagesParams {
  final String? sectionId;
  final String? tempKey;
  final List<String> imageIds;

  ReorderSectionImagesParams({
    this.sectionId,
    this.tempKey,
    required this.imageIds,
  });
}

class ReorderSectionImagesUseCase {
  final SectionImagesRepository repository;

  ReorderSectionImagesUseCase(this.repository);

  Future<Either<Failure, bool>> call(ReorderSectionImagesParams params) {
    return repository.reorderImages(
      params.sectionId,
      params.tempKey,
      params.imageIds,
    );
  }
}

// Set Primary Section Image
class SetPrimarySectionImageParams {
  final String? sectionId;
  final String? tempKey;
  final String imageId;

  SetPrimarySectionImageParams({
    this.sectionId,
    this.tempKey,
    required this.imageId,
  });
}

class SetPrimarySectionImageUseCase {
  final SectionImagesRepository repository;

  SetPrimarySectionImageUseCase(this.repository);

  Future<Either<Failure, bool>> call(SetPrimarySectionImageParams params) {
    return repository.setAsPrimaryImage(
      params.sectionId,
      params.tempKey,
      params.imageId,
    );
  }
}

// Upload Multiple Section Images
class UploadMultipleSectionImagesParams {
  final String? sectionId;
  final String? tempKey;
  final List<String> filePaths;
  final String? category;
  final List<String>? tags;
  final void Function(String filePath, int sent, int total)? onProgress;

  UploadMultipleSectionImagesParams({
    this.sectionId,
    this.tempKey,
    required this.filePaths,
    this.category,
    this.tags,
    this.onProgress,
  });
}

class UploadMultipleSectionImagesUseCase {
  final SectionImagesRepository repository;

  UploadMultipleSectionImagesUseCase(this.repository);

  Future<Either<Failure, List<SectionImage>>> call(
    UploadMultipleSectionImagesParams params,
  ) {
    return repository.uploadMultipleImages(
      sectionId: params.sectionId,
      tempKey: params.tempKey,
      filePaths: params.filePaths,
      category: params.category,
      tags: params.tags,
      onProgress: params.onProgress,
    );
  }
}
