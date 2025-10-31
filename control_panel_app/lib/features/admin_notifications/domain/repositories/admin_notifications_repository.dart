import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/admin_notification.dart';

abstract class AdminNotificationsRepository {
  Future<Either<Failure, String>> create({
    required String type,
    required String title,
    required String message,
    required String recipientId,
  });

  Future<Either<Failure, int>> broadcast({
    required String type,
    required String title,
    required String message,
    bool targetAll = false,
    List<String>? userIds,
    List<String>? roles,
    DateTime? scheduledFor,
    String? channelId,
  });

  Future<Either<Failure, bool>> delete(String notificationId);

  Future<Either<Failure, bool>> resend(String notificationId);

  Future<Either<Failure, PaginatedResult<AdminNotificationEntity>>> getSystem({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? status,
  });

  Future<Either<Failure, PaginatedResult<AdminNotificationEntity>>> getUser({
    required String userId,
    int page = 1,
    int pageSize = 20,
    bool? isRead,
  });

  Future<Either<Failure, Map<String, int>>> getStats({DateTime? startDate, DateTime? endDate});
}

