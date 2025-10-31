import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/city.dart';
import '../repositories/cities_repository.dart';

class SearchCitiesUseCase implements UseCase<List<City>, String> {
  final CitiesRepository repository;

  SearchCitiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<City>>> call(String query) async {
    return await repository.searchCities(query);
  }
}