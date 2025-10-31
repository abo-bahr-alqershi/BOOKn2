// lib/features/admin_citys/domain/usecases/city_images/upload_city_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/city_image.dart';
import '../../repositories/city_images_repository.dart';

class UploadCityImageUseCase implements UseCase<CityImage, UploadImageParams> {
  final CityImagesRepository repository;

  UploadCityImageUseCase(this.repository);

  @override
  Future<Either<Failure, CityImage>> call(UploadImageParams params) async {
    return await repository.uploadImage(
      cityId: params.cityId,
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

class UploadImageParams {
  final String? cityId;
  final String? tempKey;
  final String filePath;
  final String? category;
  final String? alt;
  final bool isPrimary;
  final int? order;
  final List<String>? tags;
  final void Function(int sent, int total)? onSendProgress;

  UploadImageParams({
    this.cityId,
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
