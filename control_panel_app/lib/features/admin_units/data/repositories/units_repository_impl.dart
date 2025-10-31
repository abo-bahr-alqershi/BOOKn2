import 'package:dartz/dartz.dart' hide Unit;
import 'package:dio/dio.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../domain/entities/unit.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../domain/entities/unit_type.dart';
import '../../domain/repositories/units_repository.dart';
import '../datasources/units_local_datasource.dart';
import '../datasources/units_remote_datasource.dart';

class UnitsRepositoryImpl implements UnitsRepository {
  final UnitsRemoteDataSource remoteDataSource;
  final UnitsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UnitsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PaginatedResult<Unit>>> getUnits({
    int? pageNumber,
    int? pageSize,
    String? propertyId,
    String? unitTypeId,
    bool? isAvailable,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    String? pricingMethod,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? numberOfGuests,
    bool? hasActiveBookings,
    String? location,
    String? sortBy,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUnits = await remoteDataSource.getUnits(
          pageNumber: pageNumber,
          pageSize: pageSize,
          propertyId: propertyId,
          unitTypeId: unitTypeId,
          isAvailable: isAvailable,
          minPrice: minPrice,
          maxPrice: maxPrice,
          searchQuery: searchQuery,
          pricingMethod: pricingMethod,
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
          numberOfGuests: numberOfGuests,
          hasActiveBookings: hasActiveBookings,
          location: location,
          sortBy: sortBy,
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
        );
        await localDataSource.cacheUnits(remoteUnits.items);

        final units = remoteUnits.items.map<Unit>((unit) => unit).toList();

        return Right(PaginatedResult<Unit>(
          items: units,
          pageNumber: remoteUnits.pageNumber,
          pageSize: remoteUnits.pageSize,
          totalCount: remoteUnits.totalCount,
          metadata: remoteUnits.metadata,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on DioException catch (e) {
        return Left(ServerFailure(e.message ?? 'حدث خطأ في الاتصال'));
      } catch (e) {
        return const Left(ServerFailure('حدث خطأ غير متوقع'));
      }
    } else {
      try {
        final localUnits = await localDataSource.getCachedUnits();
        final units = localUnits.map<Unit>((unit) => unit).toList();
        return Right(PaginatedResult<Unit>(
          items: units,
          pageNumber: 1,
          pageSize: units.length,
          totalCount: units.length,
        ));
      } on CacheException {
        return const Left(CacheFailure('لا توجد بيانات محفوظة'));
      }
    }
  }

  @override
  Future<Either<Failure, Unit>> getUnitDetails(String unitId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUnit = await remoteDataSource.getUnitDetails(unitId);
        await localDataSource.cacheUnit(remoteUnit);
        return Right(remoteUnit);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final localUnit = await localDataSource.getCachedUnit(unitId);
        if (localUnit != null) {
          return Right(localUnit);
        } else {
          return const Left(CacheFailure('لا توجد بيانات محفوظة'));
        }
      } on CacheException {
        return const Left(CacheFailure('لا توجد بيانات محفوظة'));
      }
    }
  }

  @override
  Future<Either<Failure, String>> createUnit({
    required String propertyId,
    required String unitTypeId,
    required String name,
    required String description,
    required Map<String, dynamic> basePrice,
    required String customFeatures,
    required String pricingMethod,
    List<Map<String, dynamic>>? fieldValues,
    List<String>? images,
    int? adultCapacity,
    int? childrenCapacity,
    bool? allowsCancellation,
    int? cancellationWindowDays,
    String? tempKey,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Backend expects a flat body matching CreateUnitCommand, not wrapped in a 'command' object
        final unitData = {
          'propertyId': propertyId,
          'unitTypeId': unitTypeId,
          'name': name,
          'basePrice': basePrice,
          'customFeatures': customFeatures,
          'pricingMethod': pricingMethod,
          'fieldValues': _convertFieldValuesToString(fieldValues),
          'images': images ?? [],
          if (tempKey != null && tempKey.isNotEmpty) 'tempKey': tempKey,
          if (adultCapacity != null) 'adultCapacity': adultCapacity,
          if (childrenCapacity != null) 'childrenCapacity': childrenCapacity,
          if (allowsCancellation != null)
            'allowsCancellation': allowsCancellation,
          if (cancellationWindowDays != null)
            'cancellationWindowDays': cancellationWindowDays,
        };
        final unitId = await remoteDataSource.createUnit(unitData);
        return Right(unitId);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateUnit({
    required String unitId,
    String? name,
    String? description,
    Map<String, dynamic>? basePrice,
    String? customFeatures,
    String? pricingMethod,
    List<Map<String, dynamic>>? fieldValues,
    List<String>? images,
    int? adultCapacity,
    int? childrenCapacity,
    bool? allowsCancellation,
    int? cancellationWindowDays,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final unitData = {
          if (name != null) 'name': name,
          if (basePrice != null) 'basePrice': basePrice,
          if (customFeatures != null) 'customFeatures': customFeatures,
          if (pricingMethod != null) 'pricingMethod': pricingMethod,
          if (fieldValues != null)
            'fieldValues': _convertFieldValuesToString(fieldValues),
          if (images != null) 'images': images,
          if (allowsCancellation != null)
            'allowsCancellation': allowsCancellation,
          // Always include cancellationWindowDays when allowsCancellation is explicitly true or when days is provided
          if ((allowsCancellation ?? false) && cancellationWindowDays == null)
            'cancellationWindowDays': null,
          if (cancellationWindowDays != null)
            'cancellationWindowDays': cancellationWindowDays,
        };
        final result = await remoteDataSource.updateUnit(unitId, unitData);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUnit(String unitId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteUnit(unitId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, List<UnitType>>> getUnitTypesByProperty(
    String propertyTypeId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final unitTypes =
            await remoteDataSource.getUnitTypesByProperty(propertyTypeId);
        return Right(unitTypes);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, List<UnitTypeField>>> getUnitFields(
      String unitTypeId) async {
    if (await networkInfo.isConnected) {
      try {
        final fields = await remoteDataSource.getUnitFields(unitTypeId);
        return Right(fields);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, bool>> assignUnitToSections(
    String unitId,
    List<String> sectionIds,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result =
            await remoteDataSource.assignUnitToSections(unitId, sectionIds);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  /// تحويل قيم الحقول إلى string كما يتوقعها Backend
  List<Map<String, dynamic>> _convertFieldValuesToString(
      List<Map<String, dynamic>>? fieldValues) {
    if (fieldValues == null) return [];

    return fieldValues.map((field) {
      return {
        'fieldId': field['fieldId'],
        'fieldValue': field['fieldValue']?.toString() ?? '',
      };
    }).toList();
  }
}
