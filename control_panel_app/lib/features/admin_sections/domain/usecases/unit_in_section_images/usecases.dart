// lib/features/admin_sections/domain/usecases/unit_in_section_images/usecases.dart

import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../entities/section_image.dart';
import '../../repositories/unit_in_section_images_repository.dart';

// Upload UnitInSection Image
class UploadUnitInSectionImageParams {
  final String? unitInSectionId;
  final String? tempKey;
  final String filePath;
  final String? category;
  final String? alt;
  final bool isPrimary;
  final int? order;
  final List<String>? tags;
  final ProgressCallback? onSendProgress;

  UploadUnitInSectionImageParams({
    this.unitInSectionId,
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

class UploadUnitInSectionImageUseCase {
  final UnitInSectionImagesRepository repository;

  UploadUnitInSectionImageUseCase(this.repository);

  Future<Either<Failure, SectionImage>> call(
      UploadUnitInSectionImageParams params) {
    return repository.uploadImage(
      unitInSectionId: params.unitInSectionId,
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

// Get UnitInSection Images
class GetUnitInSectionImagesParams {
  final String? unitInSectionId;
  final String? tempKey;

  GetUnitInSectionImagesParams({this.unitInSectionId, this.tempKey});
}

class GetUnitInSectionImagesUseCase {
  final UnitInSectionImagesRepository repository;

  GetUnitInSectionImagesUseCase(this.repository);

  Future<Either<Failure, List<SectionImage>>> call(
      GetUnitInSectionImagesParams params) {
    return repository.getUnitInSectionImages(
      params.unitInSectionId,
      tempKey: params.tempKey,
    );
  }
}

// Update UnitInSection Image
class UpdateUnitInSectionImageParams {
  final String imageId;
  final Map<String, dynamic> data;

  UpdateUnitInSectionImageParams({
    required this.imageId,
    required this.data,
  });
}

class UpdateUnitInSectionImageUseCase {
  final UnitInSectionImagesRepository repository;

  UpdateUnitInSectionImageUseCase(this.repository);

  Future<Either<Failure, bool>> call(UpdateUnitInSectionImageParams params) {
    return repository.updateImage(params.imageId, params.data);
  }
}

// Delete UnitInSection Image
class DeleteUnitInSectionImageUseCase {
  final UnitInSectionImagesRepository repository;

  DeleteUnitInSectionImageUseCase(this.repository);

  Future<Either<Failure, bool>> call(String imageId) {
    return repository.deleteImage(imageId);
  }
}

// Delete Multiple UnitInSection Images
class DeleteMultipleUnitInSectionImagesUseCase {
  final UnitInSectionImagesRepository repository;

  DeleteMultipleUnitInSectionImagesUseCase(this.repository);

  Future<Either<Failure, bool>> call(List<String> imageIds) {
    return repository.deleteMultipleImages(imageIds);
  }
}

// Reorder UnitInSection Images
class ReorderUnitInSectionImagesParams {
  final String? unitInSectionId;
  final String? tempKey;
  final List<String> imageIds;

  ReorderUnitInSectionImagesParams({
    this.unitInSectionId,
    this.tempKey,
    required this.imageIds,
  });
}

class ReorderUnitInSectionImagesUseCase {
  final UnitInSectionImagesRepository repository;

  ReorderUnitInSectionImagesUseCase(this.repository);

  Future<Either<Failure, bool>> call(ReorderUnitInSectionImagesParams params) {
    return repository.reorderImages(
      params.unitInSectionId,
      params.tempKey,
      params.imageIds,
    );
  }
}

// Set Primary UnitInSection Image
class SetPrimaryUnitInSectionImageParams {
  final String? unitInSectionId;
  final String? tempKey;
  final String imageId;

  SetPrimaryUnitInSectionImageParams({
    this.unitInSectionId,
    this.tempKey,
    required this.imageId,
  });
}

class SetPrimaryUnitInSectionImageUseCase {
  final UnitInSectionImagesRepository repository;

  SetPrimaryUnitInSectionImageUseCase(this.repository);

  Future<Either<Failure, bool>> call(
      SetPrimaryUnitInSectionImageParams params) {
    return repository.setAsPrimaryImage(
      params.unitInSectionId,
      params.tempKey,
      params.imageId,
    );
  }
}

// Upload Multiple UnitInSection Images
class UploadMultipleUnitInSectionImagesParams {
  final String? unitInSectionId;
  final String? tempKey;
  final List<String> filePaths;
  final String? category;
  final List<String>? tags;
  final void Function(String filePath, int sent, int total)? onProgress;

  UploadMultipleUnitInSectionImagesParams({
    this.unitInSectionId,
    this.tempKey,
    required this.filePaths,
    this.category,
    this.tags,
    this.onProgress,
  });
}

class UploadMultipleUnitInSectionImagesUseCase {
  final UnitInSectionImagesRepository repository;

  UploadMultipleUnitInSectionImagesUseCase(this.repository);

  Future<Either<Failure, List<SectionImage>>> call(
    UploadMultipleUnitInSectionImagesParams params,
  ) {
    return repository.uploadMultipleImages(
      unitInSectionId: params.unitInSectionId,
      tempKey: params.tempKey,
      filePaths: params.filePaths,
      category: params.category,
      tags: params.tags,
      onProgress: params.onProgress,
    );
  }
}
