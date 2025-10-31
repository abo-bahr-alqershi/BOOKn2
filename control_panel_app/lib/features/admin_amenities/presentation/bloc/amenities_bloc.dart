import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/amenity.dart';
import '../../domain/usecases/create_amenity_usecase.dart';
import '../../domain/usecases/update_amenity_usecase.dart';
import '../../domain/usecases/delete_amenity_usecase.dart';
import '../../domain/usecases/get_all_amenities_usecase.dart';
import '../../domain/usecases/assign_amenity_to_property_usecase.dart';
import '../../domain/repositories/amenities_repository.dart';
import 'amenities_event.dart';
import 'amenities_state.dart';

class AmenitiesBloc extends Bloc<AmenitiesEvent, AmenitiesState> {
  final CreateAmenityUseCase createAmenityUseCase;
  final UpdateAmenityUseCase updateAmenityUseCase;
  final DeleteAmenityUseCase deleteAmenityUseCase;
  final GetAllAmenitiesUseCase getAllAmenitiesUseCase;
  final AssignAmenityToPropertyUseCase assignAmenityToPropertyUseCase;
  final AmenitiesRepository repository;

  // متغيرات لحفظ حالة البحث والفلاتر
  String? _currentSearchTerm;
  bool? _currentIsAssigned;
  bool? _currentIsFree;
  int _currentPageNumber = 1;
  int _currentPageSize = 10;

  AmenitiesBloc({
    required this.createAmenityUseCase,
    required this.updateAmenityUseCase,
    required this.deleteAmenityUseCase,
    required this.getAllAmenitiesUseCase,
    required this.assignAmenityToPropertyUseCase,
    required this.repository,
  }) : super(AmenitiesInitial()) {
    on<LoadAmenitiesEvent>(_onLoadAmenities);
    on<CreateAmenityEvent>(_onCreateAmenity);
    on<UpdateAmenityEvent>(_onUpdateAmenity);
    on<DeleteAmenityEvent>(_onDeleteAmenity);
    on<ToggleAmenityStatusEvent>(_onToggleAmenityStatus);
    on<AssignAmenityToPropertyEvent>(_onAssignAmenityToProperty);
    on<AssignAmenityToPropertyTypeEvent>(_onAssignAmenityToPropertyType);
    on<LoadAmenityStatsEvent>(_onLoadAmenityStats);
    on<SearchAmenitiesEvent>(_onSearchAmenities);
    on<SelectAmenityEvent>(_onSelectAmenity);
    on<DeselectAmenityEvent>(_onDeselectAmenity);
    on<LoadPopularAmenitiesEvent>(_onLoadPopularAmenities);
    on<RefreshAmenitiesEvent>(_onRefreshAmenities);
    on<ChangePageEvent>(_onChangePage);
    on<ChangePageSizeEvent>(_onChangePageSize);
    on<ApplyFiltersEvent>(_onApplyFilters);
    on<ClearFiltersEvent>(_onClearFilters);
  }

  Future<void> _onAssignAmenityToPropertyType(
    AssignAmenityToPropertyTypeEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenityOperationInProgress(
      operation: 'assign_property_type',
      amenityId: event.amenityId,
    ));

    final result = await repository.assignAmenityToPropertyType(
      amenityId: event.amenityId,
      propertyTypeId: event.propertyTypeId,
      isDefault: event.isDefault,
    );

    result.fold(
      (failure) => emit(AmenityOperationFailure(
        message: failure.message,
        amenityId: event.amenityId,
      )),
      (_) => emit(AmenityOperationSuccess(
        message: 'تم ربط المرفق بنوع العقار بنجاح',
        amenityId: event.amenityId,
      )),
    );
  }

  Future<void> _onLoadAmenities(
    LoadAmenitiesEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    // حفظ قيم البحث والفلاتر
    _currentSearchTerm = event.searchTerm;
    _currentIsAssigned = event.isAssigned;
    _currentIsFree = event.isFree;
    _currentPageNumber = event.pageNumber;
    _currentPageSize = event.pageSize;

    final bool isLoadMore = state is AmenitiesLoaded && event.pageNumber > 1;
    if (!isLoadMore) {
      emit(const AmenitiesLoading());
    }

    final result = await getAllAmenitiesUseCase(
      GetAllAmenitiesParams(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        searchTerm: event.searchTerm,
        propertyId: event.propertyId,
        isAssigned: event.isAssigned,
        isFree: event.isFree,
      ),
    );

    await result.fold(
      (failure) async {
        emit(AmenitiesError(message: failure.message));
      },
      (page) async {
        final popularResult = !isLoadMore ? await repository.getPopularAmenities() : null;
        final popularAmenities = popularResult == null
            ? (state is AmenitiesLoaded ? (state as AmenitiesLoaded).popularAmenities : <Amenity>[])
            : popularResult.fold((_) => <Amenity>[], (amenities) => amenities);

        final statsResult = !isLoadMore ? await repository.getAmenityStats() : null;
        final stats = statsResult == null
            ? (state is AmenitiesLoaded ? (state as AmenitiesLoaded).stats : null)
            : statsResult.fold((_) => null, (s) => s);

        if (!emit.isDone) {
          if (isLoadMore && state is AmenitiesLoaded) {
            final current = state as AmenitiesLoaded;
            final mergedItems = <Amenity>[];
            final existing = current.amenities.items;
            mergedItems.addAll(existing);
            for (final a in page.items) {
              if (!mergedItems.any((x) => x.id == a.id)) mergedItems.add(a);
            }
            final merged = PaginatedResult<Amenity>(
              items: mergedItems,
              pageNumber: page.pageNumber,
              pageSize: page.pageSize,
              totalCount: page.totalCount,
            );
            emit(current.copyWith(
              amenities: merged,
              searchTerm: event.searchTerm,
              isAssigned: event.isAssigned,
              isFree: event.isFree,
              popularAmenities: popularAmenities,
              stats: stats,
            ));
          } else {
            emit(AmenitiesLoaded(
              amenities: page,
              searchTerm: event.searchTerm,
              isAssigned: event.isAssigned,
              isFree: event.isFree,
              popularAmenities: popularAmenities,
              stats: stats,
            ));
          }
        }
      },
    );
  }

  Future<void> _onCreateAmenity(
    CreateAmenityEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(const AmenityOperationInProgress(operation: 'create'));

    final result = await createAmenityUseCase(
      CreateAmenityParams(
        name: event.name,
        description: event.description,
        icon: event.icon,
        propertyTypeId: event.propertyTypeId,
        isDefaultForType: event.isDefaultForType,
      ),
    );

    result.fold(
      (failure) => emit(AmenityOperationFailure(message: failure.message)),
      (amenityId) {
        emit(AmenityOperationSuccess(
          message: 'تم إنشاء المرفق بنجاح',
          amenityId: amenityId,
        ));
        // إعادة تحميل القائمة
        if (!isClosed) {
          add(LoadAmenitiesEvent(
          pageNumber: _currentPageNumber,
          pageSize: _currentPageSize,
          searchTerm: _currentSearchTerm,
          isAssigned: _currentIsAssigned,
          isFree: _currentIsFree,
          ));
        }
      },
    );
  }

  Future<void> _onUpdateAmenity(
    UpdateAmenityEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenityOperationInProgress(
      operation: 'update',
      amenityId: event.amenityId,
    ));

    final result = await updateAmenityUseCase(
      UpdateAmenityParams(
        amenityId: event.amenityId,
        name: event.name,
        description: event.description,
        icon: event.icon,
      ),
    );

    result.fold(
      (failure) => emit(AmenityOperationFailure(
        message: failure.message,
        amenityId: event.amenityId,
      )),
      (_) {
        emit(AmenityOperationSuccess(
          message: 'تم تحديث المرفق بنجاح',
          amenityId: event.amenityId,
        ));
        // إعادة تحميل القائمة
        if (!isClosed) {
          add(LoadAmenitiesEvent(
          pageNumber: _currentPageNumber,
          pageSize: _currentPageSize,
          searchTerm: _currentSearchTerm,
          isAssigned: _currentIsAssigned,
          isFree: _currentIsFree,
          ));
        }
      },
    );
  }

  Future<void> _onDeleteAmenity(
    DeleteAmenityEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenityOperationInProgress(
      operation: 'delete',
      amenityId: event.amenityId,
    ));

    final result = await deleteAmenityUseCase(event.amenityId);

    result.fold(
      (failure) => emit(AmenityOperationFailure(
        message: failure.message,
        amenityId: event.amenityId,
      )),
      (_) {
        emit(AmenityOperationSuccess(
          message: 'تم حذف المرفق بنجاح',
          amenityId: event.amenityId,
        ));
        // إعادة تحميل القائمة
        if (!isClosed) {
          add(LoadAmenitiesEvent(
          pageNumber: _currentPageNumber,
          pageSize: _currentPageSize,
          searchTerm: _currentSearchTerm,
          isAssigned: _currentIsAssigned,
          isFree: _currentIsFree,
          ));
        }
      },
    );
  }

  Future<void> _onToggleAmenityStatus(
    ToggleAmenityStatusEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenityOperationInProgress(
      operation: 'toggle',
      amenityId: event.amenityId,
    ));

    final result = await repository.toggleAmenityStatus(event.amenityId);

    result.fold(
      (failure) => emit(AmenityOperationFailure(
        message: failure.message,
        amenityId: event.amenityId,
      )),
      (_) {
        emit(AmenityOperationSuccess(
          message: 'تم تغيير حالة المرفق بنجاح',
          amenityId: event.amenityId,
        ));
        // إعادة تحميل القائمة
        if (!isClosed) {
          add(LoadAmenitiesEvent(
          pageNumber: _currentPageNumber,
          pageSize: _currentPageSize,
          searchTerm: _currentSearchTerm,
          isAssigned: _currentIsAssigned,
          isFree: _currentIsFree,
          ));
        }
      },
    );
  }

  Future<void> _onAssignAmenityToProperty(
    AssignAmenityToPropertyEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenityOperationInProgress(
      operation: 'assign',
      amenityId: event.amenityId,
    ));

    final result = await assignAmenityToPropertyUseCase(
      AssignAmenityParams(
        amenityId: event.amenityId,
        propertyId: event.propertyId,
        isAvailable: event.isAvailable,
        extraCost: event.extraCost,
        description: event.description,
      ),
    );

    result.fold(
      (failure) => emit(AmenityOperationFailure(
        message: failure.message,
        amenityId: event.amenityId,
      )),
      (_) {
        emit(AmenityOperationSuccess(
          message: 'تم إسناد المرفق للعقار بنجاح',
          amenityId: event.amenityId,
        ));
      },
    );
  }

  Future<void> _onLoadAmenityStats(
    LoadAmenityStatsEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    if (state is AmenitiesLoaded) {
      final currentState = state as AmenitiesLoaded;
      final result = await repository.getAmenityStats();

      result.fold(
        (_) {}, // تجاهل الأخطاء
        (stats) {
          emit(currentState.copyWith(stats: stats));
        },
      );
    }
  }

  Future<void> _onSearchAmenities(
    SearchAmenitiesEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    add(LoadAmenitiesEvent(
      pageNumber: 1,
      pageSize: _currentPageSize,
      searchTerm: event.searchTerm,
      isAssigned: _currentIsAssigned,
      isFree: _currentIsFree,
    ));
  }

  Future<void> _onSelectAmenity(
    SelectAmenityEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    if (state is AmenitiesLoaded) {
      final currentState = state as AmenitiesLoaded;
      final selectedAmenity = currentState.amenities.items
          .firstWhere((amenity) => amenity.id == event.amenityId);
      emit(currentState.copyWith(selectedAmenity: selectedAmenity));
    }
  }

  Future<void> _onDeselectAmenity(
    DeselectAmenityEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    if (state is AmenitiesLoaded) {
      final currentState = state as AmenitiesLoaded;
      emit(currentState.copyWith(clearSelectedAmenity: true));
    }
  }

  Future<void> _onLoadPopularAmenities(
    LoadPopularAmenitiesEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    if (state is AmenitiesLoaded) {
      final currentState = state as AmenitiesLoaded;
      final result = await repository.getPopularAmenities(limit: event.limit);

      result.fold(
        (_) {}, // تجاهل الأخطاء
        (amenities) {
          emit(currentState.copyWith(popularAmenities: amenities));
        },
      );
    }
  }

  Future<void> _onRefreshAmenities(
    RefreshAmenitiesEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    add(LoadAmenitiesEvent(
      pageNumber: _currentPageNumber,
      pageSize: _currentPageSize,
      searchTerm: _currentSearchTerm,
      isAssigned: _currentIsAssigned,
      isFree: _currentIsFree,
    ));
  }

  Future<void> _onChangePage(
    ChangePageEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    add(LoadAmenitiesEvent(
      pageNumber: event.pageNumber,
      pageSize: _currentPageSize,
      searchTerm: _currentSearchTerm,
      isAssigned: _currentIsAssigned,
      isFree: _currentIsFree,
    ));
  }

  Future<void> _onChangePageSize(
    ChangePageSizeEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    add(LoadAmenitiesEvent(
      pageNumber: 1,
      pageSize: event.pageSize,
      searchTerm: _currentSearchTerm,
      isAssigned: _currentIsAssigned,
      isFree: _currentIsFree,
    ));
  }

  Future<void> _onApplyFilters(
    ApplyFiltersEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    add(LoadAmenitiesEvent(
      pageNumber: 1,
      pageSize: _currentPageSize,
      searchTerm: _currentSearchTerm,
      isAssigned: event.isAssigned,
      isFree: event.isFree,
    ));
  }

  Future<void> _onClearFilters(
    ClearFiltersEvent event,
    Emitter<AmenitiesState> emit,
  ) async {
    add(LoadAmenitiesEvent(
      pageNumber: 1,
      pageSize: _currentPageSize,
      searchTerm: null,
      isAssigned: null,
      isFree: null,
    ));
  }
}