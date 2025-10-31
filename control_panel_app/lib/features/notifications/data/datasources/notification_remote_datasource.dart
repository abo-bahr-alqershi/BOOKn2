import 'dart:convert';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/models/result_dto.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/request_logger.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../services/local_storage_service.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<PaginatedResult<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
  });

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead({String? userId});

  Future<void> dismissNotification(String notificationId);

  Future<Map<String, bool>> getNotificationSettings({String? userId});

  Future<void> updateNotificationSettings(Map<String, bool> settings, {String? userId});

  Future<int> getUnreadCount({String? userId});
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;
  final LocalStorageService? localStorage;
  final AuthLocalDataSource? authLocalDataSource;

  NotificationRemoteDataSourceImpl({
    required this.apiClient,
    this.localStorage,
    this.authLocalDataSource,
  });

  Future<String?> _resolveUserId({String? explicitUserId}) async {
    if (explicitUserId != null && explicitUserId.isNotEmpty) return explicitUserId;
    try {
      final cachedUser = await authLocalDataSource?.getCachedUser();
      if (cachedUser != null && cachedUser.userId.isNotEmpty) return cachedUser.userId;
    } catch (_) {}
    try {
      final stored = localStorage?.getData(StorageConstants.userId)?.toString();
      if (stored != null && stored.isNotEmpty) return stored;
    } catch (_) {}
    return null;
  }

  @override
  Future<PaginatedResult<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    const requestName = 'notifications.getNotifications';
    logRequestStart(requestName, details: {
      'page': page,
      'limit': limit,
      if (type != null) 'type': type,
    });
    try {
      final userId = await _resolveUserId();
      final normalizedType = _normalizeTypeFilter(type);
      final response = await apiClient.get(
        '/api/client/notifications',
        queryParameters: {
          if (userId != null) 'userId': userId,
          'pageNumber': page,
          'pageSize': limit,
          if (normalizedType != null) 'type': normalizedType,
        },
      );
      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final result = ResultDto.fromJson(response.data as Map<String, dynamic>, (map) => map);
        final dynamic rawData = result.data;
        final Map<String, dynamic> dataMap =
            rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};

        final List<dynamic> rawItems = (dataMap['items'] as List<dynamic>?) ??
            (dataMap['data'] as List<dynamic>?) ??
            <dynamic>[];

        final items = rawItems
            .where((e) => e != null)
            .map((e) => NotificationModel.fromJson(
                e is Map<String, dynamic> ? e : <String, dynamic>{}))
            .toList();

        final int pageNumber = (dataMap['pageNumber'] as int?) ??
            (dataMap['page'] as int?) ??
            page;
        final int pageSize = (dataMap['pageSize'] as int?) ??
            (dataMap['limit'] as int?) ??
            limit;
        final int totalCount = (dataMap['totalCount'] as int?) ??
            (dataMap['total'] as int?) ??
            items.length;

        return PaginatedResult<NotificationModel>(
          items: items,
          pageNumber: pageNumber,
          pageSize: pageSize,
          totalCount: totalCount,
        );
      }

      return const PaginatedResult(items: [], pageNumber: 1, pageSize: 20, totalCount: 0);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    const requestName = 'notifications.markAsRead';
    logRequestStart(requestName, details: {'notificationId': notificationId});
    try {
      final userId = await _resolveUserId();
      await apiClient.put(
        '/api/client/notifications/mark-as-read',
        data: {
          'notificationId': notificationId,
          if (userId != null) 'userId': userId,
        },
      );
      logRequestSuccess(requestName);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead({String? userId}) async {
    const requestName = 'notifications.markAllAsRead';
    logRequestStart(requestName, details: {'userId': userId ?? ''});
    try {
      final resolvedUserId = await _resolveUserId(explicitUserId: userId);
      await apiClient.put(
        '/api/client/notifications/mark-all-as-read',
        data: {
          if (resolvedUserId != null) 'userId': resolvedUserId,
        },
      );
      logRequestSuccess(requestName);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> dismissNotification(String notificationId) async {
    const requestName = 'notifications.dismissNotification';
    logRequestStart(requestName, details: {'notificationId': notificationId});
    try {
      final userId = await _resolveUserId();
      await apiClient.delete(
        '/api/client/notifications/dismiss',
        data: {
          'notificationId': notificationId,
          if (userId != null) 'userId': userId,
        },
      );
      logRequestSuccess(requestName);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<Map<String, bool>> getNotificationSettings({String? userId}) async {
    const requestName = 'notifications.getNotificationSettings';
    final resolvedUserId = await _resolveUserId(explicitUserId: userId);
    logRequestStart(requestName, details: {'userId': resolvedUserId ?? ''});
    try {
      final response = await apiClient.get(
        '/api/client/settings',
        queryParameters: {
          if (resolvedUserId != null) 'userId': resolvedUserId,
        },
      );
      logRequestSuccess(requestName, statusCode: response.statusCode);
      if (response.statusCode == 200) {
        final result = ResultDto.fromJson(response.data as Map<String, dynamic>, (raw) => raw);
        final data = (result.data is Map<String, dynamic>) ? result.data as Map<String, dynamic> : <String, dynamic>{};
        final remote = (data['notificationSettings'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final additional = (data['additionalSettings'] as Map<String, dynamic>?) ?? <String, dynamic>{};

        final cached = await _getCachedUiSettings();

        bool _b(dynamic v, bool d) => v is bool ? v : d;
        final bookingGroup = _b(remote['bookingNotifications'], true);
        final promoGroup = _b(remote['promotionalNotifications'], true);
        final push = _b(remote['pushNotifications'], true);
        final email = _b(remote['emailNotifications'], true);
        final sms = _b(remote['smsNotifications'], false);

        return <String, bool>{
          // map group to UI granular toggles with cached fallback
          'booking_confirmed': cached['booking_confirmed'] ?? bookingGroup,
          'booking_cancelled': cached['booking_cancelled'] ?? bookingGroup,
          'payment_received': cached['payment_received'] ?? true,
          'payment_refunded': cached['payment_refunded'] ?? true,
          'promotion_new': cached['promotion_new'] ?? promoGroup,
          'system_updates': cached['system_updates'] ?? false,
          // channels
          'push_notifications': push,
          'email_notifications': email,
          'sms_notifications': sms,
          // biometric preference surfaced to UI optional readers
          'biometric_enabled': (additional['biometricEnabled'] == true),
        };
      }
    return {};
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateNotificationSettings(Map<String, bool> settings, {String? userId}) async {
    const requestName = 'notifications.updateNotificationSettings';
    final resolvedUserId = await _resolveUserId(explicitUserId: userId);
    logRequestStart(requestName, details: {'userId': resolvedUserId ?? ''});
    try {
      final payload = _mapSettingsToCommand(settings);
      if (resolvedUserId != null) {
        payload['userId'] = resolvedUserId;
      }
      await apiClient.put(
        '/api/client/notifications/settings',
        data: payload,
      );
      logRequestSuccess(requestName);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount({String? userId}) async {
    const requestName = 'notifications.getUnreadCount';
    final resolvedUserId = await _resolveUserId(explicitUserId: userId);
    logRequestStart(requestName, details: {'userId': resolvedUserId ?? ''});
    try {
      final response = await apiClient.get(
        '/api/client/notifications/summary',
        queryParameters: {
          if (resolvedUserId != null) 'userId': resolvedUserId,
        },
      );
      logRequestSuccess(requestName, statusCode: response.statusCode);
      if (response.statusCode == 200) {
        final result = ResultDto.fromJson(response.data, (json) => json);
        final data = result.data ?? {};
        return (data['unreadCount'] as int?) ?? 0;
      }
      return 0;
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      rethrow;
    }
  }

  Map<String, dynamic> _mapSettingsToCommand(Map<String, bool> settings) {
    bool getVal(List<String> keys, bool fallback) {
      for (final k in keys) {
        final v = settings[k];
        if (v != null) return v;
      }
      return fallback;
    }

    // Derive group toggles from UI granular toggles as needed
    final bookingGroup = getVal([
      'bookingNotifications',
      'booking',
      'booking_confirmed',
      'booking_cancelled',
    ], true);
    final promoGroup = getVal([
      'promotionalNotifications',
      'promotional',
      'promotion_new',
    ], true);

    return {
      'bookingNotifications': bookingGroup,
      'promotionalNotifications': promoGroup,
      'reviewResponseNotifications': getVal(['reviewResponseNotifications', 'reviewResponses'], true),
      'emailNotifications': getVal(['emailNotifications', 'email', 'email_notifications'], true),
      'smsNotifications': getVal(['smsNotifications', 'sms', 'sms_notifications'], false),
      'pushNotifications': getVal(['pushNotifications', 'push', 'push_notifications'], true),
    };
  }

  String? _normalizeTypeFilter(String? type) {
    if (type == null) return null;
    final l = type.trim().toLowerCase();
    if (l.isEmpty || l == 'all') return null;
    // Do not send high-level category filters to backend; filter locally
    if (l == 'booking' || l == 'payment' || l == 'promotion' || l == 'system') {
      return null;
    }
    return type;
  }

  Future<Map<String, bool>> _getCachedUiSettings() async {
    try {
      final raw = localStorage?.getData('notification_settings');
      if (raw is Map<String, dynamic>) {
        return raw.map((key, value) => MapEntry(key, value == true));
      }
      if (raw is String && raw.isNotEmpty) {
        try {
          final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
          return m.map((key, value) => MapEntry(key, value == true));
        } catch (_) {}
      }
    } catch (_) {}
    return <String, bool>{};
  }
}