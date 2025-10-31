// lib/features/admin_properties/domain/usecases/property_images/reorder_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/property_images_repository.dart';

class ReorderImagesUseCase implements UseCase<bool, ReorderImagesParams> {
  final PropertyImagesRepository repository;

  ReorderImagesUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ReorderImagesParams params) async {
    return await repository.reorderImages(params.propertyId, params.tempKey, params.imageIds);
  }
}

class ReorderImagesParams {
  final String? propertyId;
  final String? tempKey;
  final List<String> imageIds;

  ReorderImagesParams({
    this.propertyId,
    this.tempKey,
    required this.imageIds,
  });
}