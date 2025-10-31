import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class UpdateNotificationSettingsUseCase implements UseCase<void, UpdateNotificationSettingsParams> {
  final NotificationRepository repository;

  UpdateNotificationSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateNotificationSettingsParams params) async {
    return await repository.updateNotificationSettings(params.settings);
  }
}

class UpdateNotificationSettingsParams extends Equatable {
  final Map<String, bool> settings;

  const UpdateNotificationSettingsParams({required this.settings});

  @override
  List<Object> get props => [settings];
}