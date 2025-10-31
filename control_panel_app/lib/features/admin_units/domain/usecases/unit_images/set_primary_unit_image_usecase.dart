// lib/features/admin_units/domain/usecases/unit_images/set_primary_unit_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/unit_images_repository.dart';

class SetPrimaryUnitImageUseCase implements UseCase<bool, SetPrimaryImageParams> {
  final UnitImagesRepository repository;

  SetPrimaryUnitImageUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SetPrimaryImageParams params) async {
    return await repository.setAsPrimaryImage(params.unitId, params.tempKey, params.imageId);
  }
}

class SetPrimaryImageParams {
  final String? unitId;
  final String? tempKey;
  final String imageId;

  SetPrimaryImageParams({
    this.unitId,
    this.tempKey,
    required this.imageId,
  });
}