// lib/features/admin_properties/domain/usecases/property_images/set_primary_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/property_images_repository.dart';

class SetPrimaryImageUseCase implements UseCase<bool, SetPrimaryImageParams> {
  final PropertyImagesRepository repository;

  SetPrimaryImageUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SetPrimaryImageParams params) async {
    return await repository.setAsPrimaryImage(params.propertyId, params.tempKey, params.imageId);
  }
}

class SetPrimaryImageParams {
  final String? propertyId;
  final String? tempKey;
  final String imageId;

  SetPrimaryImageParams({
    this.propertyId,
    this.tempKey,
    required this.imageId,
  });
}