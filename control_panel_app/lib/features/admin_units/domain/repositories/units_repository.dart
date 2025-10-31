import 'package:dartz/dartz.dart' hide Unit;
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';
import '../entities/unit.dart';
import '../entities/unit_type.dart';
import '../entities/unit_field_value.dart';

abstract class UnitsRepository {
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
  });

  Future<Either<Failure, Unit>> getUnitDetails(String unitId);

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
  });

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
  });

  Future<Either<Failure, bool>> deleteUnit(String unitId);

  Future<Either<Failure, List<UnitType>>> getUnitTypesByProperty(String propertyTypeId);

  Future<Either<Failure, List<UnitTypeField>>> getUnitFields(String unitTypeId);

  Future<Either<Failure, bool>> assignUnitToSections(
    String unitId,
    List<String> sectionIds,
  );
}