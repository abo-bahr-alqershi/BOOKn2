import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/unit_type_field.dart';

abstract class UnitTypeFieldsRepository {
  Future<Either<Failure, List<UnitTypeField>>> getFieldsByUnitType({
    required String unitTypeId,
    String? searchTerm,
    bool? isActive,
    bool? isSearchable,
    bool? isPublic,
    bool? isForUnits,
    String? category,
  });
  
  Future<Either<Failure, UnitTypeField>> getFieldById(String fieldId);
  
  Future<Either<Failure, String>> createField({
    required String unitTypeId,
    required String fieldTypeId,
    required String fieldName,
    required String displayName,
    String? description,
    Map<String, dynamic>? fieldOptions,
    Map<String, dynamic>? validationRules,
    required bool isRequired,
    required bool isSearchable,
    required bool isPublic,
    required int sortOrder,
    String? category,
    required bool isForUnits,
    String? groupId,
    required bool showInCards,
    required bool isPrimaryFilter,
    required int priority,
  });
  
  Future<Either<Failure, bool>> updateField({
    required String fieldId,
    String? fieldTypeId,
    String? fieldName,
    String? displayName,
    String? description,
    Map<String, dynamic>? fieldOptions,
    Map<String, dynamic>? validationRules,
    bool? isRequired,
    bool? isSearchable,
    bool? isPublic,
    int? sortOrder,
    String? category,
    bool? isForUnits,
    String? groupId,
    bool? showInCards,
    bool? isPrimaryFilter,
    int? priority,
  });
  
  Future<Either<Failure, bool>> deleteField(String fieldId);
}