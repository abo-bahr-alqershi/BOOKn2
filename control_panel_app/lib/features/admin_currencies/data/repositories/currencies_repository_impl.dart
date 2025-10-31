import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/currency.dart';
import '../../domain/repositories/currencies_repository.dart';
import '../datasources/currencies_local_datasource.dart';
import '../datasources/currencies_remote_datasource.dart';
import '../models/currency_model.dart';

class CurrenciesRepositoryImpl implements CurrenciesRepository {
  final CurrenciesRemoteDataSource remoteDataSource;
  final CurrenciesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CurrenciesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Currency>>> getCurrencies() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteCurrencies = await remoteDataSource.getCurrencies();
        await localDataSource.cacheCurrencies(remoteCurrencies);
        return Right(remoteCurrencies);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      try {
        final localCurrencies = await localDataSource.getCachedCurrencies();
        return Right(localCurrencies);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> saveCurrencies(List<Currency> currencies) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // Validation: ensure at most one default currency
      final defaultCount = currencies.where((c) => c.isDefault).length;
      if (defaultCount > 1) {
        return const Left(ServerFailure(
            'لا يمكن حفظ أكثر من عملة افتراضية. الرجاء إلغاء الافتراضية للعملات الأخرى.'));
      }

      final currencyModels = currencies
          .map((c) => CurrencyModel.fromEntity(c))
          .toList();
      
      final result = await remoteDataSource.saveCurrencies(currencyModels);
      
      if (result) {
        await localDataSource.cacheCurrencies(currencyModels);
      }
      
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteCurrency(String code) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.deleteCurrency(code);
      if (result) {
        // Refresh and cache after delete
        final current = await remoteDataSource.getCurrencies();
        await localDataSource.cacheCurrencies(current);
      }
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setDefaultCurrency(String code) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final currentCurrencies = await remoteDataSource.getCurrencies();
      
      // If there is already a default different than requested, allow replacing
      // but ensure only one remains default after update below.
      final updatedCurrencies = currentCurrencies.map((c) {
        return CurrencyModel(
          code: c.code,
          arabicCode: c.arabicCode,
          name: c.name,
          arabicName: c.arabicName,
          isDefault: c.code == code,
          exchangeRate: c.exchangeRate,
          lastUpdated: c.lastUpdated,
        );
      }).toList();
      
      // Extra safety: assert exactly one default
      final defaults = updatedCurrencies.where((c) => c.isDefault).length;
      if (defaults != 1) {
        return const Left(ServerFailure(
            'حالة غير صالحة: يجب أن تكون هناك عملة افتراضية واحدة فقط'));
      }

      final result = await remoteDataSource.saveCurrencies(updatedCurrencies);
      
      if (result) {
        await localDataSource.cacheCurrencies(updatedCurrencies);
      }
      
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCurrencyStats({DateTime? startDate, DateTime? endDate}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
    try {
      final stats = await remoteDataSource.getCurrencyStats(startDate: startDate, endDate: endDate);
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}