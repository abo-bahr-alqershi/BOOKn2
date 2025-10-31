import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, PaginatedResult<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
  });

  Future<Either<Failure, void>> markAsRead(String notificationId);

  Future<Either<Failure, void>> markAllAsRead();

  Future<Either<Failure, void>> dismissNotification(String notificationId);

  Future<Either<Failure, Map<String, bool>>> getNotificationSettings();

  Future<Either<Failure, void>> updateNotificationSettings(Map<String, bool> settings);

  Future<Either<Failure, int>> getUnreadCount();
}