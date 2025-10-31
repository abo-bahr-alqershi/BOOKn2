import 'package:bookn_cp_app/core/models/paginated_result.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import '../../domain/entities/admin_notification.dart';
import '../models/admin_notification_model.dart';

class AdminNotificationsRemoteDataSource {
  final ApiClient apiClient;
  AdminNotificationsRemoteDataSource({required this.apiClient});

  Future<String> create({
    required String type,
    required String title,
    required String message,
    required String recipientId,
  }) async {
    final res = await apiClient.post('/api/admin/notifications', data: {
      'type': type,
      'title': title,
      'message': message,
      'recipientId': recipientId,
    });
    return (res.data['data'] ?? res.data['result']).toString();
  }

  Future<int> broadcast({
    required String type,
    required String title,
    required String message,
    bool targetAll = false,
    List<String>? userIds,
    List<String>? roles,
    DateTime? scheduledFor,
    String? channelId,
  }) async {
    final res = await apiClient.post('/api/admin/notifications/broadcast', data: {
      'type': type,
      'title': title,
      'message': message,
      'targetAllUsers': targetAll,
      if (userIds != null) 'targetUserIds': userIds,
      if (roles != null) 'targetRoles': roles,
      if (scheduledFor != null) 'scheduledFor': scheduledFor.toUtc().toIso8601String(),
      if (channelId != null) 'targetChannelId': channelId,
    });
    return (res.data['data'] ?? res.data['result']) as int;
  }

  Future<bool> delete(String notificationId) async {
    final res = await apiClient.delete('/api/admin/notifications/$notificationId');
    return (res.data['data'] ?? res.data['result']) as bool? ?? true;
  }

  Future<bool> resend(String notificationId) async {
    final res = await apiClient.post('/api/admin/notifications/$notificationId/resend');
    return (res.data['data'] ?? res.data['result']) as bool? ?? true;
  }

  Future<PaginatedResult<AdminNotificationEntity>> getSystem({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? status,
  }) async {
    final res = await apiClient.get('/api/admin/notifications', queryParameters: {
      'pageNumber': page,
      'pageSize': pageSize,
      if (type != null) 'notificationType': type,
      if (status != null) 'status': status,
    });
    final data = res.data;
    final items = (data['items'] as List)
        .map((e) => AdminNotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      items: items,
      pageNumber: data['pageNumber'] ?? page,
      pageSize: data['pageSize'] ?? pageSize,
      totalCount: data['totalCount'] ?? items.length,
    );
  }

  Future<PaginatedResult<AdminNotificationEntity>> getUser({
    required String userId,
    int page = 1,
    int pageSize = 20,
    bool? isRead,
  }) async {
    final res = await apiClient.get('/api/admin/notifications/user/$userId', queryParameters: {
      'pageNumber': page,
      'pageSize': pageSize,
      if (isRead != null) 'isRead': isRead,
    });
    final data = res.data;
    final items = (data['items'] as List)
        .map((e) => AdminNotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      items: items,
      pageNumber: data['pageNumber'] ?? page,
      pageSize: data['pageSize'] ?? pageSize,
      totalCount: data['totalCount'] ?? items.length,
    );
  }

  Future<Map<String, int>> getStats({DateTime? startDate, DateTime? endDate}) async {
    final query = <String, dynamic>{};
    if (startDate != null) query['from'] = startDate.toUtc().toIso8601String();
    if (endDate != null) query['to'] = endDate.toUtc().toIso8601String();
    final res = await apiClient.get('/api/admin/notifications/stats', queryParameters: query);
    final data = Map<String, dynamic>.from(res.data as Map);
    return data.map((key, value) => MapEntry(key, (value as num).toInt()));
  }
}

