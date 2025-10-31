// lib/features/admin_units/domain/usecases/unit_images/upload_unit_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/unit_image.dart';
import '../../repositories/unit_images_repository.dart';

class UploadUnitImageUseCase implements UseCase<UnitImage, UploadImageParams> {
  final UnitImagesRepository repository;

  UploadUnitImageUseCase(this.repository);

  @override
  Future<Either<Failure, UnitImage>> call(UploadImageParams params) async {
    return await repository.uploadImage(
      unitId: params.unitId,
      sectionId: params.sectionId,
      unitInSectionId: params.unitInSectionId,
      tempKey: params.tempKey,
      filePath: params.filePath,
      videoThumbnailPath: params.videoThumbnailPath,
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
  final String? unitId;
  final String? sectionId;
  final String? unitInSectionId;
  final String? tempKey;
  final String filePath;
  final String? videoThumbnailPath;
  final String? category;
  final String? alt;
  final bool isPrimary;
  final int? order;
  final List<String>? tags;
  final void Function(int sent, int total)? onSendProgress;

  UploadImageParams({
    this.unitId,
    this.sectionId,
    this.unitInSectionId,
    this.tempKey,
    required this.filePath,
    this.videoThumbnailPath,
    this.category,
    this.alt,
    this.isPrimary = false,
    this.order,
    this.tags,
    this.onSendProgress,
  });
}