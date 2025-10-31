// lib/features/admin_citys/domain/usecases/city_images/reorder_city_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/city_images_repository.dart';

class ReorderCityImagesUseCase implements UseCase<bool, ReorderImagesParams> {
  final CityImagesRepository repository;

  ReorderCityImagesUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ReorderImagesParams params) async {
    return await repository.reorderImages(
        params.cityId, params.tempKey, params.imageIds);
  }
}

class ReorderImagesParams {
  final String? cityId;
  final String? tempKey;
  final List<String> imageIds;

  ReorderImagesParams({
    this.cityId,
    this.tempKey,
    required this.imageIds,
  });
}
