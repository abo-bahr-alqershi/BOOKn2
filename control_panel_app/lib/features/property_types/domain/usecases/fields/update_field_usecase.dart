import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/unit_type_fields_repository.dart';

class UpdateFieldUseCase implements UseCase<bool, UpdateFieldParams> {
  final UnitTypeFieldsRepository repository;

  UpdateFieldUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateFieldParams params) async {
    return await repository.updateField(
      fieldId: params.fieldId,
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

class UpdateFieldParams extends Equatable {
  final String fieldId;
  final String? fieldTypeId;
  final String? fieldName;
  final String? displayName;
  final String? description;
  final Map<String, dynamic>? fieldOptions;
  final Map<String, dynamic>? validationRules;
  final bool? isRequired;
  final bool? isSearchable;
  final bool? isPublic;
  final int? sortOrder;
  final String? category;
  final bool? isForUnits;
  final String? groupId;
  final bool? showInCards;
  final bool? isPrimaryFilter;
  final int? priority;

  const UpdateFieldParams({
    required this.fieldId,
    this.fieldTypeId,
    this.fieldName,
    this.displayName,
    this.description,
    this.fieldOptions,
    this.validationRules,
    this.isRequired,
    this.isSearchable,
    this.isPublic,
    this.sortOrder,
    this.category,
    this.isForUnits,
    this.groupId,
    this.showInCards,
    this.isPrimaryFilter,
    this.priority,
  });

  @override
  List<Object?> get props => [
        fieldId,
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