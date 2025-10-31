abstract class AdminNotificationsEvent {
  const AdminNotificationsEvent();
}

class LoadSystemNotificationsEvent extends AdminNotificationsEvent {
  final int page;
  final int pageSize;
  final String? type;
  final String? status;
  const LoadSystemNotificationsEvent({this.page = 1, this.pageSize = 20, this.type, this.status});
}

class LoadUserNotificationsEvent extends AdminNotificationsEvent {
  final String userId;
  final int page;
  final int pageSize;
  final bool? isRead;
  const LoadUserNotificationsEvent({required this.userId, this.page = 1, this.pageSize = 20, this.isRead});
}

class CreateAdminNotificationEvent extends AdminNotificationsEvent {
  final String type;
  final String title;
  final String message;
  final String recipientId;
  const CreateAdminNotificationEvent({required this.type, required this.title, required this.message, required this.recipientId});
}

class BroadcastAdminNotificationEvent extends AdminNotificationsEvent {
  final String type;
  final String title;
  final String message;
  final bool targetAll;
  final List<String>? userIds;
  final List<String>? roles;
  final DateTime? scheduledFor;
  final String? channelId;
  const BroadcastAdminNotificationEvent({
    required this.type,
    required this.title,
    required this.message,
    this.targetAll = false,
    this.userIds,
    this.roles,
    this.scheduledFor,
    this.channelId,
  });
}

class DeleteAdminNotificationEvent extends AdminNotificationsEvent {
  final String notificationId;
  const DeleteAdminNotificationEvent(this.notificationId);
}

class ResendAdminNotificationEvent extends AdminNotificationsEvent {
  final String notificationId;
  const ResendAdminNotificationEvent(this.notificationId);
}

class LoadAdminNotificationsStatsEvent extends AdminNotificationsEvent {
  const LoadAdminNotificationsStatsEvent();
}

