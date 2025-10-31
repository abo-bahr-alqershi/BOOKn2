import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/unit_type_field.dart';
import '../../domain/repositories/unit_type_fields_repository.dart';
import '../datasources/unit_type_fields_remote_datasource.dart';

class UnitTypeFieldsRepositoryImpl implements UnitTypeFieldsRepository {
  final UnitTypeFieldsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UnitTypeFieldsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<UnitTypeField>>> getFieldsByUnitType({
    required String unitTypeId,
    String? searchTerm,
    bool? isActive,
    bool? isSearchable,
    bool? isPublic,
    bool? isForUnits,
    String? category,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getFieldsByUnitType(
          unitTypeId: unitTypeId,
          searchTerm: searchTerm,
          isActive: isActive,
          isSearchable: isSearchable,
          isPublic: isPublic,
          isForUnits: isForUnits,
          category: category,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UnitTypeField>> getFieldById(String fieldId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getFieldById(fieldId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
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
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.createField(
          unitTypeId: unitTypeId,
          fieldTypeId: fieldTypeId,
          fieldName: fieldName,
          displayName: displayName,
          description: description,
          fieldOptions: fieldOptions,
          validationRules: validationRules,
          isRequired: isRequired,
          isSearchable: isSearchable,
          isPublic: isPublic,
          sortOrder: sortOrder,
          category: category,
          isForUnits: isForUnits,
          groupId: groupId,
          showInCards: showInCards,
          isPrimaryFilter: isPrimaryFilter,
          priority: priority,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
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
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateField(
          fieldId: fieldId,
          fieldTypeId: fieldTypeId,
          fieldName: fieldName,
          displayName: displayName,
          description: description,
          fieldOptions: fieldOptions,
          validationRules: validationRules,
          isRequired: isRequired,
          isSearchable: isSearchable,
          isPublic: isPublic,
          sortOrder: sortOrder,
          category: category,
          isForUnits: isForUnits,
          groupId: groupId,
          showInCards: showInCards,
          isPrimaryFilter: isPrimaryFilter,
          priority: priority,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteField(String fieldId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteField(fieldId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}