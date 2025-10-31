import 'package:bookn_cp_app/features/admin_notifications/domain/repositories/admin_notifications_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';

class CreateAdminNotificationUseCase {
  final AdminNotificationsRepository repository;
  CreateAdminNotificationUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String type,
    required String title,
    required String message,
    required String recipientId,
  }) =>
      repository.create(
          type: type, title: title, message: message, recipientId: recipientId);
}
