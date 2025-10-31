// lib/features/admin_audit_logs/domain/usecases/get_property_activity_logs_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/audit_log.dart';
import '../repositories/audit_logs_repository.dart';

class GetPropertyActivityLogsUseCase
    implements UseCase<PaginatedResult<AuditLog>, PropertyActivityLogsQuery> {
  final AuditLogsRepository repository;

  GetPropertyActivityLogsUseCase({required this.repository});

  @override
  Future<Either<Failure, PaginatedResult<AuditLog>>> call(
      PropertyActivityLogsQuery params) async {
    return await repository.getPropertyActivityLogs(params);
  }
}