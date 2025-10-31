// lib/features/admin_audit_logs/presentation/bloc/audit_logs_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/audit_log.dart';

abstract class AuditLogsEvent extends Equatable {
  const AuditLogsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAuditLogsEvent extends AuditLogsEvent {
  final AuditLogsQuery query;

  const LoadAuditLogsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class LoadMoreAuditLogsEvent extends AuditLogsEvent {
  const LoadMoreAuditLogsEvent();
}

class RefreshAuditLogsEvent extends AuditLogsEvent {
  const RefreshAuditLogsEvent();
}

class FilterAuditLogsEvent extends AuditLogsEvent {
  final String? userId;
  final DateTime? from;
  final DateTime? to;
  final String? operationType;
  final String? searchTerm;

  const FilterAuditLogsEvent({
    this.userId,
    this.from,
    this.to,
    this.operationType,
    this.searchTerm,
  });

  @override
  List<Object?> get props => [userId, from, to, operationType, searchTerm];
}

class ExportAuditLogsEvent extends AuditLogsEvent {
  final AuditLogsQuery query;

  const ExportAuditLogsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class SelectAuditLogEvent extends AuditLogsEvent {
  final AuditLog auditLog;

  const SelectAuditLogEvent({required this.auditLog});

  @override
  List<Object?> get props => [auditLog];
}

class LoadAuditLogDetailsEvent extends AuditLogsEvent {
  final String auditLogId;

  const LoadAuditLogDetailsEvent({required this.auditLogId});

  @override
  List<Object?> get props => [auditLogId];
}

class ClearFiltersEvent extends AuditLogsEvent {
  const ClearFiltersEvent();
}