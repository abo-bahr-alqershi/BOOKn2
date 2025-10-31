// lib/features/admin_properties/domain/repositories/property_images_repository.dart

import 'package:bookn_cp_app/features/admin_properties/domain/entities/property_image.dart';
import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:dio/dio.dart';

abstract class PropertyImagesRepository {
  Future<Either<Failure, PropertyImage>> uploadImage({
    String? propertyId,
    String? tempKey,
    required String filePath,
    String? category,
    String? alt,
    bool isPrimary,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  });

  Future<Either<Failure, List<PropertyImage>>> getPropertyImages(
      String? propertyId,
      {String? tempKey});

  Future<Either<Failure, bool>> updateImage(
    String imageId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, bool>> deleteImage(String imageId);

  Future<Either<Failure, bool>> reorderImages(
    String? propertyId,
    String? tempKey,
    List<String> imageIds,
  );

  Future<Either<Failure, bool>> setAsPrimaryImage(
    String? propertyId,
    String? tempKey,
    String imageId,
  );

  Future<Either<Failure, bool>> deleteMultipleImages(List<String> imageIds);

  Future<Either<Failure, List<PropertyImage>>> uploadMultipleImages({
    String? propertyId,
    String? tempKey,
    required List<String> filePaths,
    String? category,
    List<String>? tags,
    void Function(String filePath, int sent, int total)? onProgress,
  });
}
