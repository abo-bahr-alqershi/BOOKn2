// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditLogModel _$AuditLogModelFromJson(Map<String, dynamic> json) =>
    AuditLogModel(
      id: json['id'] as String,
      tableName: json['tableName'] as String,
      action: json['action'] as String,
      recordId: json['recordId'] as String,
      recordName: json['recordName'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      changes: json['changes'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String,
      oldValues: json['oldValues'] as Map<String, dynamic>?,
      newValues: json['newValues'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isSlowOperation: json['isSlowOperation'] as bool,
    );

Map<String, dynamic> _$AuditLogModelToJson(AuditLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tableName': instance.tableName,
      'action': instance.action,
      'recordId': instance.recordId,
      'recordName': instance.recordName,
      'userId': instance.userId,
      'username': instance.username,
      'changes': instance.changes,
      'timestamp': instance.timestamp.toIso8601String(),
      'notes': instance.notes,
      'oldValues': instance.oldValues,
      'newValues': instance.newValues,
      'metadata': instance.metadata,
      'isSlowOperation': instance.isSlowOperation,
    };
