import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class DismissNotificationUseCase implements UseCase<void, DismissNotificationParams> {
  final NotificationRepository repository;

  DismissNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DismissNotificationParams params) async {
    return await repository.dismissNotification(params.notificationId);
  }
}

class DismissNotificationParams extends Equatable {
  final String notificationId;

  const DismissNotificationParams({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}