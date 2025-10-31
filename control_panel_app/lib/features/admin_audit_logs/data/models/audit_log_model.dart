// lib/features/admin_audit_logs/data/models/audit_log_model.dart

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/audit_log.dart';

part 'audit_log_model.g.dart';

@JsonSerializable()
class AuditLogModel extends AuditLog {
  const AuditLogModel({
    required String id,
    required String tableName,
    required String action,
    required String recordId,
    required String recordName,
    required String userId,
    required String username,
    required String changes,
    required DateTime timestamp,
    required String notes,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    Map<String, dynamic>? metadata,
    required bool isSlowOperation,
  }) : super(
          id: id,
          tableName: tableName,
          action: action,
          recordId: recordId,
          recordName: recordName,
          userId: userId,
          username: username,
          changes: changes,
          timestamp: timestamp,
          notes: notes,
          oldValues: oldValues,
          newValues: newValues,
          metadata: metadata,
          isSlowOperation: isSlowOperation,
        );

  factory AuditLogModel.fromJson(Map<String, dynamic> json) =>
      _$AuditLogModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuditLogModelToJson(this);

  factory AuditLogModel.fromEntity(AuditLog entity) {
    return AuditLogModel(
      id: entity.id,
      tableName: entity.tableName,
      action: entity.action,
      recordId: entity.recordId,
      recordName: entity.recordName,
      userId: entity.userId,
      username: entity.username,
      changes: entity.changes,
      timestamp: entity.timestamp,
      notes: entity.notes,
      oldValues: entity.oldValues,
      newValues: entity.newValues,
      metadata: entity.metadata,
      isSlowOperation: entity.isSlowOperation,
    );
  }
}