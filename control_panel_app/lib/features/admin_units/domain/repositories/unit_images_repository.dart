// lib/features/admin_units/domain/repositories/unit_images_repository.dart

import 'package:bookn_cp_app/features/admin_units/domain/entities/unit_image.dart';
import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:dio/dio.dart';

abstract class UnitImagesRepository {
  Future<Either<Failure, UnitImage>> uploadImage({
    String? unitId,
    String? sectionId,
    String? unitInSectionId,
    String? tempKey,
    required String filePath,
    String? videoThumbnailPath,
    String? category,
    String? alt,
    bool isPrimary,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  });

  Future<Either<Failure, List<UnitImage>>> getUnitImages(String? unitId,
      {String? tempKey});

  Future<Either<Failure, bool>> updateImage(
    String imageId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, bool>> deleteImage(String imageId);

  Future<Either<Failure, bool>> reorderImages(
    String? unitId,
    String? tempKey,
    List<String> imageIds,
  );

  Future<Either<Failure, bool>> setAsPrimaryImage(
    String? unitId,
    String? tempKey,
    String imageId,
  );

  Future<Either<Failure, bool>> deleteMultipleImages(List<String> imageIds);

  Future<Either<Failure, List<UnitImage>>> uploadMultipleImages({
    String? unitId,
    String? tempKey,
    required List<String> filePaths,
    String? category,
    List<String>? tags,
    void Function(String filePath, int sent, int total)? onProgress,
  });
}
