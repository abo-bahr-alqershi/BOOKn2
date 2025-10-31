import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/currencies_repository.dart';

class SetDefaultCurrencyUseCase extends UseCase<bool, SetDefaultCurrencyParams> {
  final CurrenciesRepository repository;

  SetDefaultCurrencyUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SetDefaultCurrencyParams params) async {
    return await repository.setDefaultCurrency(params.code);
  }
}

class SetDefaultCurrencyParams extends Equatable {
  final String code;

  const SetDefaultCurrencyParams({required this.code});

  @override
  List<Object> get props => [code];
}