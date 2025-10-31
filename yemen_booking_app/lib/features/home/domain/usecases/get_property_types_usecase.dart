import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/property_type.dart';
import '../repositories/home_repository.dart';

class GetPropertyTypesUseCase implements UseCase<List<PropertyType>, NoParams> {
  final HomeRepository repository;

  GetPropertyTypesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PropertyType>>> call(NoParams params) async {
    return repository.getPropertyTypes();
  }
}