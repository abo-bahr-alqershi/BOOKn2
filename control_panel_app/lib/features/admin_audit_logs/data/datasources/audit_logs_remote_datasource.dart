// lib/features/admin_audit_logs/data/datasources/audit_logs_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/audit_log.dart';
import '../models/audit_log_model.dart';

abstract class AuditLogsRemoteDataSource {
  Future<PaginatedResult<AuditLog>> getAuditLogs(AuditLogsQuery query);
  Future<PaginatedResult<AuditLog>> getCustomerActivityLogs(
      CustomerActivityLogsQuery query);
  Future<PaginatedResult<AuditLog>> getPropertyActivityLogs(
      PropertyActivityLogsQuery query);
  Future<PaginatedResult<AuditLog>> getAdminActivityLogs(
      AdminActivityLogsQuery query);
  Future<List<AuditLog>> exportAuditLogs(AuditLogsQuery query);
  Future<AuditLog> getAuditLogDetails(String auditLogId);
}

class AuditLogsRemoteDataSourceImpl implements AuditLogsRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/audit-logs';

  AuditLogsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PaginatedResult<AuditLog>> getAuditLogs(AuditLogsQuery query) async {
    try {
      final queryParams = query.toMap();
      
      final response = await apiClient.get(
        _baseEndpoint,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        // التحقق من البنية الصحيحة للاستجابة
        if (response.data is Map && response.data.containsKey('items')) {
          final items = (response.data['items'] as List? ?? [])
              .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
              .toList();

          return PaginatedResult<AuditLog>(
            items: items,
            totalCount: response.data['totalCount'] ?? 0,
            pageNumber: response.data['pageNumber'] ?? 1,
            pageSize: response.data['pageSize'] ?? 20,
          );
        } else {
          // إذا كانت البنية مختلفة، حاول تحليلها مباشرة
          return PaginatedResult<AuditLog>.fromJson(
            response.data,
            (json) => AuditLogModel.fromJson(json),
          );
        }
      } else {
        throw const ServerException('Invalid response format');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch audit logs',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Future<AuditLog> getAuditLogDetails(String auditLogId) async {
    try {
      final response = await apiClient.get('$_baseEndpoint/$auditLogId/details');
      if (response.data is Map<String, dynamic>) {
        return AuditLogModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerException('Invalid response for audit log details');
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch audit log details',
      );
    }
  }

  @override
  Future<PaginatedResult<AuditLog>> getCustomerActivityLogs(
      CustomerActivityLogsQuery query) async {
    try {
      final queryParams = query.toMap();
      
      final response = await apiClient.get(_baseEndpoint, queryParameters: queryParams);

      if (response.data != null) {
        if (response.data is Map && response.data.containsKey('items')) {
          final items = (response.data['items'] as List? ?? [])
              .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
              .toList();

          return PaginatedResult<AuditLog>(
            items: items,
            totalCount: response.data['totalCount'] ?? 0,
            pageNumber: response.data['pageNumber'] ?? 1,
            pageSize: response.data['pageSize'] ?? 20,
          );
        } else {
          return PaginatedResult<AuditLog>.fromJson(
            response.data,
            (json) => AuditLogModel.fromJson(json),
          );
        }
      } else {
        throw const ServerException('Invalid response format');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch customer activity logs',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Future<PaginatedResult<AuditLog>> getPropertyActivityLogs(
      PropertyActivityLogsQuery query) async {
    try {
      final queryParams = query.toMap();
      
      final response = await apiClient.get(_baseEndpoint, queryParameters: queryParams);

      if (response.data != null) {
        if (response.data is Map && response.data.containsKey('items')) {
          final items = (response.data['items'] as List? ?? [])
              .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
              .toList();

          return PaginatedResult<AuditLog>(
            items: items,
            totalCount: response.data['totalCount'] ?? 0,
            pageNumber: response.data['pageNumber'] ?? 1,
            pageSize: response.data['pageSize'] ?? 20,
          );
        } else {
          return PaginatedResult<AuditLog>.fromJson(
            response.data,
            (json) => AuditLogModel.fromJson(json),
          );
        }
      } else {
        throw const ServerException('Invalid response format');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch property activity logs',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Future<PaginatedResult<AuditLog>> getAdminActivityLogs(
      AdminActivityLogsQuery query) async {
    try {
      final queryParams = query.toMap();
      
      final response = await apiClient.get(_baseEndpoint, queryParameters: queryParams);

      if (response.data != null) {
        if (response.data is Map && response.data.containsKey('items')) {
          final items = (response.data['items'] as List? ?? [])
              .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
              .toList();

          return PaginatedResult<AuditLog>(
            items: items,
            totalCount: response.data['totalCount'] ?? 0,
            pageNumber: response.data['pageNumber'] ?? 1,
            pageSize: response.data['pageSize'] ?? 20,
          );
        } else {
          return PaginatedResult<AuditLog>.fromJson(
            response.data,
            (json) => AuditLogModel.fromJson(json),
          );
        }
      } else {
        throw const ServerException('Invalid response format');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to fetch admin activity logs',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Future<List<AuditLog>> exportAuditLogs(AuditLogsQuery query) async {
    try {
      final queryParams = {...query.toMap(), 'pageSize': 10000};
      
      final response = await apiClient.get(_baseEndpoint, queryParameters: queryParams);

      if (response.data != null) {
        // التحقق من وجود isSuccess flag إذا كان API يستخدمه
        if (response.data is Map && response.data.containsKey('isSuccess')) {
          if (response.data['isSuccess'] == true) {
            final data = response.data['data'];
            if (data is List) {
              return data
                  .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
                  .toList();
            } else if (data is Map && data.containsKey('items')) {
              return (data['items'] as List? ?? [])
                  .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
                  .toList();
            }
          } else {
            throw ServerException(
              response.data['message'] ?? 'Failed to export audit logs',
            );
          }
        }
        
        // إذا لم يكن هناك isSuccess flag، حاول معالجة البيانات مباشرة
        if (response.data is List) {
          return response.data
              .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (response.data is Map && response.data.containsKey('items')) {
          return (response.data['items'] as List? ?? [])
              .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw const ServerException('Invalid export response format');
        }
      } else {
        throw const ServerException('Empty response received');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw const ServerException(
          'Export size too large. Please narrow down your filters.',
        );
      }
      throw ServerException(
        e.response?.data?['message'] ?? 'Failed to export audit logs',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Unexpected error occurred: ${e.toString()}');
    }
  }
}