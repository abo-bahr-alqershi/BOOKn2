// lib/features/admin_audit_logs/domain/repositories/audit_logs_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/audit_log.dart';

abstract class AuditLogsRepository {
  Future<Either<Failure, PaginatedResult<AuditLog>>> getAuditLogs(
      AuditLogsQuery query);
  Future<Either<Failure, PaginatedResult<AuditLog>>> getCustomerActivityLogs(
      CustomerActivityLogsQuery query);
  Future<Either<Failure, PaginatedResult<AuditLog>>> getPropertyActivityLogs(
      PropertyActivityLogsQuery query);
  Future<Either<Failure, PaginatedResult<AuditLog>>> getAdminActivityLogs(
      AdminActivityLogsQuery query);
  Future<Either<Failure, List<AuditLog>>> exportAuditLogs(
      AuditLogsQuery query);

  /// Get single audit log details including heavy fields
  Future<Either<Failure, AuditLog>> getAuditLogDetails(String auditLogId);
}