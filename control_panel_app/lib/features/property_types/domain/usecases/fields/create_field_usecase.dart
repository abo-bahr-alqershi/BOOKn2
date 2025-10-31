import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/unit_type_fields_repository.dart';

class CreateFieldUseCase implements UseCase<String, CreateFieldParams> {
  final UnitTypeFieldsRepository repository;

  CreateFieldUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateFieldParams params) async {
    return await repository.createField(
      unitTypeId: params.unitTypeId,
      fieldTypeId: params.fieldTypeId,
      fieldName: params.fieldName,
      displayName: params.displayName,
      description: params.description,
      fieldOptions: params.fieldOptions,
      validationRules: params.validationRules,
      isRequired: params.isRequired,
      isSearchable: params.isSearchable,
      isPublic: params.isPublic,
      sortOrder: params.sortOrder,
      category: params.category,
      isForUnits: params.isForUnits,
      groupId: params.groupId,
      showInCards: params.showInCards,
      isPrimaryFilter: params.isPrimaryFilter,
      priority: params.priority,
    );
  }
}

class CreateFieldParams extends Equatable {
  final String unitTypeId;
  final String fieldTypeId;
  final String fieldName;
  final String displayName;
  final String? description;
  final Map<String, dynamic>? fieldOptions;
  final Map<String, dynamic>? validationRules;
  final bool isRequired;
  final bool isSearchable;
  final bool isPublic;
  final int sortOrder;
  final String? category;
  final bool isForUnits;
  final String? groupId;
  final bool showInCards;
  final bool isPrimaryFilter;
  final int priority;

  const CreateFieldParams({
    required this.unitTypeId,
    required this.fieldTypeId,
    required this.fieldName,
    required this.displayName,
    this.description,
    this.fieldOptions,
    this.validationRules,
    required this.isRequired,
    required this.isSearchable,
    required this.isPublic,
    required this.sortOrder,
    this.category,
    required this.isForUnits,
    this.groupId,
    required this.showInCards,
    required this.isPrimaryFilter,
    required this.priority,
  });

  @override
  List<Object?> get props => [
        unitTypeId,
        fieldTypeId,
        fieldName,
        displayName,
        description,
        fieldOptions,
        validationRules,
        isRequired,
        isSearchable,
        isPublic,
        sortOrder,
        category,
        isForUnits,
        groupId,
        showInCards,
        isPrimaryFilter,
        priority,
      ];
}