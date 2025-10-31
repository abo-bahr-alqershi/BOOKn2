import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/unit_type.dart';

abstract class UnitTypesRepository {
  Future<Either<Failure, PaginatedResult<UnitType>>> getUnitTypesByPropertyType({
    required String propertyTypeId,
    required int pageNumber,
    required int pageSize,
  });
  
  Future<Either<Failure, UnitType>> getUnitTypeById(String id);
  
  Future<Either<Failure, String>> createUnitType({
    required String propertyTypeId,
    required String name,
    required int maxCapacity,
    required String icon,
    double? systemCommissionRate,
    required bool isHasAdults,
    required bool isHasChildren,
    required bool isMultiDays,
    required bool isRequiredToDetermineTheHour,
  });
  
  Future<Either<Failure, bool>> updateUnitType({
    required String unitTypeId,
    required String name,
    required int maxCapacity,
    required String icon,
    double? systemCommissionRate,
    required bool isHasAdults,
    required bool isHasChildren,
    required bool isMultiDays,
    required bool isRequiredToDetermineTheHour,
  });
  
  Future<Either<Failure, bool>> deleteUnitType(String unitTypeId);
}