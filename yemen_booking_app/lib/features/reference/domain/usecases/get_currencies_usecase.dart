import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/currency.dart';
import '../repositories/reference_repository.dart';

class GetCurrenciesUseCase implements UseCase<List<Currency>, NoParams> {
  final ReferenceRepository repository;
  GetCurrenciesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Currency>>> call(NoParams params) {
    return repository.getCurrencies();
  }
}

