import '../../../notifications/domain/entities/notification.dart'
    as common_notif;
import '../../domain/entities/admin_notification.dart';

abstract class AdminNotificationsState {
  final Map<String, int>? stats;
  final String? statsError;

  const AdminNotificationsState({this.stats, this.statsError});
}

class AdminNotificationsInitial extends AdminNotificationsState {
  const AdminNotificationsInitial({super.stats, super.statsError});
}

class AdminNotificationsLoading extends AdminNotificationsState {
  const AdminNotificationsLoading({super.stats, super.statsError});
}

class AdminNotificationsSubmitting extends AdminNotificationsState {
  final String action; // create, broadcast, resend, delete
  const AdminNotificationsSubmitting(this.action, {super.stats, super.statsError});
}

class AdminSystemNotificationsLoaded extends AdminNotificationsState {
  final List<AdminNotificationEntity> items;
  final int totalCount;
  const AdminSystemNotificationsLoaded({
    required this.items,
    required this.totalCount,
    super.stats,
    super.statsError,
  });
}

class AdminUserNotificationsLoaded extends AdminNotificationsState {
  final List<AdminNotificationEntity> items;
  final int totalCount;
  const AdminUserNotificationsLoaded({
    required this.items,
    required this.totalCount,
    super.stats,
    super.statsError,
  });
}

class AdminNotificationsSuccess extends AdminNotificationsState {
  final String message;
  const AdminNotificationsSuccess(
    this.message, {
    super.stats,
    super.statsError,
  });
}

class AdminNotificationsError extends AdminNotificationsState {
  final String message;
  const AdminNotificationsError(
    this.message, {
    super.stats,
    super.statsError,
  });
}
