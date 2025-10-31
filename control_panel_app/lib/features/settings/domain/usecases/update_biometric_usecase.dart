import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/settings_repository.dart';

class UpdateBiometricUseCase implements UseCase<bool, UpdateBiometricParams> {
  final SettingsRepository repository;

  UpdateBiometricUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateBiometricParams params) async {
    return await repository.updateBiometric(params.enabled);
  }
}

class UpdateBiometricParams extends Equatable {
  final bool enabled;

  const UpdateBiometricParams({required this.enabled});

  @override
  List<Object> get props => [enabled];
}
