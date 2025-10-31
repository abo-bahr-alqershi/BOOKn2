// lib/features/admin_audit_logs/domain/entities/audit_log.dart

import 'package:equatable/equatable.dart';

/// Entity representing an audit log entry
class AuditLog extends Equatable {
  final String id;
  final String tableName;
  final String action;
  final String recordId;
  final String recordName;
  final String userId;
  final String username;
  final String changes;
  final DateTime timestamp;
  final String notes;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final Map<String, dynamic>? metadata;
  final bool isSlowOperation;

  const AuditLog({
    required this.id,
    required this.tableName,
    required this.action,
    required this.recordId,
    required this.recordName,
    required this.userId,
    required this.username,
    required this.changes,
    required this.timestamp,
    required this.notes,
    this.oldValues,
    this.newValues,
    this.metadata,
    required this.isSlowOperation,
  });

  @override
  List<Object?> get props => [
        id,
        tableName,
        action,
        recordId,
        recordName,
        userId,
        username,
        changes,
        timestamp,
        notes,
        oldValues,
        newValues,
        metadata,
        isSlowOperation,
      ];

  // Helper methods
  bool get isCreate => action.toLowerCase() == 'create';
  bool get isUpdate => action.toLowerCase() == 'update';
  bool get isDelete => action.toLowerCase() == 'delete';
  
  String get actionIcon {
    switch (action.toLowerCase()) {
      case 'create':
        return 'add_circle';
      case 'update':
        return 'edit';
      case 'delete':
        return 'delete';
      case 'login':
        return 'login';
      case 'logout':
        return 'logout';
      default:
        return 'info';
    }
  }

  String get actionColor {
    switch (action.toLowerCase()) {
      case 'create':
        return '#00FF88';
      case 'update':
        return '#00D4FF';
      case 'delete':
        return '#FF3366';
      case 'login':
        return '#4FACFE';
      case 'logout':
        return '#FFB800';
      default:
        return '#667EEA';
    }
  }
}

/// Query parameters for audit logs
class AuditLogsQuery extends Equatable {
  final int? pageNumber;
  final int? pageSize;
  final String? userId;
  final DateTime? from;
  final DateTime? to;
  final String? searchTerm;
  final String? operationType;
  // Optional precise filters
  final String? entityType; // e.g., "Booking"
  final String? recordId;   // entity GUID as string
  // Aggregated filter to include related entities (e.g., payments linked to booking)
  final String? relatedToBookingId;

  const AuditLogsQuery({
    this.pageNumber,
    this.pageSize,
    this.userId,
    this.from,
    this.to,
    this.searchTerm,
    this.operationType,
    this.entityType,
    this.recordId,
    this.relatedToBookingId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (pageNumber != null) 'pageNumber': pageNumber,
      if (pageSize != null) 'pageSize': pageSize,
      if (userId != null) 'userId': userId,
      if (from != null) 'from': from!.toIso8601String(),
      if (to != null) 'to': to!.toIso8601String(),
      if (searchTerm != null) 'searchTerm': searchTerm,
      if (operationType != null) 'operationType': operationType,
      if (entityType != null) 'entityType': entityType,
      if (recordId != null) 'recordId': recordId,
      if (relatedToBookingId != null) 'relatedToBookingId': relatedToBookingId,
    };
  }

  @override
  List<Object?> get props => [
        pageNumber,
        pageSize,
        userId,
        from,
        to,
        searchTerm,
        operationType,
        entityType,
        recordId,
        relatedToBookingId,
      ];
}

/// Query for customer activity logs
class CustomerActivityLogsQuery extends Equatable {
  final int? pageNumber;
  final int? pageSize;

  const CustomerActivityLogsQuery({
    this.pageNumber,
    this.pageSize,
  });

  Map<String, dynamic> toMap() {
    return {
      if (pageNumber != null) 'pageNumber': pageNumber,
      if (pageSize != null) 'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [pageNumber, pageSize];
}

/// Query for property activity logs
class PropertyActivityLogsQuery extends Equatable {
  final String? propertyId;
  final int? pageNumber;
  final int? pageSize;

  const PropertyActivityLogsQuery({
    this.propertyId,
    this.pageNumber,
    this.pageSize,
  });

  Map<String, dynamic> toMap() {
    return {
      if (propertyId != null) 'propertyId': propertyId,
      if (pageNumber != null) 'pageNumber': pageNumber,
      if (pageSize != null) 'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [propertyId, pageNumber, pageSize];
}

/// Query for admin activity logs
class AdminActivityLogsQuery extends Equatable {
  final int pageNumber;
  final int pageSize;

  const AdminActivityLogsQuery({
    required this.pageNumber,
    required this.pageSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [pageNumber, pageSize];
}