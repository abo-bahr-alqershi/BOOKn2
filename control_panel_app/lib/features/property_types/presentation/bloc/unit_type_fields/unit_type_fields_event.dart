import 'package:equatable/equatable.dart';

abstract class UnitTypeFieldsEvent extends Equatable {
  const UnitTypeFieldsEvent();

  @override
  List<Object?> get props => [];
}

class LoadUnitTypeFieldsEvent extends UnitTypeFieldsEvent {
  final String unitTypeId;

  const LoadUnitTypeFieldsEvent({required this.unitTypeId});

  @override
  List<Object> get props => [unitTypeId];
}

class SearchFieldsEvent extends UnitTypeFieldsEvent {
  final String searchTerm;

  const SearchFieldsEvent({required this.searchTerm});

  @override
  List<Object> get props => [searchTerm];
}

class CreateFieldEvent extends UnitTypeFieldsEvent {
  final String unitTypeId;
  final Map<String, dynamic> fieldData;

  const CreateFieldEvent({
    required this.unitTypeId,
    required this.fieldData,
  });

  @override
  List<Object> get props => [unitTypeId, fieldData];
}

class UpdateFieldEvent extends UnitTypeFieldsEvent {
  final String fieldId;
  final Map<String, dynamic> fieldData;

  const UpdateFieldEvent({
    required this.fieldId,
    required this.fieldData,
  });

  @override
  List<Object> get props => [fieldId, fieldData];
}

class DeleteFieldEvent extends UnitTypeFieldsEvent {
  final String fieldId;

  const DeleteFieldEvent({required this.fieldId});

  @override
  List<Object> get props => [fieldId];
}