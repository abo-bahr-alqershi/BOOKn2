// lib/features/admin_audit_logs/data/repositories/audit_logs_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_logs_repository.dart';
import '../datasources/audit_logs_local_datasource.dart';
import '../datasources/audit_logs_remote_datasource.dart';

class AuditLogsRepositoryImpl implements AuditLogsRepository {
  final AuditLogsRemoteDataSource remoteDataSource;
  final AuditLogsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuditLogsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PaginatedResult<AuditLog>>> getAuditLogs(
      AuditLogsQuery query) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAuditLogs(query);
        await localDataSource.cacheAuditLogs(result.items);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      try {
        final cachedLogs = await localDataSource.getCachedAuditLogs();
        return Right(PaginatedResult(
          items: cachedLogs,
          totalCount: cachedLogs.length,
          pageNumber: 1,
          pageSize: cachedLogs.length,
        ));
      } catch (e) {
        return Left(CacheFailure('No cached data available'));
      }
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<AuditLog>>> getCustomerActivityLogs(
      CustomerActivityLogsQuery query) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCustomerActivityLogs(query);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<AuditLog>>> getPropertyActivityLogs(
      PropertyActivityLogsQuery query) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPropertyActivityLogs(query);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<AuditLog>>> getAdminActivityLogs(
      AdminActivityLogsQuery query) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAdminActivityLogs(query);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<AuditLog>>> exportAuditLogs(
      AuditLogsQuery query) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.exportAuditLogs(query);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AuditLog>> getAuditLogDetails(String auditLogId) async {
    try {
      final result = await remoteDataSource.getAuditLogDetails(auditLogId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}