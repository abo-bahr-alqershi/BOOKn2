import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/currency.dart';

abstract class CurrenciesRepository {
  Future<Either<Failure, List<Currency>>> getCurrencies();
  Future<Either<Failure, bool>> saveCurrencies(List<Currency> currencies);
  Future<Either<Failure, bool>> deleteCurrency(String code);
  Future<Either<Failure, bool>> setDefaultCurrency(String code);
  Future<Either<Failure, Map<String, dynamic>>> getCurrencyStats({DateTime? startDate, DateTime? endDate});
}