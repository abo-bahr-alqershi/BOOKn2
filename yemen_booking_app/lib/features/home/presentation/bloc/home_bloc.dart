// lib/features/home/presentation/bloc/home_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_sections_usecase.dart';
import '../../domain/usecases/get_section_data_usecase.dart';
import '../../domain/usecases/get_property_types_usecase.dart';
import '../../domain/usecases/get_unit_types_with_fields_usecase.dart';
import '../../domain/usecases/get_property_types_with_units_usecase.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/data_sync_service.dart';
import '../../../../services/filter_storage_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetSectionsUseCase getSectionsUseCase;
  final GetSectionDataUseCase getSectionDataUseCase;
  final GetPropertyTypesUseCase getPropertyTypesUseCase;
  final GetUnitTypesWithFieldsUseCase getUnitTypesWithFieldsUseCase;
  final GetPropertyTypesWithUnitsUseCase? getPropertyTypesWithUnitsUseCase;
  final HomeRepository homeRepository;
  final DataSyncService dataSyncService;
  final FilterStorageService filterStorageService;

  HomeBloc({
    required this.getSectionsUseCase,
    required this.getSectionDataUseCase,
    required this.getPropertyTypesUseCase,
    required this.getUnitTypesWithFieldsUseCase,
    this.getPropertyTypesWithUnitsUseCase,
    required this.homeRepository,
    required this.dataSyncService,
    required this.filterStorageService,
  }) : super(const HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<LoadSectionsEvent>(_onLoadSections);
    on<LoadSectionDataEvent>(_onLoadSectionData);
    on<LoadPropertyTypesEvent>(_onLoadPropertyTypes);
    on<LoadUnitTypesEvent>(_onLoadUnitTypes);
    on<RecordSectionImpressionEvent>(_onRecordSectionImpression);
    on<RecordSectionInteractionEvent>(_onRecordSectionInteraction);
    on<UpdateSearchQueryEvent>(_onUpdateSearchQuery);
    on<ClearSearchEvent>(_onClearSearch);
    on<UpdatePropertyTypeFilterEvent>(_onUpdatePropertyTypeFilter);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
    on<LoadMoreSectionDataEvent>(_onLoadMoreSectionData);
    on<UpdateUnitTypeSelectionEvent>(_onUpdateUnitTypeSelection);
    on<UpdateDynamicFieldValuesEvent>(_onUpdateDynamicFieldValues);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    try {
      // Load sections first
      final sectionsResult = await getSectionsUseCase(
        GetSectionsParams(forceRefresh: event.forceRefresh),
      );

      if (sectionsResult.isLeft()) {
        final failure = sectionsResult.fold((l) => l, (r) => null);
        emit(HomeError(message: _mapFailureToMessage(failure!)));
        return;
      }

      final sections = sectionsResult.fold((l) => null, (r) => r.items)!;
      final filteredSections = sections
          .where((s) => ((s.contentType ?? '').toLowerCase() != 'none'))
          .toList();

      // Load property types (+ unit types if available) to avoid extra roundtrips
      List<dynamic> propertyTypes = [];
      Map<String, List<dynamic>> unitTypesMap = {};
      bool combinedSucceeded = false;
      if (getPropertyTypesWithUnitsUseCase != null) {
        try {
          final combined = await getPropertyTypesWithUnitsUseCase!(NoParams());
          combined.fold(
            (_) {},
            (data) {
              propertyTypes = data.propertyTypes;
              unitTypesMap = data.unitTypesByPropertyTypeId.map(
                (k, v) => MapEntry(k, v),
              );
              combinedSucceeded = true;
            },
          );
        } catch (_) {}
      }
      if (!combinedSucceeded) {
        try {
          final propertyTypesResult = await getPropertyTypesUseCase(NoParams());
          propertyTypes = propertyTypesResult.fold(
            (l) => <dynamic>[],
            (r) => r,
          );
          // Prefetch unit types for all property types to avoid selection-time fetches
          if (propertyTypes.isNotEmpty) {
            final List<dynamic> pts = propertyTypes;
            final List<Future<void>> tasks = [];
            for (final pt in pts) {
              final String ptId = (pt as dynamic).id as String;
              tasks.add(() async {
                final res = await getUnitTypesWithFieldsUseCase(
                  GetUnitTypesParams(propertyTypeId: ptId),
                );
                res.fold(
                  (failure) => null,
                  (units) {
                    unitTypesMap[ptId] = units;
                  },
                );
              }());
            }
            await Future.wait(tasks);
            combinedSucceeded = true;
          }
        } catch (e) {
          // Fallback to local data if remote fails
          try {
            final localPropertyTypes = await dataSyncService.getPropertyTypes();
            propertyTypes = localPropertyTypes;
          } catch (localError) {
            print('Error loading property types from both remote and local: $localError');
            propertyTypes = <dynamic>[];
          }
        }
      }

      // Load section data for each active section
      final Map<String, dynamic> sectionData = {};
      final Map<String, bool> sectionsLoadingMore = {};

      for (final section in filteredSections) {
        sectionsLoadingMore[section.id] = false;
        final initialPageSize = section.homeItemsCount ?? section.itemsToShow;
        final sectionDataResult = await getSectionDataUseCase(
          GetSectionDataParams(
            sectionId: section.id,
            pageNumber: 1,
            pageSize: initialPageSize,
          ),
        );
        if (sectionDataResult.isRight()) {
          final data = sectionDataResult.fold((l) => null, (r) => r)!;
          sectionData[section.id] = data;
        }
      }

      // Load saved selections (property type, unit type, dates, guests, dynamic fields)
      final saved = filterStorageService.getHomeSelections();
      String? savedPropertyTypeId = saved['propertyTypeId'] as String?;
      String? savedUnitTypeId = saved['unitTypeId'] as String?;
      Map<String, dynamic> savedDynamicValues =
          Map<String, dynamic>.from(saved['dynamicFieldValues'] as Map<String, dynamic>? ?? const {});
      final Map<String, dynamic> savedDynamicFilters =
          Map<String, dynamic>.from(saved['dynamicFieldFilters'] as Map<String, dynamic>? ?? const {});
      // Extract dates and guests explicitly so we can preserve them if needed
      final DateTime? savedCheckIn = saved['checkIn'] as DateTime?;
      final DateTime? savedCheckOut = saved['checkOut'] as DateTime?;
      final int savedAdults = (saved['adults'] as int?) ?? 0;
      final int savedChildren = (saved['children'] as int?) ?? 0;

      // Validate saved property/unit against loaded data
      bool propertyExists = false;
      if (savedPropertyTypeId != null) {
        propertyExists = propertyTypes.any((pt) => (pt as dynamic).id == savedPropertyTypeId);
      }
      if (!propertyExists) {
        // Property type is no longer valid; clear selection IDs but keep dates/guests
        savedPropertyTypeId = null;
        savedUnitTypeId = null;
        savedDynamicValues = {
          if (savedCheckIn != null) 'checkIn': savedCheckIn,
          if (savedCheckOut != null) 'checkOut': savedCheckOut,
          'adults': savedAdults,
          'children': savedChildren,
        };
      } else {
        final units = unitTypesMap[savedPropertyTypeId] ?? const [];
        final unitExists = savedUnitTypeId != null && units.any((u) => (u as dynamic).id == savedUnitTypeId);
        if (!unitExists) {
          // Unit type is no longer valid; keep dates/guests but drop dynamic filters
          savedUnitTypeId = null;
          savedDynamicValues = {
            if (savedCheckIn != null) 'checkIn': savedCheckIn,
            if (savedCheckOut != null) 'checkOut': savedCheckOut,
            'adults': savedAdults,
            'children': savedChildren,
          };
        } else {
          // Unit type exists; keep all saved dynamic values (dates/guests + dynamic filters)
          // Ensure dates/guests are present even if dynamic values map was missing them
          savedDynamicValues = {
            ...savedDynamicFilters,
            if (savedCheckIn != null) 'checkIn': savedCheckIn,
            if (savedCheckOut != null) 'checkOut': savedCheckOut,
            'adults': savedAdults,
            'children': savedChildren,
          };
        }
      }

      emit(HomeLoaded(
        sections: filteredSections,
        sectionData: sectionData.cast(),
        propertyTypes: propertyTypes.cast(),
        unitTypes: unitTypesMap.map((k, v) => MapEntry(k, v.cast())),
        combinedUnitsPreloaded: combinedSucceeded,
        selectedPropertyTypeId: savedPropertyTypeId,
        selectedUnitTypeId: savedUnitTypeId,
        dynamicFieldValues: savedDynamicValues,
        sectionsLoadingMore: sectionsLoadingMore,
      ));
    } catch (e) {
      emit(HomeError(message: 'حدث خطأ غير متوقع: $e'));
    }
  }

  Future<void> _onLoadSections(
    LoadSectionsEvent event,
    Emitter<HomeState> emit,
  ) async {
    final sectionsResult = await getSectionsUseCase(
      GetSectionsParams(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        target: event.target,
        type: event.type,
        forceRefresh: event.forceRefresh,
      ),
    );

    sectionsResult.fold(
      (failure) => emit(HomeError(message: _mapFailureToMessage(failure))),
      (sections) {
        if (state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          final filtered = sections.items
              .where((s) => ((s.contentType ?? '').toLowerCase() != 'none'))
              .toList();
          emit(currentState.copyWith(sections: filtered));
        }
      },
    );
  }

  Future<void> _onLoadSectionData(
    LoadSectionDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(
        sectionsLoadingMore: {
          ...currentState.sectionsLoadingMore,
          event.sectionId: true,
        },
      ));
    }

    final sectionDataResult = await getSectionDataUseCase(
      GetSectionDataParams(
        sectionId: event.sectionId,
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        forceRefresh: event.forceRefresh,
      ),
    );

    sectionDataResult.fold(
      (failure) => emit(SectionError(
        sectionId: event.sectionId,
        message: _mapFailureToMessage(failure),
      )),
      (data) {
        if (state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          emit(currentState.copyWith(
            sectionData: {
              ...currentState.sectionData,
              event.sectionId: data,
            },
            sectionsLoadingMore: {
              ...currentState.sectionsLoadingMore,
              event.sectionId: false,
            },
          ));
        } else {
          emit(SectionDataLoaded(sectionId: event.sectionId, data: data));
        }
      },
    );
  }

  Future<void> _onLoadPropertyTypes(
    LoadPropertyTypesEvent event,
    Emitter<HomeState> emit,
  ) async {
    final result = await getPropertyTypesUseCase(NoParams());

    result.fold(
      (failure) {
        if (state is HomeLoaded) {
          // Don't emit error if we're in loaded state, just log it
        } else {
          emit(HomeError(message: _mapFailureToMessage(failure)));
        }
      },
      (propertyTypes) {
        if (state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          emit(currentState.copyWith(propertyTypes: propertyTypes.cast()));
        } else {
          emit(PropertyTypesLoaded(propertyTypes: propertyTypes.cast()));
        }
      },
    );
  }

  Future<void> _onLoadUnitTypes(
    LoadUnitTypesEvent event,
    Emitter<HomeState> emit,
  ) async {
    // If we already have unit types for this property type, do nothing
    if (state is HomeLoaded) {
      final s = state as HomeLoaded;
      final cached = s.unitTypes[event.propertyTypeId];
      if (cached != null && cached.isNotEmpty) {
        return;
      }
    }

    final result = await getUnitTypesWithFieldsUseCase(
      GetUnitTypesParams(propertyTypeId: event.propertyTypeId),
    );

    result.fold(
      (failure) {
        // Handle error silently or emit specific error
      },
      (unitTypes) {
        if (state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          emit(currentState.copyWith(
            unitTypes: {
              ...currentState.unitTypes,
              event.propertyTypeId: unitTypes.cast(),
            },
          ));
        } else {
          emit(UnitTypesLoaded(
            propertyTypeId: event.propertyTypeId,
            unitTypes: unitTypes.cast(),
          ));
        }
      },
    );
  }

  Future<void> _onRecordSectionImpression(
    RecordSectionImpressionEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Fire and forget analytics
    homeRepository.recordSectionImpression(sectionId: event.sectionId);
  }

  Future<void> _onRecordSectionInteraction(
    RecordSectionInteractionEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Fire and forget analytics
    homeRepository.recordSectionInteraction(
      sectionId: event.sectionId,
      interactionType: event.interactionType,
      itemId: event.itemId,
      metadata: event.metadata,
    );
  }

  Future<void> _onUpdateSearchQuery(
    UpdateSearchQueryEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(searchQuery: ''));
    }
  }

  Future<void> _onUpdatePropertyTypeFilter(
    UpdatePropertyTypeFilterEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(
        selectedPropertyTypeId: event.propertyTypeId,
        selectedUnitTypeId: null,
        dynamicFieldValues: const {},
      ));
      await filterStorageService.saveHomeSelections(
        propertyTypeId: event.propertyTypeId,
        unitTypeId: null,
        dynamicFieldValues: const {},
      );
      
      // Load unit types for selected property type
      if (event.propertyTypeId != null) {
        // No network fetch on selection; rely on preloaded unitTypes from initial load
      }
    }
  }

  void _onUpdateUnitTypeSelection(
    UpdateUnitTypeSelectionEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(
        selectedUnitTypeId: event.unitTypeId,
        dynamicFieldValues: const {},
      ));
      filterStorageService.saveHomeSelections(
        propertyTypeId: currentState.selectedPropertyTypeId,
        unitTypeId: event.unitTypeId,
        dynamicFieldValues: const {},
      );
    }
  }

  void _onUpdateDynamicFieldValues(
    UpdateDynamicFieldValuesEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final newValues = Map<String, dynamic>.from(event.values);
      emit(currentState.copyWith(dynamicFieldValues: newValues));
      filterStorageService.saveHomeSelections(
        propertyTypeId: currentState.selectedPropertyTypeId,
        unitTypeId: currentState.selectedUnitTypeId,
        dynamicFieldValues: newValues,
      );
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(isRefreshing: true));
      
      add(const LoadHomeDataEvent(forceRefresh: true));
    }
  }

  Future<void> _onLoadMoreSectionData(
    LoadMoreSectionDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final existingData = currentState.sectionData[event.sectionId];
      
      if (existingData != null) {
        final nextPage = (existingData.pageNumber ?? 1) + 1;
        add(LoadSectionDataEvent(
          sectionId: event.sectionId,
          pageNumber: nextPage,
        ));
      }
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case (ServerFailure):
        return 'حدث خطأ في الخادم. يرجى المحاولة مرة أخرى.';
      case (CacheFailure):
        return 'حدث خطأ في تحميل البيانات المحفوظة.';
      case (NetworkFailure):
        return 'يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
      default:
        return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }
}