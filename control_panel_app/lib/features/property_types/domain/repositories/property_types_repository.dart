import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/property_type.dart';

abstract class PropertyTypesRepository {
  Future<Either<Failure, PaginatedResult<PropertyType>>> getAllPropertyTypes({
    required int pageNumber,
    required int pageSize,
  });
  
  Future<Either<Failure, PropertyType>> getPropertyTypeById(String id);
  
  Future<Either<Failure, String>> createPropertyType({
    required String name,
    required String description,
    required List<String> defaultAmenities,
    required String icon,
  });
  
  Future<Either<Failure, bool>> updatePropertyType({
    required String propertyTypeId,
    required String name,
    required String description,
    required List<String> defaultAmenities,
    required String icon,
  });
  
  Future<Either<Failure, bool>> deletePropertyType(String propertyTypeId);
}