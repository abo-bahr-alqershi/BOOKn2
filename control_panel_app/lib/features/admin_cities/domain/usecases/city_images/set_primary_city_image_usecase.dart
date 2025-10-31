// lib/features/admin_citys/domain/usecases/city_images/set_primary_city_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/city_images_repository.dart';

class SetPrimaryCityImageUseCase
    implements UseCase<bool, SetPrimaryImageParams> {
  final CityImagesRepository repository;

  SetPrimaryCityImageUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SetPrimaryImageParams params) async {
    return await repository.setAsPrimaryImage(
        params.cityId, params.tempKey, params.imageId);
  }
}

class SetPrimaryImageParams {
  final String? cityId;
  final String? tempKey;
  final String imageId;

  SetPrimaryImageParams({
    this.cityId,
    this.tempKey,
    required this.imageId,
  });
}
