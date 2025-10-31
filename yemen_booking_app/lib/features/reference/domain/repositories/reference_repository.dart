import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/city.dart';
import '../entities/currency.dart';

abstract class ReferenceRepository {
  Future<Either<Failure, List<City>>> getCities({bool forceRefresh = false});
  Future<Either<Failure, List<Currency>>> getCurrencies({bool forceRefresh = false});
}

