import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/unit_type_field.dart';
import '../../repositories/unit_type_fields_repository.dart';

class GetFieldsByUnitTypeUseCase 
    implements UseCase<List<UnitTypeField>, GetFieldsByUnitTypeParams> {
  final UnitTypeFieldsRepository repository;

  GetFieldsByUnitTypeUseCase(this.repository);

  @override
  Future<Either<Failure, List<UnitTypeField>>> call(
    GetFieldsByUnitTypeParams params,
  ) async {
    return await repository.getFieldsByUnitType(
      unitTypeId: params.unitTypeId,
      searchTerm: params.searchTerm,
      isActive: params.isActive,
      isSearchable: params.isSearchable,
      isPublic: params.isPublic,
      isForUnits: params.isForUnits,
      category: params.category,
    );
  }
}

class GetFieldsByUnitTypeParams extends Equatable {
  final String unitTypeId;
  final String? searchTerm;
  final bool? isActive;
  final bool? isSearchable;
  final bool? isPublic;
  final bool? isForUnits;
  final String? category;

  const GetFieldsByUnitTypeParams({
    required this.unitTypeId,
    this.searchTerm,
    this.isActive,
    this.isSearchable,
    this.isPublic,
    this.isForUnits,
    this.category,
  });

  @override
  List<Object?> get props => [
        unitTypeId,
        searchTerm,
        isActive,
        isSearchable,
        isPublic,
        isForUnits,
        category,
      ];
}