// lib/features/admin_audit_logs/domain/usecases/get_audit_logs_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/audit_log.dart';
import '../repositories/audit_logs_repository.dart';

class GetAuditLogsUseCase
    implements UseCase<PaginatedResult<AuditLog>, AuditLogsQuery> {
  final AuditLogsRepository repository;

  GetAuditLogsUseCase({required this.repository});

  @override
  Future<Either<Failure, PaginatedResult<AuditLog>>> call(
      AuditLogsQuery params) async {
    return await repository.getAuditLogs(params);
  }
}