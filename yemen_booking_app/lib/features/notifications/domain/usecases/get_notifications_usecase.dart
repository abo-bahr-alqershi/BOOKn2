import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase implements UseCase<PaginatedResult<NotificationEntity>, GetNotificationsParams> {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<NotificationEntity>>> call(GetNotificationsParams params) async {
    return await repository.getNotifications(
      page: params.page,
      limit: params.limit,
      type: params.type,
    );
  }
}

class GetNotificationsParams extends Equatable {
  final int page;
  final int limit;
  final String? type;

  const GetNotificationsParams({
    this.page = 1,
    this.limit = 20,
    this.type,
  });

  @override
  List<Object?> get props => [page, limit, type];
}