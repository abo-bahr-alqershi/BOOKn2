import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/unit.dart';
import '../../../domain/entities/unit_type.dart';
import '../../../domain/entities/money.dart';
import '../../../domain/entities/pricing_method.dart';
import '../../../domain/usecases/create_unit_usecase.dart';
import '../../../domain/usecases/update_unit_usecase.dart';
import '../../../domain/usecases/get_unit_types_by_property_usecase.dart';
import '../../../domain/usecases/get_unit_fields_usecase.dart';

part 'unit_form_event.dart';
part 'unit_form_state.dart';

class UnitFormBloc extends Bloc<UnitFormEvent, UnitFormState> {
  final CreateUnitUseCase createUnitUseCase;
  final UpdateUnitUseCase updateUnitUseCase;
  final GetUnitTypesByPropertyUseCase getUnitTypesByPropertyUseCase;
  final GetUnitFieldsUseCase getUnitFieldsUseCase;

  UnitFormBloc({
    required this.createUnitUseCase,
    required this.updateUnitUseCase,
    required this.getUnitTypesByPropertyUseCase,
    required this.getUnitFieldsUseCase,
  }) : super(UnitFormInitial()) {
    on<InitializeFormEvent>(_onInitializeForm);
    on<PropertySelectedEvent>(_onPropertySelected);
    on<UnitTypeSelectedEvent>(_onUnitTypeSelected);
    on<UpdateUnitNameEvent>(_onUpdateUnitName); 
    on<UpdateDescriptionEvent>(_onUpdateDescription);
    on<UpdateCapacityEvent>(_onUpdateCapacity);
    on<UpdateUnitImageEvent>(_onUpdateUnitImage);
    on<UpdatePricingEvent>(_onUpdatePricing);
    on<UpdateFeaturesEvent>(_onUpdateFeatures);
    on<UpdateDynamicFieldsEvent>(_onUpdateDynamicFields);
    on<SubmitFormEvent>(_onSubmitForm);
    on<UpdateCancellationPolicyEvent>(_onUpdateCancellationPolicy);
  }

  Future<void> _onInitializeForm(
    InitializeFormEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    // لا تستخدم حالة تحميل هنا لتجنب الرجوع البصري ومسح الحقول عند التحرير
    if (event.unitId != null) {
      emit(UnitFormReady(
        isEditMode: true,
        unitId: event.unitId,
      ));
    } else {
      emit(UnitFormReady(tempKey: event.tempKey));
    }
  }

  Future<void> _onUpdateUnitName(
    UpdateUnitNameEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      emit(currentState.copyWith(
        unitName: event.name,
      ));
    }
  }

  Future<void> _onUpdateDescription(
    UpdateDescriptionEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      emit(currentState.copyWith(
        description: event.description,
      ));
    }
  }


  Future<void> _onPropertySelected(
    PropertySelectedEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      emit(currentState.copyWith(isLoadingUnitTypes: true));
      
      final targetPropertyTypeId = event.propertyTypeId ?? event.propertyId;
      final result = await getUnitTypesByPropertyUseCase(targetPropertyTypeId!);
      
      result.fold(
        (failure) => emit(UnitFormError(message: failure.message)),
        (unitTypes) => emit(currentState.copyWith(
          selectedPropertyId: event.propertyId,
          availableUnitTypes: unitTypes,
          isLoadingUnitTypes: false,
        )),
      );
    }
  }

  Future<void> _onUnitTypeSelected(
    UnitTypeSelectedEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      emit(currentState.copyWith(isLoadingFields: true));
      
      // Try resolve selected unit type from available list if present (safe for edit mode when list may be empty)
      UnitType? unitType;
      try {
        unitType = currentState.availableUnitTypes.firstWhere((type) => type.id == event.unitTypeId);
      } catch (_) {
        unitType = currentState.selectedUnitType; // keep previous if any (edit mode)
      }
      
      // Load fields for this unit type
      final result = await getUnitFieldsUseCase(event.unitTypeId);
      
      result.fold(
        (failure) => emit(UnitFormError(message: failure.message)),
        (fields) => emit(currentState.copyWith(
          selectedUnitType: unitType,
          unitTypeFields: fields,
          isLoadingFields: false,
        )),
      );
    }
  }

  Future<void> _onUpdateCapacity(
    UpdateCapacityEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      emit(currentState.copyWith(
        adultCapacity: event.adultCapacity,
        childrenCapacity: event.childrenCapacity,
      ));
    }
  }

    Future<void> _onUpdateUnitImage(
    UpdateUnitImageEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      emit(currentState.copyWith(
        images: event.images,
      ));
    }
  }



  Future<void> _onUpdatePricing(
    UpdatePricingEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      emit(currentState.copyWith(
        basePrice: event.basePrice,
        pricingMethod: event.pricingMethod,
      ));
    }
  }

  Future<void> _onUpdateFeatures(
    UpdateFeaturesEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      emit(currentState.copyWith(
        customFeatures: event.features,
      ));
    }
  }

  Future<void> _onUpdateDynamicFields(
    UpdateDynamicFieldsEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      emit(currentState.copyWith(
        dynamicFieldValues: event.values,
      ));
    }
  }

  Future<void> _onUpdateCancellationPolicy(
    UpdateCancellationPolicyEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      emit(currentState.copyWith(
        allowsCancellation: event.allowsCancellation,
        cancellationWindowDays: event.cancellationWindowDays,
      ));
    }
  }

  Future<void> _onSubmitForm(
    SubmitFormEvent event,
    Emitter<UnitFormState> emit,
  ) async {
    if (state is UnitFormReady) {
      final currentState = state as UnitFormReady;
      
      // التحقق من البيانات المطلوبة قبل الإرسال
      if (!_validateFormData(currentState)) {
        emit(const UnitFormError(message: 'الرجاء ملء جميع الحقول المطلوبة'));
        return;
      }
      
      emit(UnitFormLoading());
      
      if (currentState.isEditMode) {
        // Update existing unit
        final result = await updateUnitUseCase(UpdateUnitParams(
          unitId: currentState.unitId!,
          name: currentState.unitName,
          description: currentState.description ?? '',
          basePrice: currentState.basePrice?.toJson(),
          customFeatures: currentState.customFeatures,
          pricingMethod: currentState.pricingMethod?.value,
          fieldValues: _convertDynamicFieldsToList(currentState.dynamicFieldValues),
          images: currentState.images,
          adultCapacity: currentState.adultCapacity,
          childrenCapacity: currentState.childrenCapacity,
          allowsCancellation: currentState.allowsCancellation,
          cancellationWindowDays: currentState.cancellationWindowDays,
        ));
        
        result.fold(
          (failure) => emit(UnitFormError(message: failure.message)),
          (_) => emit(UnitFormSubmitted(unitId: currentState.unitId)),
        );
      } else {
        // Create new unit - مع التحقق الآمن
        final result = await createUnitUseCase(CreateUnitParams(
          propertyId: currentState.selectedPropertyId!,
          unitTypeId: currentState.selectedUnitType!.id,
          name: currentState.unitName!,
          description: currentState.description ?? '',
          basePrice: currentState.basePrice!.toJson(),
          customFeatures: currentState.customFeatures ?? '',
          pricingMethod: currentState.pricingMethod!.value,
          fieldValues: _convertDynamicFieldsToList(currentState.dynamicFieldValues),
          images: currentState.images,
          adultCapacity: currentState.adultCapacity ?? 0,
          childrenCapacity: currentState.childrenCapacity ?? 0,
          tempKey: currentState.tempKey,
          allowsCancellation: currentState.allowsCancellation,
          cancellationWindowDays: currentState.cancellationWindowDays,
        ));
        
        result.fold(
          (failure) => emit(UnitFormError(message: failure.message)),
          (newUnitId) => emit(UnitFormSubmitted(unitId: newUnitId)),
        );
      }
    }
  }

  // دالة للتحقق من صحة البيانات
  bool _validateFormData(UnitFormReady state) {
    if (state.isEditMode) {
      return state.unitId != null;
    }
    
    // للإنشاء، تحقق من جميع الحقول المطلوبة
    return state.selectedPropertyId != null &&
           state.selectedUnitType != null &&
           state.unitName != null &&
           state.unitName!.isNotEmpty &&
           state.basePrice != null &&
           state.pricingMethod != null &&
           state.description != null &&
           state.description!.isNotEmpty;
  }

  List<Map<String, dynamic>> _convertDynamicFieldsToList(
    Map<String, dynamic> fieldValues,
  ) {
    return fieldValues.entries
        .map((entry) => {
              'fieldId': entry.key,
              'fieldValue': entry.value?.toString() ?? '',
            })
        .toList();
  }
}