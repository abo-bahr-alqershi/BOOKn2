import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/city.dart';
import '../repositories/reference_repository.dart';

class GetCitiesUseCase implements UseCase<List<City>, NoParams> {
  final ReferenceRepository repository;
  GetCitiesUseCase(this.repository);
  @override
  Future<Either<Failure, List<City>>> call(NoParams params) {
    return repository.getCities();
  }
}

