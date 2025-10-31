import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/cities_repository.dart';

class DeleteCityUseCase implements UseCase<bool, String> {
  final CitiesRepository repository;

  DeleteCityUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String name) async {
    return await repository.deleteCity(name);
  }
}