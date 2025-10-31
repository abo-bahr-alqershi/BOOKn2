import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class UpdateNotificationSettingsUseCase 
    implements UseCase<bool, UpdateNotificationSettingsParams> {
  final SettingsRepository repository;

  UpdateNotificationSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateNotificationSettingsParams params) async {
    return await repository.updateNotificationSettings(params.settings);
  }
}

class UpdateNotificationSettingsParams extends Equatable {
  final NotificationSettings settings;

  const UpdateNotificationSettingsParams({required this.settings});

  @override
  List<Object> get props => [settings];
}