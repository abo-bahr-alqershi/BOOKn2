// lib/features/admin_citys/domain/repositories/city_images_repository.dart

import 'package:bookn_cp_app/features/admin_cities/domain/entities/city_image.dart';
import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:dio/dio.dart';

abstract class CityImagesRepository {
  Future<Either<Failure, CityImage>> uploadImage({
    String? cityId,
    String? tempKey,
    required String filePath,
    String? category,
    String? alt,
    bool isPrimary = false,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  });

  Future<Either<Failure, List<CityImage>>> getCityImages(String? cityId,
      {String? tempKey});

  Future<Either<Failure, bool>> updateImage(
    String imageId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, bool>> deleteImage(String imageId);

  Future<Either<Failure, bool>> reorderImages(
    String? cityId,
    String? tempKey,
    List<String> imageIds,
  );

  Future<Either<Failure, bool>> setAsPrimaryImage(
    String? cityId,
    String? tempKey,
    String imageId,
  );

  Future<Either<Failure, bool>> deleteMultipleImages(List<String> imageIds);

  Future<Either<Failure, List<CityImage>>> uploadMultipleImages({
    String? cityId,
    String? tempKey,
    required List<String> filePaths,
    String? category,
    List<String>? tags,
    void Function(String filePath, int sent, int total)? onProgress,
  });
}
