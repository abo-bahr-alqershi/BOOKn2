// lib/features/admin_units/domain/usecases/unit_images/upload_multiple_unit_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/unit_image.dart';
import '../../repositories/unit_images_repository.dart';

class UploadMultipleUnitImagesUseCase implements UseCase<List<UnitImage>, UploadMultipleImagesParams> {
  final UnitImagesRepository repository;

  UploadMultipleUnitImagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<UnitImage>>> call(UploadMultipleImagesParams params) async {
    return await repository.uploadMultipleImages(
      unitId: params.unitId,
      tempKey: params.tempKey,
      filePaths: params.filePaths,
      category: params.category,
      tags: params.tags,
      onProgress: params.onProgress,
    );
  }
}

class UploadMultipleImagesParams {
  final String? unitId;
  final String? tempKey;
  final List<String> filePaths;
  final String? category;
  final List<String>? tags;
  final void Function(String filePath, int sent, int total)? onProgress;

  UploadMultipleImagesParams({
    this.unitId,
    this.tempKey,
    required this.filePaths,
    this.category,
    this.tags,
    this.onProgress,
  });
}