// lib/features/admin_audit_logs/domain/usecases/export_audit_logs_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/audit_log.dart';
import '../repositories/audit_logs_repository.dart';

class ExportAuditLogsUseCase
    implements UseCase<List<AuditLog>, AuditLogsQuery> {
  final AuditLogsRepository repository;

  ExportAuditLogsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<AuditLog>>> call(AuditLogsQuery params) async {
    return await repository.exportAuditLogs(params);
  }
}