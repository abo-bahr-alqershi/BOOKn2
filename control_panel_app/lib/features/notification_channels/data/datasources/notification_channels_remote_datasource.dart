import 'package:bookn_cp_app/core/network/api_client.dart';
import '../../domain/entities/notification_channel.dart';

class NotificationChannelsRemoteDataSource {
  final ApiClient apiClient;
  NotificationChannelsRemoteDataSource({required this.apiClient});

  Future<List<NotificationChannel>> getChannels({
    String? search,
    String? type,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await apiClient.get(
      '/api/admin/notification-channels',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (search != null) 'search': search,
        if (type != null) 'type': type,
        if (isActive != null) 'isActive': isActive,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['data'] as List).cast<Map<String, dynamic>>();
    return items.map(_parseChannel).toList();
  }

  Future<NotificationChannel> getChannel(String id) async {
    final res = await apiClient.get('/api/admin/notification-channels/$id');
    final data = res.data['data'] as Map<String, dynamic>;
    final channel = data['channel'] ?? data; // دعم الشكلين
    return _parseChannel(Map<String, dynamic>.from(channel));
  }

  Future<NotificationChannel> createChannel({
    required String name,
    required String identifier,
    String? description,
    String? type,
    String? icon,
    String? color,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'identifier': identifier,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
    };
    final res = await apiClient.post('/api/admin/notification-channels', data: body);
    return _parseChannel(Map<String, dynamic>.from(res.data['data']));
  }

  Future<NotificationChannel> updateChannel(
    String id, {
    String? name,
    String? description,
    bool? isActive,
    String? icon,
    String? color,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (isActive != null) body['isActive'] = isActive;
    if (icon != null) body['icon'] = icon;
    if (color != null) body['color'] = color;

    final res = await apiClient.put('/api/admin/notification-channels/$id', data: body);
    return _parseChannel(Map<String, dynamic>.from(res.data['data']));
  }

  Future<bool> deleteChannel(String id) async {
    final res = await apiClient.delete('/api/admin/notification-channels/$id');
    return (res.data['success'] as bool?) ?? true;
  }

  Future<List<UserChannelSubscription>> getChannelSubscribers(
    String channelId, {
    bool activeOnly = true,
  }) async {
    final res = await apiClient.get(
      '/api/admin/notification-channels/$channelId/subscribers',
      queryParameters: {'activeOnly': activeOnly},
    );
    final items = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return items.map(_parseSubscription).toList();
  }

  Future<int> addSubscribers(String channelId, List<String> userIds) async {
    final res = await apiClient.post(
      '/api/admin/notification-channels/$channelId/subscribers',
      data: {'userIds': userIds},
    );
    return (res.data['data']?['addedCount'] ?? 0) as int;
  }

  Future<int> removeSubscribers(String channelId, List<String> userIds) async {
    final res = await apiClient.delete(
      '/api/admin/notification-channels/$channelId/subscribers',
      data: {'userIds': userIds},
    );
    return (res.data['data']?['removedCount'] ?? 0) as int;
  }

  Future<ChannelNotificationHistory> sendChannelNotification(
    String channelId, {
    required String title,
    required String content,
    String? type,
    Map<String, String>? data,
  }) async {
    final res = await apiClient.post(
      '/api/admin/notification-channels/$channelId/send',
      data: {
        'title': title,
        'content': content,
        if (type != null) 'type': type,
        if (data != null) 'data': data,
      },
    );
    return _parseHistory(Map<String, dynamic>.from(res.data['data']));
  }

  Future<List<ChannelNotificationHistory>> getChannelHistory(
    String channelId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await apiClient.get(
      '/api/admin/notification-channels/$channelId/history',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final items = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return items.map(_parseHistory).toList();
  }

  Future<ChannelStatistics> getStatistics() async {
    final res = await apiClient.get('/api/admin/notification-channels/statistics');
    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return ChannelStatistics(
      totalChannels: (data['total_channels'] ?? 0) as int,
      activeChannels: (data['active_channels'] ?? 0) as int,
      totalSubscriptions: (data['total_subscriptions'] ?? 0) as int,
      activeSubscriptions: (data['active_subscriptions'] ?? 0) as int,
      totalNotificationsSent: (data['total_notifications_sent'] ?? 0) as int,
      channelsByType: Map<String, int>.from(data['channels_by_type'] ?? {}),
      topActiveChannels: (data['top_active_channels'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map((e) => ChannelSummary(
                id: (e['id'] ?? '').toString(),
                name: (e['name'] ?? '').toString(),
                notificationsSentCount: (e['notificationsSentCount'] ?? 0) as int,
                subscribersCount: (e['subscribersCount'] ?? 0) as int,
              ))
          .toList(),
    );
  }

  Future<Map<String, dynamic>> getChannelStatistics(String channelId) async {
    final res = await apiClient.get('/api/admin/notification-channels/$channelId');
    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return Map<String, dynamic>.from(data['statistics'] ?? {});
  }

  Future<List<NotificationChannel>> getUserChannels(String userId) async {
    final res = await apiClient.get('/api/admin/notification-channels/user/$userId');
    final items = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return items.map(_parseChannel).toList();
  }

  Future<bool> updateUserSubscriptions(
    String userId, {
    List<String>? channelsToAdd,
    List<String>? channelsToRemove,
  }) async {
    final body = <String, dynamic>{};
    if (channelsToAdd != null) body['channelsToAdd'] = channelsToAdd;
    if (channelsToRemove != null) body['channelsToRemove'] = channelsToRemove;

    final res = await apiClient.put(
      '/api/admin/notification-channels/user/$userId/subscriptions',
      data: body,
    );
    // consider success true on 200
    return (res.data is Map) ? ((res.data['success'] as bool?) ?? true) : true;
  }

  // Parsers
  NotificationChannel _parseChannel(Map<String, dynamic> json) {
    return NotificationChannel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      identifier: (json['identifier'] ?? '').toString(),
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
      isActive: (json['isActive'] ?? true) as bool,
      isPrivate: (json['isPrivate'] ?? false) as bool,
      isDeletable: (json['isDeletable'] ?? true) as bool,
      type: (json['type'] ?? 'CUSTOM').toString(),
      allowedRoles: List<String>.from(json['allowedRoles'] ?? const []),
      subscribersCount: (json['subscribersCount'] ?? 0) as int,
      notificationsSentCount: (json['notificationsSentCount'] ?? 0) as int,
      lastNotificationAt: json['lastNotificationAt'] != null
          ? DateTime.tryParse(json['lastNotificationAt'].toString())
          : null,
      createdBy: json['createdBy']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  UserChannelSubscription _parseSubscription(Map<String, dynamic> json) {
    return UserChannelSubscription(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      channelId: (json['channelId'] ?? '').toString(),
      userName: json['userName']?.toString(),
      userEmail: json['userEmail']?.toString(),
      isActive: (json['isActive'] ?? true) as bool,
      isMuted: (json['isMuted'] ?? false) as bool,
      subscribedAt: DateTime.tryParse(json['subscribedAt']?.toString() ?? '') ?? DateTime.now(),
      unsubscribedAt: json['unsubscribedAt'] != null
          ? DateTime.tryParse(json['unsubscribedAt'].toString())
          : null,
      notificationsReceivedCount: (json['notificationsReceivedCount'] ?? 0) as int,
      lastNotificationReceivedAt: json['lastNotificationReceivedAt'] != null
          ? DateTime.tryParse(json['lastNotificationReceivedAt'].toString())
          : null,
      notes: json['notes']?.toString(),
    );
  }

  ChannelNotificationHistory _parseHistory(Map<String, dynamic> json) {
    return ChannelNotificationHistory(
      id: (json['id'] ?? '').toString(),
      channelId: (json['channelId'] ?? '').toString(),
      notificationId: json['notificationId']?.toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      type: (json['type'] ?? 'INFO').toString(),
      recipientsCount: (json['recipientsCount'] ?? 0) as int,
      successfulDeliveries: (json['successfulDeliveries'] ?? 0) as int,
      failedDeliveries: (json['failedDeliveries'] ?? 0) as int,
      senderId: json['senderId']?.toString(),
      senderName: json['senderName']?.toString(),
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
