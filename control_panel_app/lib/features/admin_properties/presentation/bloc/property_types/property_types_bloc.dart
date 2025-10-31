// lib/features/admin_properties/presentation/bloc/property_types/property_types_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../../domain/entities/property_type.dart';
import '../../../domain/usecases/property_types/get_property_types_usecase.dart';
import '../../../domain/usecases/property_types/create_property_type_usecase.dart';
import '../../../domain/usecases/property_types/update_property_type_usecase.dart';
import '../../../domain/usecases/property_types/delete_property_type_usecase.dart';

part 'property_types_event.dart';
part 'property_types_state.dart';

class PropertyTypesBloc extends Bloc<PropertyTypesEvent, PropertyTypesState> {
  final GetPropertyTypesUseCase getPropertyTypes;
  final CreatePropertyTypeUseCase createPropertyType;
  final UpdatePropertyTypeUseCase updatePropertyType;
  final DeletePropertyTypeUseCase deletePropertyType;
  
  PropertyTypesBloc({
    required this.getPropertyTypes,
    required this.createPropertyType,
    required this.updatePropertyType,
    required this.deletePropertyType,
  }) : super(PropertyTypesInitial()) {
    on<LoadPropertyTypesEvent>(_onLoadPropertyTypes);
    on<CreatePropertyTypeEvent>(_onCreatePropertyType);
    on<UpdatePropertyTypeEvent>(_onUpdatePropertyType);
    on<DeletePropertyTypeEvent>(_onDeletePropertyType);
  }
  
  Future<void> _onLoadPropertyTypes(
    LoadPropertyTypesEvent event,
    Emitter<PropertyTypesState> emit,
  ) async {
    emit(PropertyTypesLoading());
    
    final result = await getPropertyTypes(
      GetPropertyTypesParams(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
      ),
    );
    
    result.fold(
      (failure) => emit(PropertyTypesError(failure.message)),
      (paginatedResult) => emit(PropertyTypesLoaded(
        propertyTypes: paginatedResult.items,
        totalCount: paginatedResult.totalCount,
        currentPage: paginatedResult.pageNumber,
        totalPages: paginatedResult.totalPages,
        hasNextPage: paginatedResult.hasNextPage,
        hasPreviousPage: paginatedResult.hasPreviousPage,
      )),
    );
  }
  
  Future<void> _onCreatePropertyType(
    CreatePropertyTypeEvent event,
    Emitter<PropertyTypesState> emit,
  ) async {
    emit(PropertyTypeCreating());
    
    final result = await createPropertyType(
      CreatePropertyTypeParams(
        name: event.name,
        description: event.description,
        defaultAmenities: event.defaultAmenities,
        icon: event.icon,
      ),
    );
    
    result.fold(
      (failure) => emit(PropertyTypesError(failure.message)),
      (propertyTypeId) {
        emit(PropertyTypeCreated(propertyTypeId));
        add(LoadPropertyTypesEvent());
      },
    );
  }
  
  Future<void> _onUpdatePropertyType(
    UpdatePropertyTypeEvent event,
    Emitter<PropertyTypesState> emit,
  ) async {
    emit(PropertyTypeUpdating());
    
    final result = await updatePropertyType(
      UpdatePropertyTypeParams(
        propertyTypeId: event.propertyTypeId,
        name: event.name,
        description: event.description,
        defaultAmenities: event.defaultAmenities,
        icon: event.icon,
      ),
    );
    
    result.fold(
      (failure) => emit(PropertyTypesError(failure.message)),
      (_) {
        emit(PropertyTypeUpdated());
        add(LoadPropertyTypesEvent());
      },
    );
  }
  
  Future<void> _onDeletePropertyType(
    DeletePropertyTypeEvent event,
    Emitter<PropertyTypesState> emit,
  ) async {
    emit(PropertyTypeDeleting());
    
    final result = await deletePropertyType(event.propertyTypeId);
    
    result.fold(
      (failure) => emit(PropertyTypesError(failure.message)),
      (_) {
        emit(PropertyTypeDeleted());
        add(LoadPropertyTypesEvent());
      },
    );
  }
}