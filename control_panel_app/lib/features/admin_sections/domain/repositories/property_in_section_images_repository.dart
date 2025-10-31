// lib/features/admin_sections/domain/repositories/property_in_section_images_repository.dart

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../entities/section_image.dart';

abstract class PropertyInSectionImagesRepository {
  Future<Either<Failure, SectionImage>> uploadImage({
    String? propertyInSectionId,
    String? tempKey,
    required String filePath,
    String? category,
    String? alt,
    bool isPrimary,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  });

  Future<Either<Failure, List<SectionImage>>> getPropertyInSectionImages(
    String? propertyInSectionId, {
    String? tempKey,
  });

  Future<Either<Failure, bool>> updateImage(
    String imageId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, bool>> deleteImage(String imageId);

  Future<Either<Failure, bool>> reorderImages(
    String? propertyInSectionId,
    String? tempKey,
    List<String> imageIds,
  );

  Future<Either<Failure, bool>> setAsPrimaryImage(
    String? propertyInSectionId,
    String? tempKey,
    String imageId,
  );

  Future<Either<Failure, bool>> deleteMultipleImages(List<String> imageIds);

  Future<Either<Failure, List<SectionImage>>> uploadMultipleImages({
    String? propertyInSectionId,
    String? tempKey,
    required List<String> filePaths,
    String? category,
    List<String>? tags,
    void Function(String filePath, int sent, int total)? onProgress,
  });
}
