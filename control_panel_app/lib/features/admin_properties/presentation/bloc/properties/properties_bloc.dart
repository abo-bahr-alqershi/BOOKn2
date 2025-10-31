// lib/features/admin_properties/presentation/bloc/properties/properties_bloc.dart

import 'package:bookn_cp_app/features/admin_amenities/domain/entities/amenity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../../domain/entities/property.dart';
import '../../../domain/usecases/properties/get_all_properties_usecase.dart';
import '../../../domain/usecases/properties/get_property_details_usecase.dart';
import '../../../domain/usecases/properties/create_property_usecase.dart';
import '../../../domain/usecases/properties/update_property_usecase.dart';
import '../../../domain/usecases/properties/delete_property_usecase.dart';
import '../../../domain/usecases/properties/approve_property_usecase.dart';
import '../../../domain/usecases/properties/reject_property_usecase.dart';

part 'properties_event.dart';
part 'properties_state.dart';

class PropertiesBloc extends Bloc<PropertiesEvent, PropertiesState> {
  final GetAllPropertiesUseCase getAllProperties;
  final GetPropertyDetailsUseCase getPropertyDetails;
  final CreatePropertyUseCase createProperty;
  final UpdatePropertyUseCase updateProperty;
  final DeletePropertyUseCase deleteProperty;
  final ApprovePropertyUseCase approveProperty;
  final RejectPropertyUseCase rejectProperty;

  PropertiesBloc({
    required this.getAllProperties,
    required this.getPropertyDetails,
    required this.createProperty,
    required this.updateProperty,
    required this.deleteProperty,
    required this.approveProperty,
    required this.rejectProperty,
  }) : super(PropertiesInitial()) {
    on<LoadPropertiesEvent>(_onLoadProperties);
    on<LoadMorePropertiesEvent>(_onLoadMoreProperties);
    on<LoadPropertyDetailsEvent>(_onLoadPropertyDetails);
    on<CreatePropertyEvent>(_onCreateProperty);
    on<UpdatePropertyEvent>(_onUpdateProperty);
    on<DeletePropertyEvent>(_onDeleteProperty);
    on<ApprovePropertyEvent>(_onApproveProperty);
    on<RejectPropertyEvent>(_onRejectProperty);
    on<FilterPropertiesEvent>(_onFilterProperties);
    on<SearchPropertiesEvent>(_onSearchProperties);
  }

  Future<void> _onLoadProperties(
    LoadPropertiesEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertiesLoading());

    final result = await getAllProperties(
      GetAllPropertiesParams(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        sortBy: event.sortBy,
        isAscending: event.isAscending,
        isApproved: event.isApproved,
      ),
    );

    result.fold(
      (failure) => emit(PropertiesError(failure.message)),
      (paginatedResult) => emit(PropertiesLoaded(
        properties: paginatedResult.items,
        totalCount: paginatedResult.totalCount,
        currentPage: paginatedResult.pageNumber,
        totalPages: paginatedResult.totalPages,
        hasNextPage: paginatedResult.hasNextPage,
        hasPreviousPage: paginatedResult.hasPreviousPage,
        stats: (paginatedResult.metadata is Map<String, dynamic>)
            ? (paginatedResult.metadata as Map<String, dynamic>)
            : null,
        activeFilters: null,
      )),
    );
  }

  Future<void> _onLoadMoreProperties(
    LoadMorePropertiesEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    final current = state;
    if (current is! PropertiesLoaded) return;
    if (!current.hasNextPage && event.pageNumber == null) return;

    final nextPage = event.pageNumber ?? (current.currentPage + 1);

    final result = await getAllProperties(
      GetAllPropertiesParams(
        pageNumber: nextPage,
        pageSize: event.pageSize ?? 20,
        searchTerm: current.searchTerm,
        propertyTypeId: current.activeFilters != null
            ? current.activeFilters!['propertyTypeId'] as String?
            : null,
        minPrice: current.activeFilters != null
            ? current.activeFilters!['minPrice'] as double?
            : null,
        maxPrice: current.activeFilters != null
            ? current.activeFilters!['maxPrice'] as double?
            : null,
        amenityIds: current.activeFilters != null
            ? (current.activeFilters!['amenityIds'] as List<String>?)
            : null,
        starRatings: current.activeFilters != null
            ? (current.activeFilters!['starRatings'] as List<int>?)
            : null,
        minAverageRating: current.activeFilters != null
            ? current.activeFilters!['minAverageRating'] as double?
            : null,
        isApproved: current.activeFilters != null
            ? current.activeFilters!['isApproved'] as bool?
            : null,
        hasActiveBookings: current.activeFilters != null
            ? current.activeFilters!['hasActiveBookings'] as bool?
            : null,
      ),
    );

    result.fold(
      (failure) => emit(PropertiesError(failure.message)),
      (paginatedResult) {
        final List<Property> combined = List<Property>.from(current.properties)
          ..addAll(paginatedResult.items);

        emit(PropertiesLoaded(
          properties: combined,
          totalCount: paginatedResult.totalCount,
          currentPage: paginatedResult.pageNumber,
          totalPages: paginatedResult.totalPages,
          hasNextPage: paginatedResult.hasNextPage,
          hasPreviousPage: paginatedResult.hasPreviousPage,
          searchTerm: current.searchTerm,
          activeFilters: current.activeFilters,
          stats: (paginatedResult.metadata is Map<String, dynamic>)
              ? (paginatedResult.metadata as Map<String, dynamic>)
              : current.stats,
        ));
      },
    );
  }

  Future<void> _onLoadPropertyDetails(
    LoadPropertyDetailsEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertyDetailsLoading());

    final result = await getPropertyDetails(
      GetPropertyDetailsParams(
        propertyId: event.propertyId,
        includeUnits: event.includeUnits,
      ),
    );

    result.fold(
      (failure) => emit(PropertyDetailsError(failure.message)),
      (property) => emit(PropertyDetailsLoaded(property)),
    );
  }

  Future<void> _onCreateProperty(
    CreatePropertyEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertyCreating());

    final result = await createProperty(
      CreatePropertyParams(
        name: event.name,
        address: event.address,
        propertyTypeId: event.propertyTypeId,
        ownerId: event.ownerId,
        description: event.description,
        latitude: event.latitude,
        longitude: event.longitude,
        city: event.city,
        starRating: event.starRating,
        images: event.images,
        amenityIds: event.amenityIds,
        tempKey: event.tempKey,
        shortDescription: event.shortDescription,
        currency: event.currency,
        isFeatured: event.isFeatured,
      ),
    );

    result.fold(
      (failure) => emit(PropertiesError(failure.message)),
      (propertyId) {
        emit(PropertyCreated(propertyId));
        add(const LoadPropertiesEvent());
      },
    );
  }

  Future<void> _onUpdateProperty(
    UpdatePropertyEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertyUpdating());

    final result = await updateProperty(
      UpdatePropertyParams(
        propertyId: event.propertyId,
        name: event.name,
        address: event.address,
        description: event.description,
        latitude: event.latitude,
        longitude: event.longitude,
        city: event.city,
        starRating: event.starRating,
        images: event.images,
        shortDescription: event.shortDescription,
        currency: event.currency,
        isFeatured: event.isFeatured,
        ownerId: event.ownerId,
        amenityIds: event.amenityIds,
      ),
    );

    result.fold(
      (failure) => emit(PropertiesError(failure.message)),
      (_) {
        emit(PropertyUpdated());
        add(const LoadPropertiesEvent());
      },
    );
  }

  Future<void> _onDeleteProperty(
    DeletePropertyEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertyDeleting());

    final result = await deleteProperty(event.propertyId);

    result.fold(
      (failure) => emit(PropertiesError(failure.message)),
      (_) {
        emit(PropertyDeleted());
        add(const LoadPropertiesEvent());
      },
    );
  }

  Future<void> _onApproveProperty(
    ApprovePropertyEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    final result = await approveProperty(event.propertyId);

    result.fold(
      (failure) => emit(PropertiesError(failure.message)),
      (_) {
        emit(PropertyStatusUpdated(event.propertyId, true));
        add(LoadPropertyDetailsEvent(propertyId: event.propertyId));
      },
    );
  }

  Future<void> _onRejectProperty(
    RejectPropertyEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    final result = await rejectProperty(event.propertyId);

    result.fold(
      (failure) => emit(PropertiesError(failure.message)),
      (_) {
        emit(PropertyStatusUpdated(event.propertyId, false));
        add(LoadPropertyDetailsEvent(propertyId: event.propertyId));
      },
    );
  }

  Future<void> _onFilterProperties(
    FilterPropertiesEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertiesLoading());

    final result = await getAllProperties(
      GetAllPropertiesParams(
        pageNumber: 1,
        pageSize: 20,
        searchTerm: event.searchTerm,
        propertyTypeId: event.propertyTypeId,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        amenityIds: event.amenityIds,
        starRatings: event.starRatings,
        minAverageRating: event.minAverageRating,
        isApproved: event.isApproved,
        hasActiveBookings: event.hasActiveBookings,
      ),
    );

    result.fold(
      (failure) => emit(PropertiesError(failure.message)),
      (paginatedResult) => emit(PropertiesLoaded(
        properties: paginatedResult.items,
        totalCount: paginatedResult.totalCount,
        currentPage: paginatedResult.pageNumber,
        totalPages: paginatedResult.totalPages,
        hasNextPage: paginatedResult.hasNextPage,
        hasPreviousPage: paginatedResult.hasPreviousPage,
        stats: (paginatedResult.metadata is Map<String, dynamic>) ? (paginatedResult.metadata as Map<String, dynamic>) : null,
        activeFilters: {
          if (event.propertyTypeId != null)
            'propertyTypeId': event.propertyTypeId!,
          if (event.searchTerm != null && event.searchTerm!.isNotEmpty)
            'searchTerm': event.searchTerm!,
          if (event.minPrice != null) 'minPrice': event.minPrice!,
          if (event.maxPrice != null) 'maxPrice': event.maxPrice!,
          if (event.amenityIds != null) 'amenityIds': event.amenityIds!,
          if (event.starRatings != null) 'starRatings': event.starRatings!,
          if (event.minAverageRating != null)
            'minAverageRating': event.minAverageRating!,
          if (event.isApproved != null) 'isApproved': event.isApproved!,
          if (event.hasActiveBookings != null)
            'hasActiveBookings': event.hasActiveBookings!,
        },
      )),
    );
  }

  Future<void> _onSearchProperties(
    SearchPropertiesEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertiesLoading());

    final result = await getAllProperties(
      GetAllPropertiesParams(
        pageNumber: 1,
        pageSize: 20,
        searchTerm: event.searchTerm,
      ),
    );

    result.fold(
      (failure) => emit(PropertiesError(failure.message)),
      (paginatedResult) => emit(PropertiesLoaded(
        properties: paginatedResult.items,
        totalCount: paginatedResult.totalCount,
        currentPage: paginatedResult.pageNumber,
        totalPages: paginatedResult.totalPages,
        hasNextPage: paginatedResult.hasNextPage,
        hasPreviousPage: paginatedResult.hasPreviousPage,
        searchTerm: event.searchTerm,
        stats: (paginatedResult.metadata is Map<String, dynamic>) ? (paginatedResult.metadata as Map<String, dynamic>) : null,
        activeFilters: null,
      )),
    );
  }
}
