// lib/features/admin_citys/domain/usecases/city_images/delete_city_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/city_images_repository.dart';

class DeleteCityImageUseCase implements UseCase<bool, String> {
  final CityImagesRepository repository;

  DeleteCityImageUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String imageId) async {
    return await repository.deleteImage(imageId);
  }
}
