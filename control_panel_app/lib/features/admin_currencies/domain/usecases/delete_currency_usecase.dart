import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/currencies_repository.dart';

class DeleteCurrencyUseCase extends UseCase<bool, DeleteCurrencyParams> {
  final CurrenciesRepository repository;

  DeleteCurrencyUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteCurrencyParams params) async {
    return await repository.deleteCurrency(params.code);
  }
}

class DeleteCurrencyParams extends Equatable {
  final String code;

  const DeleteCurrencyParams({required this.code});

  @override
  List<Object> get props => [code];
}