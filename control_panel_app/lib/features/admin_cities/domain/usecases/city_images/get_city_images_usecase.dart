// lib/features/admin_citys/domain/usecases/city_images/get_city_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/city_image.dart';
import '../../repositories/city_images_repository.dart';

class GetCityImagesUseCase
    implements UseCase<List<CityImage>, GetCityImagesParams> {
  final CityImagesRepository repository;

  GetCityImagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CityImage>>> call(
      GetCityImagesParams params) async {
    return await repository.getCityImages(params.cityId,
        tempKey: params.tempKey);
  }
}

class GetCityImagesParams {
  final String? cityId;
  final String? tempKey;

  GetCityImagesParams({this.cityId, this.tempKey});
}
