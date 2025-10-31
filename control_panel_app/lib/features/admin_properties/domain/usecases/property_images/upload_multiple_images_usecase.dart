// lib/features/admin_properties/domain/usecases/property_images/upload_multiple_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/property_image.dart';
import '../../repositories/property_images_repository.dart';

class UploadMultipleImagesUseCase implements UseCase<List<PropertyImage>, UploadMultipleImagesParams> {
  final PropertyImagesRepository repository;

  UploadMultipleImagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PropertyImage>>> call(UploadMultipleImagesParams params) async {
    return await repository.uploadMultipleImages(
      propertyId: params.propertyId,
      tempKey: params.tempKey,
      filePaths: params.filePaths,
      category: params.category,
      tags: params.tags,
      onProgress: params.onProgress,
    );
  }
}

class UploadMultipleImagesParams {
  final String? propertyId;
  final String? tempKey;
  final List<String> filePaths;
  final String? category;
  final List<String>? tags;
  final void Function(String filePath, int sent, int total)? onProgress;

  UploadMultipleImagesParams({
    this.propertyId,
    this.tempKey,
    required this.filePaths,
    this.category,
    this.tags,
    this.onProgress,
  });
}