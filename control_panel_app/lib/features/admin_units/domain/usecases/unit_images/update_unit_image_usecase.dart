// lib/features/admin_units/domain/usecases/unit_images/update_unit_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/unit_images_repository.dart';

class UpdateUnitImageUseCase implements UseCase<bool, UpdateImageParams> {
  final UnitImagesRepository repository;

  UpdateUnitImageUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateImageParams params) async {
    return await repository.updateImage(params.imageId, params.data);
  }
}

class UpdateImageParams {
  final String imageId;
  final Map<String, dynamic> data;

  UpdateImageParams({
    required this.imageId,
    required this.data,
  });
}