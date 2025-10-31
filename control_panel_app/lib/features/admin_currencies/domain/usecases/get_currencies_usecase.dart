import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/currency.dart';
import '../repositories/currencies_repository.dart';

class GetCurrenciesUseCase extends UseCase<List<Currency>, NoParams> {
  final CurrenciesRepository repository;

  GetCurrenciesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Currency>>> call(NoParams params) async {
    return await repository.getCurrencies();
  }
}