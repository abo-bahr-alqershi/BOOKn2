// lib/features/admin_citys/domain/usecases/city_images/update_city_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/city_images_repository.dart';

class UpdateCityImageUseCase implements UseCase<bool, UpdateImageParams> {
  final CityImagesRepository repository;

  UpdateCityImageUseCase(this.repository);

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
