// lib/features/admin_audit_logs/domain/usecases/get_admin_activity_logs_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/audit_log.dart';
import '../repositories/audit_logs_repository.dart';

class GetAdminActivityLogsUseCase
    implements UseCase<PaginatedResult<AuditLog>, AdminActivityLogsQuery> {
  final AuditLogsRepository repository;

  GetAdminActivityLogsUseCase({required this.repository});

  @override
  Future<Either<Failure, PaginatedResult<AuditLog>>> call(
      AdminActivityLogsQuery params) async {
    return await repository.getAdminActivityLogs(params);
  }
}