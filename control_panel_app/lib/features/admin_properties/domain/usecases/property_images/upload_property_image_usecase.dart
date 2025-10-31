// lib/features/admin_properties/domain/usecases/property_images/upload_property_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/property_image.dart';
import '../../repositories/property_images_repository.dart';

class UploadPropertyImageUseCase
    implements UseCase<PropertyImage, UploadImageParams> {
  final PropertyImagesRepository repository;

  UploadPropertyImageUseCase(this.repository);

  @override
  Future<Either<Failure, PropertyImage>> call(UploadImageParams params) async {
    return await repository.uploadImage(
      propertyId: params.propertyId,
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
  final String? propertyId;
  final String? tempKey;
  final String filePath;
  final String? category;
  final String? alt;
  final bool isPrimary;
  final int? order;
  final List<String>? tags;
  final void Function(int sent, int total)? onSendProgress;

  UploadImageParams({
    this.propertyId,
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
