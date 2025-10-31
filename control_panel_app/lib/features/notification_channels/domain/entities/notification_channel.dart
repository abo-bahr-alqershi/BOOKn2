import 'package:equatable/equatable.dart';

/// كيان قناة الإشعارات
/// Notification channel entity
class NotificationChannel extends Equatable {
  final String id;
  final String name;
  final String identifier;
  final String? description;
  final String? icon;
  final String? color;
  final bool isActive;
  final bool isPrivate;
  final bool isDeletable;
  final String type; // SYSTEM, CUSTOM, ROLE_BASED, EVENT_BASED
  final List<String> allowedRoles;
  final int subscribersCount;
  final int notificationsSentCount;
  final DateTime? lastNotificationAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.identifier,
    this.description,
    this.icon,
    this.color,
    this.isActive = true,
    this.isPrivate = false,
    this.isDeletable = true,
    this.type = 'CUSTOM',
    this.allowedRoles = const [],
    this.subscribersCount = 0,
    this.notificationsSentCount = 0,
    this.lastNotificationAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    identifier,
    description,
    icon,
    color,
    isActive,
    isPrivate,
    isDeletable,
    type,
    allowedRoles,
    subscribersCount,
    notificationsSentCount,
    lastNotificationAt,
    createdBy,
    createdAt,
    updatedAt,
  ];

  /// Get FCM topic for this channel
  String get fcmTopic => 'channel_$identifier';

  /// Get display color
  String get displayColor => color ?? '#1E88E5';

  /// Get display icon
  String get displayIcon => icon ?? '📢';

  /// Check if channel is system channel
  bool get isSystem => type == 'SYSTEM';

  /// Get channel type label in Arabic
  String get typeLabel {
    switch (type) {
      case 'SYSTEM':
        return 'قناة نظام';
      case 'CUSTOM':
        return 'قناة مخصصة';
      case 'ROLE_BASED':
        return 'قناة حسب الدور';
      case 'EVENT_BASED':
        return 'قناة حسب الحدث';
      default:
        return 'قناة';
    }
  }
}

/// كيان اشتراك المستخدم في القناة
/// User channel subscription entity
class UserChannelSubscription extends Equatable {
  final String id;
  final String userId;
  final String channelId;
  final NotificationChannel? channel;
  final String? userName;
  final String? userEmail;
  final bool isActive;
  final bool isMuted;
  final DateTime subscribedAt;
  final DateTime? unsubscribedAt;
  final int notificationsReceivedCount;
  final DateTime? lastNotificationReceivedAt;
  final String? notes;

  const UserChannelSubscription({
    required this.id,
    required this.userId,
    required this.channelId,
    this.channel,
    this.userName,
    this.userEmail,
    this.isActive = true,
    this.isMuted = false,
    required this.subscribedAt,
    this.unsubscribedAt,
    this.notificationsReceivedCount = 0,
    this.lastNotificationReceivedAt,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    channelId,
    channel,
    userName,
    userEmail,
    isActive,
    isMuted,
    subscribedAt,
    unsubscribedAt,
    notificationsReceivedCount,
    lastNotificationReceivedAt,
    notes,
  ];
}

/// كيان سجل إشعارات القناة
/// Channel notification history entity
class ChannelNotificationHistory extends Equatable {
  final String id;
  final String channelId;
  final String? notificationId;
  final String title;
  final String content;
  final String type;
  final int recipientsCount;
  final int successfulDeliveries;
  final int failedDeliveries;
  final String? senderId;
  final String? senderName;
  final DateTime sentAt;

  const ChannelNotificationHistory({
    required this.id,
    required this.channelId,
    this.notificationId,
    required this.title,
    required this.content,
    this.type = 'INFO',
    this.recipientsCount = 0,
    this.successfulDeliveries = 0,
    this.failedDeliveries = 0,
    this.senderId,
    this.senderName,
    required this.sentAt,
  });

  @override
  List<Object?> get props => [
    id,
    channelId,
    notificationId,
    title,
    content,
    type,
    recipientsCount,
    successfulDeliveries,
    failedDeliveries,
    senderId,
    senderName,
    sentAt,
  ];

  /// Get success rate
  double get successRate {
    if (recipientsCount == 0) return 0;
    return (successfulDeliveries / recipientsCount) * 100;
  }

  /// Get type label in Arabic
  String get typeLabel {
    switch (type) {
      case 'INFO':
        return 'معلومات';
      case 'WARNING':
        return 'تحذير';
      case 'ERROR':
        return 'خطأ';
      case 'SUCCESS':
        return 'نجاح';
      case 'URGENT':
        return 'عاجل';
      default:
        return type;
    }
  }
}

/// إحصائيات القنوات
/// Channels statistics
class ChannelStatistics extends Equatable {
  final int totalChannels;
  final int activeChannels;
  final int totalSubscriptions;
  final int activeSubscriptions;
  final int totalNotificationsSent;
  final Map<String, int> channelsByType;
  final List<ChannelSummary> topActiveChannels;

  const ChannelStatistics({
    required this.totalChannels,
    required this.activeChannels,
    required this.totalSubscriptions,
    required this.activeSubscriptions,
    required this.totalNotificationsSent,
    required this.channelsByType,
    required this.topActiveChannels,
  });

  @override
  List<Object?> get props => [
    totalChannels,
    activeChannels,
    totalSubscriptions,
    activeSubscriptions,
    totalNotificationsSent,
    channelsByType,
    topActiveChannels,
  ];
}

/// ملخص القناة
/// Channel summary
class ChannelSummary extends Equatable {
  final String id;
  final String name;
  final int notificationsSentCount;
  final int subscribersCount;

  const ChannelSummary({
    required this.id,
    required this.name,
    required this.notificationsSentCount,
    required this.subscribersCount,
  });

  @override
  List<Object?> get props => [id, name, notificationsSentCount, subscribersCount];
}
