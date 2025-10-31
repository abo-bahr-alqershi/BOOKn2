// lib/features/admin_audit_logs/presentation/bloc/audit_logs_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/audit_log.dart';

abstract class AuditLogsState extends Equatable {
  const AuditLogsState();

  @override
  List<Object?> get props => [];
}

class AuditLogsInitial extends AuditLogsState {}

class AuditLogsLoading extends AuditLogsState {}

class AuditLogsLoaded extends AuditLogsState {
  final List<AuditLog> auditLogs;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasReachedMax;
  final AuditLog? selectedLog;
  final AuditLogsQuery currentQuery;
  final bool loadingDetails;

  const AuditLogsLoaded({
    required this.auditLogs,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.hasReachedMax,
    this.selectedLog,
    required this.currentQuery,
    this.loadingDetails = false,
  });

  AuditLogsLoaded copyWith({
    List<AuditLog>? auditLogs,
    int? totalCount,
    int? currentPage,
    int? pageSize,
    bool? hasReachedMax,
    AuditLog? selectedLog,
    AuditLogsQuery? currentQuery,
    bool? loadingDetails,
  }) {
    return AuditLogsLoaded(
      auditLogs: auditLogs ?? this.auditLogs,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selectedLog: selectedLog ?? this.selectedLog,
      currentQuery: currentQuery ?? this.currentQuery,
      loadingDetails: loadingDetails ?? this.loadingDetails,
    );
  }

  @override
  List<Object?> get props => [
        auditLogs,
        totalCount,
        currentPage,
        pageSize,
        hasReachedMax,
        selectedLog,
        currentQuery,
        loadingDetails,
      ];
}

class AuditLogsError extends AuditLogsState {
  final String message;

  const AuditLogsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuditLogsExporting extends AuditLogsState {}

class AuditLogsExported extends AuditLogsState {
  final List<AuditLog> exportedLogs;

  const AuditLogsExported({required this.exportedLogs});

  @override
  List<Object?> get props => [exportedLogs];
}