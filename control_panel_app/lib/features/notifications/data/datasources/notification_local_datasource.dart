import 'dart:convert';
import '../../../../services/local_storage_service.dart';
import '../models/notification_model.dart';

abstract class NotificationLocalDataSource {
  Future<List<NotificationModel>> getCachedNotifications();
  Future<void> cacheNotifications(List<NotificationModel> notifications);
  Future<void> clearCache();
  Future<Map<String, bool>> getNotificationSettings();
  Future<void> saveNotificationSettings(Map<String, bool> settings);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final LocalStorageService localStorage;

  NotificationLocalDataSourceImpl({required this.localStorage});

  @override
  Future<List<NotificationModel>> getCachedNotifications() async {
    final raw = localStorage.getData('notifications_cache')?.toString();
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = raw is String ? raw : raw.toString();
      final List<dynamic> list = decoded is String ? (decoded.startsWith('[') ? (jsonDecode(decoded) as List<dynamic>) : <dynamic>[]) : <dynamic>[];
      return list
          .whereType<Map>()
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
    return [];
    }
  }

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    try {
      final data = notifications.map((n) => n.toJson()).toList();
      await localStorage.saveData('notifications_cache', data);
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    try {
      await localStorage.removeData('notifications_cache');
    } catch (_) {}
  }

  @override
  Future<Map<String, bool>> getNotificationSettings() async {
    final raw = localStorage.getData('notification_settings');
    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) => MapEntry(key, value == true));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
        return m.map((key, value) => MapEntry(key, value == true));
      } catch (_) {}
    }
    return {};
  }

  @override
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    try {
      final existing = await getNotificationSettings();
      // Merge to preserve any keys not present in current update
      final merged = Map<String, bool>.from(existing)..addAll(settings);
      await localStorage.saveData('notification_settings', merged);
    } catch (_) {
      await localStorage.saveData('notification_settings', settings);
    }
  }
}