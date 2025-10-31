import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class GetNotificationSettingsUseCase
    implements UseCase<Map<String, bool>, GetNotificationSettingsParams> {
  final NotificationRepository repository;

  GetNotificationSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, bool>>> call(
    GetNotificationSettingsParams params,
  ) async {
    return await repository.getNotificationSettings();
  }
}

class GetNotificationSettingsParams extends Equatable {
  const GetNotificationSettingsParams();

  @override
  List<Object?> get props => [];
}
