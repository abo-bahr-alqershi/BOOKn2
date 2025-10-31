import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/features/admin_notifications/domain/repositories/admin_notifications_repository.dart';
import 'package:bookn_cp_app/features/admin_notifications/domain/entities/admin_notification.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';

class GetUserAdminNotificationsUseCase {
  final AdminNotificationsRepository repository;
  GetUserAdminNotificationsUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<AdminNotificationEntity>>> call({
    required String userId,
    int page = 1,
    int pageSize = 20,
    bool? isRead,
  }) =>
      repository.getUser(
          userId: userId, page: page, pageSize: pageSize, isRead: isRead);
}
