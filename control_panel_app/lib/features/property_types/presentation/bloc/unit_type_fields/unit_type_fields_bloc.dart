import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/fields/get_fields_by_unit_type_usecase.dart';
import '../../../domain/usecases/fields/create_field_usecase.dart';
import '../../../domain/usecases/fields/update_field_usecase.dart';
import '../../../domain/usecases/fields/delete_field_usecase.dart';
import 'unit_type_fields_event.dart';
import 'unit_type_fields_state.dart';

class UnitTypeFieldsBloc extends Bloc<UnitTypeFieldsEvent, UnitTypeFieldsState> {
  final GetFieldsByUnitTypeUseCase getFieldsByUnitType;
  final CreateFieldUseCase createField;
  final UpdateFieldUseCase updateField;
  final DeleteFieldUseCase deleteField;

  String? _currentUnitTypeId;

  UnitTypeFieldsBloc({
    required this.getFieldsByUnitType,
    required this.createField,
    required this.updateField,
    required this.deleteField,
  }) : super(UnitTypeFieldsInitial()) {
    on<LoadUnitTypeFieldsEvent>(_onLoadFields);
    on<SearchFieldsEvent>(_onSearchFields);
    on<CreateFieldEvent>(_onCreateField);
    on<UpdateFieldEvent>(_onUpdateField);
    on<DeleteFieldEvent>(_onDeleteField);
  }

  Future<void> _onLoadFields(
    LoadUnitTypeFieldsEvent event,
    Emitter<UnitTypeFieldsState> emit,
  ) async {
    emit(UnitTypeFieldsLoading());
    _currentUnitTypeId = event.unitTypeId;
    
    final result = await getFieldsByUnitType(
      GetFieldsByUnitTypeParams(unitTypeId: event.unitTypeId),
    );
    
    result.fold(
      (failure) => emit(UnitTypeFieldsError(message: failure.message)),
      (fields) => emit(UnitTypeFieldsLoaded(
        fields: fields,
        filteredFields: fields,
      )),
    );
  }

  void _onSearchFields(
    SearchFieldsEvent event,
    Emitter<UnitTypeFieldsState> emit,
  ) {
    if (state is UnitTypeFieldsLoaded) {
      final loadedState = state as UnitTypeFieldsLoaded;
      final searchTerm = event.searchTerm.toLowerCase();
      
      final filteredFields = loadedState.fields.where((field) {
        return field.displayName.toLowerCase().contains(searchTerm) ||
               field.fieldName.toLowerCase().contains(searchTerm) ||
               field.description.toLowerCase().contains(searchTerm);
      }).toList();
      
      emit(loadedState.copyWith(
        filteredFields: filteredFields,
        searchTerm: event.searchTerm,
      ));
    }
  }

  Future<void> _onCreateField(
    CreateFieldEvent event,
    Emitter<UnitTypeFieldsState> emit,
  ) async {
    final currentState = state;
    
    final Map<String, dynamic>? fieldOptions = event.fieldData['fieldOptions'] == null
        ? null
        : Map<String, dynamic>.from(event.fieldData['fieldOptions'] as Map);
    final Map<String, dynamic>? validationRules = event.fieldData['validationRules'] == null
        ? null
        : Map<String, dynamic>.from(event.fieldData['validationRules'] as Map);

    final result = await createField(
      CreateFieldParams(
        unitTypeId: event.unitTypeId,
        fieldTypeId: event.fieldData['fieldTypeId'],
        fieldName: event.fieldData['fieldName'],
        displayName: event.fieldData['displayName'],
        description: event.fieldData['description'],
        fieldOptions: fieldOptions,
        validationRules: validationRules,
        isRequired: event.fieldData['isRequired'],
        isSearchable: event.fieldData['isSearchable'],
        isPublic: event.fieldData['isPublic'],
        sortOrder: event.fieldData['sortOrder'],
        category: event.fieldData['category'],
        isForUnits: event.fieldData['isForUnits'],
        groupId: event.fieldData['groupId'],
        showInCards: event.fieldData['showInCards'],
        isPrimaryFilter: event.fieldData['isPrimaryFilter'],
        priority: event.fieldData['priority'],
      ),
    );
    
    result.fold(
      (failure) {
        emit(UnitTypeFieldsError(message: failure.message));
        if (currentState is UnitTypeFieldsLoaded) {
          emit(currentState);
        }
      },
      (_) {
        if (_currentUnitTypeId != null) {
          add(LoadUnitTypeFieldsEvent(unitTypeId: _currentUnitTypeId!));
        }
      },
    );
  }

  Future<void> _onUpdateField(
    UpdateFieldEvent event,
    Emitter<UnitTypeFieldsState> emit,
  ) async {
    final currentState = state;
    
    final Map<String, dynamic>? fieldOptions = event.fieldData['fieldOptions'] == null
        ? null
        : Map<String, dynamic>.from(event.fieldData['fieldOptions'] as Map);
    final Map<String, dynamic>? validationRules = event.fieldData['validationRules'] == null
        ? null
        : Map<String, dynamic>.from(event.fieldData['validationRules'] as Map);
    
    final result = await updateField(
      UpdateFieldParams(
        fieldId: event.fieldId,
        fieldTypeId: event.fieldData['fieldTypeId'],
        fieldName: event.fieldData['fieldName'],
        displayName: event.fieldData['displayName'],
        description: event.fieldData['description'],
        fieldOptions: fieldOptions,
        validationRules: validationRules,
        isRequired: event.fieldData['isRequired'],
        isSearchable: event.fieldData['isSearchable'],
        isPublic: event.fieldData['isPublic'],
        sortOrder: event.fieldData['sortOrder'],
        category: event.fieldData['category'],
        isForUnits: event.fieldData['isForUnits'],
        groupId: event.fieldData['groupId'],
        showInCards: event.fieldData['showInCards'],
        isPrimaryFilter: event.fieldData['isPrimaryFilter'],
        priority: event.fieldData['priority'],
      ),
    );
    
    result.fold(
      (failure) {
        emit(UnitTypeFieldsError(message: failure.message));
        if (currentState is UnitTypeFieldsLoaded) {
          emit(currentState);
        }
      },
      (_) {
        if (_currentUnitTypeId != null) {
          add(LoadUnitTypeFieldsEvent(unitTypeId: _currentUnitTypeId!));
        }
      },
    );
  }

  Future<void> _onDeleteField(
    DeleteFieldEvent event,
    Emitter<UnitTypeFieldsState> emit,
  ) async {
    final currentState = state;
    
    final result = await deleteField(event.fieldId);
    
    result.fold(
      (failure) {
        emit(UnitTypeFieldsError(message: failure.message));
        if (currentState is UnitTypeFieldsLoaded) {
          emit(currentState);
        }
      },
      (_) {
        if (_currentUnitTypeId != null) {
          add(LoadUnitTypeFieldsEvent(unitTypeId: _currentUnitTypeId!));
        }
      },
    );
  }
}