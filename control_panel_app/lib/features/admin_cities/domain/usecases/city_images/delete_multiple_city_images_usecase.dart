// lib/features/admin_citys/domain/usecases/city_images/delete_multiple_city_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/city_images_repository.dart';

class DeleteMultipleCityImagesUseCase implements UseCase<bool, List<String>> {
  final CityImagesRepository repository;

  DeleteMultipleCityImagesUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(List<String> imageIds) async {
    return await repository.deleteMultipleImages(imageIds);
  }
}
