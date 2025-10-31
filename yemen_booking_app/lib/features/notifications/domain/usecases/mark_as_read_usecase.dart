import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class MarkAsReadUseCase implements UseCase<void, MarkAsReadParams> {
  final NotificationRepository repository;

  MarkAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkAsReadParams params) async {
    if (params.notificationId == null) {
      return await repository.markAllAsRead();
    } else {
      return await repository.markAsRead(params.notificationId!);
    }
  }
}

class MarkAsReadParams extends Equatable {
  final String? notificationId;

  const MarkAsReadParams({this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}