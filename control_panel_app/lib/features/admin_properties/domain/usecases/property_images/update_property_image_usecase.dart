// lib/features/admin_properties/domain/usecases/property_images/update_property_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/property_images_repository.dart';

class UpdatePropertyImageUseCase implements UseCase<bool, UpdateImageParams> {
  final PropertyImagesRepository repository;

  UpdatePropertyImageUseCase(this.repository);

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