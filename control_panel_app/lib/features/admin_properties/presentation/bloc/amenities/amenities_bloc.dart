// lib/features/admin_properties/presentation/bloc/amenities/amenities_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/amenity.dart';
import '../../../domain/usecases/amenities/get_amenities_usecase.dart';
import '../../../domain/usecases/amenities/create_amenity_usecase.dart';
import '../../../domain/usecases/amenities/update_amenity_usecase.dart';
import '../../../domain/usecases/amenities/delete_amenity_usecase.dart';
import '../../../domain/usecases/amenities/assign_amenity_to_property_usecase.dart';
import '../../../domain/usecases/amenities/unassign_amenity_from_property_usecase.dart';

part 'amenities_event.dart';
part 'amenities_state.dart';

class AmenitiesBloc extends Bloc<AmenitiesEvent, AmenitiesState> {
  final GetAmenitiesUseCase getAmenities;
  final CreateAmenityUseCase createAmenity;
  final UpdateAmenityUseCase updateAmenity;
  final DeleteAmenityUseCase deleteAmenity;
  final AssignAmenityToPropertyUseCase assignAmenityToProperty;
  final UnassignAmenityFromPropertyUseCase unassignAmenityFromProperty;

  AmenitiesBloc({
    required this.getAmenities,
    required this.createAmenity,
    required this.updateAmenity,
    required this.deleteAmenity,
    required this.assignAmenityToProperty,
    required this.unassignAmenityFromProperty,
  }) : super(AmenitiesInitial()) {
    on<LoadAmenitiesEvent>(_onLoadAmenities);
    on<CreateAmenityEvent>(_onCreateAmenity);
    on<UpdateAmenityEvent>(_onUpdateAmenity);
    on<DeleteAmenityEvent>(_onDeleteAmenity);
    on<AssignAmenityToPropertyEvent>(_onAssignAmenityToProperty);
    on<UnassignAmenityFromPropertyEvent>(_onUnassignAmenityFromProperty);
  }

  Future<void> _onLoadAmenities(
    LoadAmenitiesEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenitiesLoading());

    final result = await getAmenities(
      GetAmenitiesParams(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        searchTerm: event.searchTerm,
        propertyId: event.propertyId,
        isAssigned: event.isAssigned,
        isFree: event.isFree,
        propertyTypeId: event is LoadAmenitiesEventWithType ? event.propertyTypeId : null,
      ),
    );

    result.fold(
      (failure) => emit(AmenitiesError(failure.message)),
      (paginatedResult) => emit(AmenitiesLoaded(
        amenities: paginatedResult.items,
        totalCount: paginatedResult.totalCount,
        currentPage: paginatedResult.pageNumber,
        totalPages: paginatedResult.totalPages,
        hasNextPage: paginatedResult.hasNextPage,
        hasPreviousPage: paginatedResult.hasPreviousPage,
      )),
    );
  }

  Future<void> _onCreateAmenity(
    CreateAmenityEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenityCreating());

    final result = await createAmenity(
      CreateAmenityParams(
        name: event.name,
        description: event.description,
        icon: event.icon,
      ),
    );

    result.fold(
      (failure) => emit(AmenitiesError(failure.message)),
      (amenityId) {
        emit(AmenityCreated(amenityId));
        add(const LoadAmenitiesEvent());
      },
    );
  }

  Future<void> _onUpdateAmenity(
    UpdateAmenityEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenityUpdating());

    final result = await updateAmenity(
      UpdateAmenityParams(
        amenityId: event.amenityId,
        name: event.name,
        description: event.description,
        icon: event.icon,
      ),
    );

    result.fold(
      (failure) => emit(AmenitiesError(failure.message)),
      (_) {
        emit(AmenityUpdated());
        add(const LoadAmenitiesEvent());
      },
    );
  }

  Future<void> _onDeleteAmenity(
    DeleteAmenityEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenityDeleting());

    final result = await deleteAmenity(event.amenityId);

    result.fold(
      (failure) => emit(AmenitiesError(failure.message)),
      (_) {
        emit(AmenityDeleted());
        add(const LoadAmenitiesEvent());
      },
    );
  }

  Future<void> _onAssignAmenityToProperty(
    AssignAmenityToPropertyEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenityAssigning());

    final result = await assignAmenityToProperty(
      AssignAmenityParams(
        amenityId: event.amenityId,
        propertyId: event.propertyId,
        isAvailable: event.isAvailable,
        extraCost: event.extraCost,
        currency: event.currency,
        description: event.description,
      ),
    );

    result.fold(
      (failure) => emit(AmenitiesError(failure.message)),
      (_) {
        emit(AmenityAssigned());
        add(LoadAmenitiesEvent(propertyId: event.propertyId));
      },
    );
  }

  Future<void> _onUnassignAmenityFromProperty(
    UnassignAmenityFromPropertyEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenityUnassigning());

    final result = await unassignAmenityFromProperty(
      UnassignAmenityParams(
        amenityId: event.amenityId,
        propertyId: event.propertyId,
      ),
    );

    result.fold(
      (failure) => emit(AmenitiesError(failure.message)),
      (_) {
        emit(AmenityUnassigned());
        add(LoadAmenitiesEvent(propertyId: event.propertyId));
      },
    );
  }
}
