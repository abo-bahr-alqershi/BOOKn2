import 'package:equatable/equatable.dart';
import '../../domain/entities/notification.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the notification bloc is first created
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// State when any notification operation is in progress
class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

/// State when notification settings are being loaded
class NotificationSettingsLoading extends NotificationState {
  const NotificationSettingsLoading();
}

/// State when notifications are successfully loaded
class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final bool hasReachedMax;
  final int currentPage;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.hasReachedMax,
    required this.currentPage,
    required this.unreadCount,
  });

  @override
  List<Object> get props =>
      [notifications, hasReachedMax, currentPage, unreadCount];

  NotificationLoaded copyWith({
    List<NotificationEntity>? notifications,
    bool? hasReachedMax,
    int? currentPage,
    int? unreadCount,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// State when only unread count is loaded/refreshed
class NotificationUnreadCountLoaded extends NotificationState {
  final int unreadCount;

  const NotificationUnreadCountLoaded({required this.unreadCount});

  @override
  List<Object?> get props => [unreadCount];
}

/// State when notification settings are loaded
class NotificationSettingsLoaded extends NotificationState {
  final Map<String, bool> settings;

  const NotificationSettingsLoaded({required this.settings});

  @override
  List<Object> get props => [settings];
}

/// State when a notification operation is successful
class NotificationOperationSuccess extends NotificationState {
  final String message;

  const NotificationOperationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

/// State when an error occurs
class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object> get props => [message];
}
