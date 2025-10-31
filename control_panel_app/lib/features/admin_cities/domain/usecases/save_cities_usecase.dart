import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/city.dart';
import '../repositories/cities_repository.dart';

class SaveCitiesUseCase implements UseCase<bool, List<City>> {
  final CitiesRepository repository;

  SaveCitiesUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(List<City> cities) async {
    return await repository.saveCities(cities);
  }
}