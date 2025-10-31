// lib/features/admin_properties/domain/usecases/property_images/delete_property_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/property_images_repository.dart';

class DeletePropertyImageUseCase implements UseCase<bool, String> {
  final PropertyImagesRepository repository;

  DeletePropertyImageUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String imageId) async {
    return await repository.deleteImage(imageId);
  }
}