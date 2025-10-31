// lib/features/admin_audit_logs/data/datasources/audit_logs_local_datasource.dart

import 'package:hive/hive.dart';
import '../../domain/entities/audit_log.dart';
import '../models/audit_log_model.dart';

abstract class AuditLogsLocalDataSource {
  Future<void> cacheAuditLogs(List<AuditLog> logs);
  Future<List<AuditLog>> getCachedAuditLogs();
  Future<void> clearCache();
}

class AuditLogsLocalDataSourceImpl implements AuditLogsLocalDataSource {
  static const String _boxName = 'audit_logs_cache';
  static const String _logsKey = 'cached_logs';

  @override
  Future<void> cacheAuditLogs(List<AuditLog> logs) async {
    final box = await Hive.openBox(_boxName);
    final jsonList = logs
        .map((log) => AuditLogModel.fromEntity(log).toJson())
        .toList();
    await box.put(_logsKey, jsonList);
  }

  @override
  Future<List<AuditLog>> getCachedAuditLogs() async {
    final box = await Hive.openBox(_boxName);
    final jsonList = box.get(_logsKey, defaultValue: <dynamic>[]) as List;
    return jsonList
        .map((json) => AuditLogModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}