import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/city.dart';
import '../repositories/cities_repository.dart';

class UpdateCityUseCase implements UseCase<City, UpdateCityParams> {
  final CitiesRepository repository;

  UpdateCityUseCase(this.repository);

  @override
  Future<Either<Failure, City>> call(UpdateCityParams params) async {
    return await repository.updateCity(params.oldName, params.city);
  }
}

class UpdateCityParams extends Equatable {
  final String oldName;
  final City city;

  const UpdateCityParams({
    required this.oldName,
    required this.city,
  });

  @override
  List<Object?> get props => [oldName, city];
}