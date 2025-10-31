import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/city.dart';
import '../repositories/cities_repository.dart';

class CreateCityUseCase implements UseCase<City, City> {
  final CitiesRepository repository;

  CreateCityUseCase(this.repository);

  @override
  Future<Either<Failure, City>> call(City city) async {
    return await repository.createCity(city);
  }
}