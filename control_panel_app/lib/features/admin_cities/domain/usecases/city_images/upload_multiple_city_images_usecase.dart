// lib/features/admin_citys/domain/usecases/city_images/upload_multiple_city_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/city_image.dart';
import '../../repositories/city_images_repository.dart';

class UploadMultipleCityImagesUseCase
    implements UseCase<List<CityImage>, UploadMultipleImagesParams> {
  final CityImagesRepository repository;

  UploadMultipleCityImagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CityImage>>> call(
      UploadMultipleImagesParams params) async {
    return await repository.uploadMultipleImages(
      cityId: params.cityId,
      tempKey: params.tempKey,
      filePaths: params.filePaths,
      category: params.category,
      tags: params.tags,
      onProgress: params.onProgress,
    );
  }
}

class UploadMultipleImagesParams {
  final String? cityId;
  final String? tempKey;
  final List<String> filePaths;
  final String? category;
  final List<String>? tags;
  final void Function(String filePath, int sent, int total)? onProgress;

  UploadMultipleImagesParams({
    this.cityId,
    this.tempKey,
    required this.filePaths,
    this.category,
    this.tags,
    this.onProgress,
  });
}
