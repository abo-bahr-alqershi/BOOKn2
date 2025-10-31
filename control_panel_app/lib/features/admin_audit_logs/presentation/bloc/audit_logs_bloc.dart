// lib/features/admin_audit_logs/presentation/bloc/audit_logs_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/usecases/get_audit_logs_usecase.dart';
import '../../domain/usecases/export_audit_logs_usecase.dart';
import '../../domain/repositories/audit_logs_repository.dart';
import 'audit_logs_event.dart';
import 'audit_logs_state.dart';

class AuditLogsBloc extends Bloc<AuditLogsEvent, AuditLogsState> {
  final GetAuditLogsUseCase getAuditLogsUseCase;
  final ExportAuditLogsUseCase exportAuditLogsUseCase;
  final AuditLogsRepository? auditLogsRepository;

  static const int _pageSize = 20;

  AuditLogsBloc({
    required this.getAuditLogsUseCase,
    required this.exportAuditLogsUseCase,
    AuditLogsRepository? repository,
  })  : auditLogsRepository = repository,
        super(AuditLogsInitial()) {
    on<LoadAuditLogsEvent>(_onLoadAuditLogs);
    on<LoadMoreAuditLogsEvent>(_onLoadMoreAuditLogs);
    on<RefreshAuditLogsEvent>(_onRefreshAuditLogs);
    on<FilterAuditLogsEvent>(_onFilterAuditLogs);
    on<ExportAuditLogsEvent>(_onExportAuditLogs);
    on<SelectAuditLogEvent>(_onSelectAuditLog);
    on<LoadAuditLogDetailsEvent>(_onLoadAuditLogDetails);
    on<ClearFiltersEvent>(_onClearFilters);
  }

  Future<void> _onLoadAuditLogs(
    LoadAuditLogsEvent event,
    Emitter<AuditLogsState> emit,
  ) async {
    emit(AuditLogsLoading());

    final query = event.query.copyWith(
      pageNumber: event.query.pageNumber ?? 1,
      pageSize: event.query.pageSize ?? _pageSize,
    );

    final result = await getAuditLogsUseCase(query);

    result.fold(
      (failure) => emit(AuditLogsError(message: failure.message)),
      (paginatedResult) {
        emit(AuditLogsLoaded(
          auditLogs: paginatedResult.items,
          totalCount: paginatedResult.totalCount,
          currentPage: paginatedResult.pageNumber,
          pageSize: paginatedResult.pageSize,
          hasReachedMax: paginatedResult.items.length < _pageSize,
          currentQuery: query,
        ));
      },
    );
  }

  Future<void> _onLoadMoreAuditLogs(
    LoadMoreAuditLogsEvent event,
    Emitter<AuditLogsState> emit,
  ) async {
    if (state is AuditLogsLoaded) {
      final currentState = state as AuditLogsLoaded;
      
      if (currentState.hasReachedMax) return;

      final nextPage = currentState.currentPage + 1;
      final query = currentState.currentQuery.copyWith(
        pageNumber: nextPage,
      );

      final result = await getAuditLogsUseCase(query);

      result.fold(
        (failure) => emit(AuditLogsError(message: failure.message)),
        (paginatedResult) {
          emit(currentState.copyWith(
            auditLogs: [...currentState.auditLogs, ...paginatedResult.items],
            currentPage: nextPage,
            hasReachedMax: paginatedResult.items.length < _pageSize,
          ));
        },
      );
    }
  }

  Future<void> _onRefreshAuditLogs(
    RefreshAuditLogsEvent event,
    Emitter<AuditLogsState> emit,
  ) async {
    if (state is AuditLogsLoaded) {
      final currentState = state as AuditLogsLoaded;
      add(LoadAuditLogsEvent(query: currentState.currentQuery));
    } else {
      add(LoadAuditLogsEvent(query: const AuditLogsQuery()));
    }
  }

  Future<void> _onFilterAuditLogs(
    FilterAuditLogsEvent event,
    Emitter<AuditLogsState> emit,
  ) async {
    final query = AuditLogsQuery(
      pageNumber: 1,
      pageSize: _pageSize,
      userId: event.userId,
      from: event.from,
      to: event.to,
      operationType: event.operationType,
      searchTerm: event.searchTerm,
    );

    add(LoadAuditLogsEvent(query: query));
  }

  Future<void> _onExportAuditLogs(
    ExportAuditLogsEvent event,
    Emitter<AuditLogsState> emit,
  ) async {
    emit(AuditLogsExporting());

    final result = await exportAuditLogsUseCase(event.query);

    result.fold(
      (failure) => emit(AuditLogsError(message: failure.message)),
      (logs) => emit(AuditLogsExported(exportedLogs: logs)),
    );
  }

  void _onSelectAuditLog(
    SelectAuditLogEvent event,
    Emitter<AuditLogsState> emit,
  ) {
    if (state is AuditLogsLoaded) {
      final currentState = state as AuditLogsLoaded;
      emit(currentState.copyWith(selectedLog: event.auditLog));
    }
  }

  Future<void> _onLoadAuditLogDetails(
    LoadAuditLogDetailsEvent event,
    Emitter<AuditLogsState> emit,
  ) async {
    if (auditLogsRepository == null) return;
    if (state is! AuditLogsLoaded) return;
    final currentState = state as AuditLogsLoaded;
    emit(currentState.copyWith(loadingDetails: true));
    final result = await auditLogsRepository!.getAuditLogDetails(event.auditLogId);
    result.fold(
      (_) => emit(currentState.copyWith(loadingDetails: false)),
      (log) => emit(currentState.copyWith(selectedLog: log, loadingDetails: false)),
    );
  }

  void _onClearFilters(
    ClearFiltersEvent event,
    Emitter<AuditLogsState> emit,
  ) {
    add(LoadAuditLogsEvent(query: const AuditLogsQuery()));
  }

  // Extension method for AuditLogsQuery
}

extension on AuditLogsQuery {
  AuditLogsQuery copyWith({
    int? pageNumber,
    int? pageSize,
    String? userId,
    DateTime? from,
    DateTime? to,
    String? searchTerm,
    String? operationType,
    String? entityType,
    String? recordId,
    String? relatedToBookingId,
  }) {
    return AuditLogsQuery(
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      userId: userId ?? this.userId,
      from: from ?? this.from,
      to: to ?? this.to,
      searchTerm: searchTerm ?? this.searchTerm,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      recordId: recordId ?? this.recordId,
      relatedToBookingId: relatedToBookingId ?? this.relatedToBookingId,
    );
  }
}