import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/cities_repository.dart';

class UploadCityImageUseCase implements UseCase<String, UploadCityImageParams> {
  final CitiesRepository repository;

  UploadCityImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadCityImageParams params) async {
    return await repository.uploadCityImage(
      params.cityName,
      params.imagePath,
      onSendProgress: params.onSendProgress,
    );
  }
}

class UploadCityImageParams extends Equatable {
  final String cityName;
  final String imagePath;
  final ProgressCallback? onSendProgress;

  const UploadCityImageParams({
    required this.cityName,
    required this.imagePath,
    this.onSendProgress,
  });

  @override
  List<Object?> get props => [cityName, imagePath, onSendProgress];
}