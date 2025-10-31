// lib/features/admin_units/domain/usecases/unit_images/reorder_unit_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/unit_images_repository.dart';

class ReorderUnitImagesUseCase implements UseCase<bool, ReorderImagesParams> {
  final UnitImagesRepository repository;

  ReorderUnitImagesUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ReorderImagesParams params) async {
    return await repository.reorderImages(params.unitId, params.tempKey, params.imageIds);
  }
}

class ReorderImagesParams {
  final String? unitId;
  final String? tempKey;
  final List<String> imageIds;

  ReorderImagesParams({
    this.unitId,
    this.tempKey,
    required this.imageIds,
  });
}