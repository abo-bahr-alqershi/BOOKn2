import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../domain/entities/section.dart';
import '../../../domain/usecases/sections/get_all_sections_usecase.dart';
import '../../../domain/usecases/sections/delete_section_usecase.dart';
import '../../../domain/usecases/sections/toggle_section_status_usecase.dart';
import 'sections_list_event.dart';
import 'sections_list_state.dart';

class SectionsListBloc extends Bloc<SectionsListEvent, SectionsListState> {
  final GetAllSectionsUseCase getAllSections;
  final DeleteSectionUseCase deleteSection;
  final ToggleSectionStatusUseCase toggleStatus;

  int _pageSize = 20;
  GetAllSectionsParams _lastParams = const GetAllSectionsParams();

  SectionsListBloc({
    required this.getAllSections,
    required this.deleteSection,
    required this.toggleStatus,
  }) : super(SectionsListInitial()) {
    on<LoadSectionsEvent>(_onLoadSections);
    on<ChangeSectionsPageEvent>(_onChangePage);
    on<ApplySectionsFiltersEvent>(_onApplyFilters);
    on<ToggleSectionStatusEvent>(_onToggleStatus);
    on<DeleteSectionEvent>(_onDeleteSection);
    on<RefreshSectionsEvent>(_onRefresh);
  }

  Future<void> _onLoadSections(
    LoadSectionsEvent event,
    Emitter<SectionsListState> emit,
  ) async {
    emit(SectionsListLoading());
    _pageSize = event.pageSize ?? _pageSize;
    _lastParams = GetAllSectionsParams(
      pageNumber: event.pageNumber ?? 1,
      pageSize: _pageSize,
      target: event.target,
      type: event.type,
      contentType: event.contentType,
    );
    final result = await getAllSections(_lastParams);
    result.fold(
      (failure) => emit(SectionsListError(message: failure.message)),
      (page) => emit(SectionsListLoaded(
        page: page,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
      )),
    );
  }

  Future<void> _onChangePage(
    ChangeSectionsPageEvent event,
    Emitter<SectionsListState> emit,
  ) async {
    if (state is! SectionsListLoaded) return;
    final current = state as SectionsListLoaded;
    _lastParams = GetAllSectionsParams(
      pageNumber: event.pageNumber,
      pageSize: _pageSize,
      target: _lastParams.target,
      type: _lastParams.type,
      contentType: _lastParams.contentType,
    );
    final result = await getAllSections(_lastParams);
    result.fold(
      (failure) => emit(SectionsListError(message: failure.message)),
      (nextPage) {
        // append items to existing for smoother infinite scroll UX
        final mergedItems = <Section>[]
          ..addAll(current.page.items);
        for (final s in nextPage.items) {
          if (!mergedItems.any((x) => x.id == s.id)) mergedItems.add(s);
        }
        final merged = PaginatedResult<Section>(
          items: mergedItems,
          pageNumber: nextPage.pageNumber,
          pageSize: nextPage.pageSize,
          totalCount: nextPage.totalCount,
        );
        emit(SectionsListLoaded(
          page: merged,
          currentPage: nextPage.currentPage,
          totalPages: nextPage.totalPages,
        ));
      },
    );
  }

  Future<void> _onApplyFilters(
    ApplySectionsFiltersEvent event,
    Emitter<SectionsListState> emit,
  ) async {
    emit(SectionsListLoading());
    _lastParams = GetAllSectionsParams(
      pageNumber: 1,
      pageSize: _pageSize,
      target: event.target,
      type: event.type,
      contentType: event.contentType,
    );
    final result = await getAllSections(_lastParams);
    result.fold(
      (failure) => emit(SectionsListError(message: failure.message)),
      (page) => emit(SectionsListLoaded(
        page: page,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
      )),
    );
  }

  Future<void> _onToggleStatus(
    ToggleSectionStatusEvent event,
    Emitter<SectionsListState> emit,
  ) async {
    final res = await toggleStatus(
        ToggleSectionStatusParams(sectionId: event.sectionId, isActive: event.isActive));
    res.fold(
      (_) {},
      (_) => add(LoadSectionsEvent(
        pageNumber: _lastParams.pageNumber,
        pageSize: _lastParams.pageSize,
        target: _lastParams.target,
        type: _lastParams.type,
        contentType: _lastParams.contentType,
      )),
    );
  }

  Future<void> _onDeleteSection(
    DeleteSectionEvent event,
    Emitter<SectionsListState> emit,
  ) async {
    final res = await deleteSection(DeleteSectionParams(event.sectionId));
    res.fold(
      (_) {},
      (_) => add(LoadSectionsEvent(
        pageNumber: _lastParams.pageNumber,
        pageSize: _lastParams.pageSize,
        target: _lastParams.target,
        type: _lastParams.type,
        contentType: _lastParams.contentType,
      )),
    );
  }

  Future<void> _onRefresh(
    RefreshSectionsEvent event,
    Emitter<SectionsListState> emit,
  ) async {
    add(LoadSectionsEvent(
      pageNumber: _lastParams.pageNumber,
      pageSize: _lastParams.pageSize,
      target: _lastParams.target,
      type: _lastParams.type,
      contentType: _lastParams.contentType,
    ));
  }
}

