import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/cities_repository.dart';
import '../datasources/cities_local_datasource.dart';
import '../datasources/cities_remote_datasource.dart';
import '../models/city_model.dart';

class CitiesRepositoryImpl implements CitiesRepository {
  final CitiesRemoteDataSource remoteDataSource;
  final CitiesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CitiesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<City>>> getCities({
    int? page,
    int? limit,
    String? search,
    String? country,
    bool? isActive,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // إذا كانت هناك معاملات للصفحات، استخدم الطريقة المُرَقَّمة
        if (page != null && limit != null) {
          final paginatedResult = await remoteDataSource.getCitiesPaginated(
            pageNumber: page,
            pageSize: limit,
            search: search,
            country: country,
            isActive: isActive,
          );
          
          // حفظ في الذاكرة المؤقتة
          await localDataSource.cacheCities(
            paginatedResult.items.map((city) => 
              CityModel.fromEntity(city)
            ).toList(),
          );
          
          return Right(paginatedResult.items);
        } else {
          // إذا لم تكن هناك معاملات صفحات، احصل على جميع المدن
          final remoteCities = await remoteDataSource.getCities();
          
          // حفظ في الذاكرة المؤقتة
          await localDataSource.cacheCities(remoteCities);
          
          // تطبيق الفلاتر محلياً
          List<City> filteredCities = remoteCities;
          
          if (search != null && search.isNotEmpty) {
            filteredCities = filteredCities.where((city) =>
              city.name.toLowerCase().contains(search.toLowerCase()) ||
              city.country.toLowerCase().contains(search.toLowerCase())
            ).toList();
          }
          
          if (country != null && country.isNotEmpty) {
            filteredCities = filteredCities.where((city) =>
              city.country.toLowerCase() == country.toLowerCase()
            ).toList();
          }
          
          if (isActive != null) {
            filteredCities = filteredCities.where((city) =>
              city.isActive == isActive
            ).toList();
          }
          
          return Right(filteredCities);
        }
      } on ApiException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // في حالة عدم وجود اتصال، استخدم البيانات المحفوظة
      try {
        final localCities = await localDataSource.getCachedCities();
        return Right(localCities);
      } catch (e) {
        return const Left(CacheFailure('Failed to load cached cities'));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> saveCities(List<City> cities) async {
    if (await networkInfo.isConnected) {
      try {
        final cityModels = cities
            .map((city) => CityModel.fromEntity(city))
            .toList();
        final result = await remoteDataSource.saveCities(cityModels);
        
        // تحديث الذاكرة المؤقتة
        await localDataSource.cacheCities(cityModels);
        
        return Right(result);
      } on ApiException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, City>> createCity(City city) async {
    if (await networkInfo.isConnected) {
      try {
        final cityModel = CityModel.fromEntity(city);
        final cityId = await remoteDataSource.createCity(cityModel);
        
        // إنشاء المدينة مع المعرف المُرجع
        final createdCity = city.copyWith(name: cityId.isNotEmpty ? cityId : city.name);
        
        // مسح الذاكرة المؤقتة لفرض التحديث
        await localDataSource.clearCache();
        
        return Right(createdCity);
      } on ApiException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, City>> updateCity(String oldName, City city) async {
    if (await networkInfo.isConnected) {
      try {
        final cityModel = CityModel.fromEntity(city);
        final success = await remoteDataSource.updateCity(oldName, cityModel);
        
        if (success) {
          // مسح الذاكرة المؤقتة لفرض التحديث
          await localDataSource.clearCache();
          return Right(city);
        } else {
          return const Left(ServerFailure('Failed to update city'));
        }
      } on ApiException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteCity(String name) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteCity(name);
        
        if (result) {
          // مسح الذاكرة المؤقتة لفرض التحديث
          await localDataSource.clearCache();
        }
        
        return Right(result);
      } on ApiException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<City>>> searchCities(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.searchCities(query);
        return Right(result);
      } on ApiException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // البحث في البيانات المحفوظة
      try {
        final cachedCities = await localDataSource.getCachedCities();
        final filteredCities = cachedCities.where((city) =>
          city.name.toLowerCase().contains(query.toLowerCase()) ||
          city.country.toLowerCase().contains(query.toLowerCase())
        ).toList();
        return Right(filteredCities);
      } catch (e) {
        return const Left(CacheFailure('Failed to search in cached cities'));
      }
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCitiesStatistics({DateTime? startDate, DateTime? endDate}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCitiesStatistics(startDate: startDate, endDate: endDate);
        return Right(result);
      } on ApiException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadCityImage(String cityName, String imagePath, {ProgressCallback? onSendProgress}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.uploadCityImage(cityName, imagePath, onSendProgress: onSendProgress);
        return Right(result);
      } on ApiException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteCityImage(String imageUrl) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteCityImage(imageUrl);
        return Right(result);
      } on ApiException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}