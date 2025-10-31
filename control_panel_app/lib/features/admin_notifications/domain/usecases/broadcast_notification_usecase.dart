import 'package:bookn_cp_app/features/admin_notifications/domain/repositories/admin_notifications_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';

class BroadcastAdminNotificationUseCase {
  final AdminNotificationsRepository repository;
  BroadcastAdminNotificationUseCase(this.repository);

  Future<Either<Failure, int>> call({
    required String type,
    required String title,
    required String message,
    bool targetAll = false,
    List<String>? userIds,
    List<String>? roles,
    DateTime? scheduledFor,
    String? channelId,
  }) =>
      repository.broadcast(
        type: type,
        title: title,
        message: message,
        targetAll: targetAll,
        userIds: userIds,
        roles: roles,
        scheduledFor: scheduledFor,
        channelId: channelId,
      );
}
