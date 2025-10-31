import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/cities_repository.dart';

class DeleteCityImageUseCase implements UseCase<bool, DeleteCityImageParams> {
  final CitiesRepository repository;

  DeleteCityImageUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteCityImageParams params) async {
    return await repository.deleteCityImage(params.imageUrl);
  }
}

class DeleteCityImageParams extends Equatable {
  final String cityName;
  final String imageUrl;

  const DeleteCityImageParams({
    required this.cityName,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [cityName, imageUrl];
}