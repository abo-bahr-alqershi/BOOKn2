import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load notifications
class LoadNotificationsEvent extends NotificationEvent {
  final int page;
  final int limit;
  final String? type;
  final bool refresh;

  const LoadNotificationsEvent({
    this.page = 1,
    this.limit = 20,
    this.type,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, limit, type, refresh];
}

/// Event to mark a notification as read
class MarkNotificationAsReadEvent extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsReadEvent({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

/// Event to mark all notifications as read
class MarkAllNotificationsAsReadEvent extends NotificationEvent {
  const MarkAllNotificationsAsReadEvent();
}

/// Event to dismiss a notification
class DismissNotificationEvent extends NotificationEvent {
  final String notificationId;

  const DismissNotificationEvent({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

/// Event to load notification settings
class LoadNotificationSettingsEvent extends NotificationEvent {
  const LoadNotificationSettingsEvent();
}

/// Event to update notification settings
class UpdateNotificationSettingsEvent extends NotificationEvent {
  final Map<String, bool> settings;

  const UpdateNotificationSettingsEvent({required this.settings});

  @override
  List<Object> get props => [settings];
}

/// Event to load unread count
class LoadUnreadCountEvent extends NotificationEvent {
  const LoadUnreadCountEvent();
}