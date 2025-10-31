import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/currency.dart';
import '../repositories/currencies_repository.dart';

class SaveCurrenciesUseCase extends UseCase<bool, SaveCurrenciesParams> {
  final CurrenciesRepository repository;

  SaveCurrenciesUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SaveCurrenciesParams params) async {
    return await repository.saveCurrencies(params.currencies);
  }
}

class SaveCurrenciesParams extends Equatable {
  final List<Currency> currencies;

  const SaveCurrenciesParams({required this.currencies});

  @override
  List<Object> get props => [currencies];
}