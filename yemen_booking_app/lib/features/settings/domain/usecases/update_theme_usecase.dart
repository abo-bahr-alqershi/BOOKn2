import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/settings_repository.dart';

class UpdateThemeUseCase implements UseCase<bool, UpdateThemeParams> {
  final SettingsRepository repository;

  UpdateThemeUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateThemeParams params) async {
    return await repository.updateTheme(params.isDarkMode);
  }
}

class UpdateThemeParams extends Equatable {
  final bool isDarkMode;

  const UpdateThemeParams({required this.isDarkMode});

  @override
  List<Object> get props => [isDarkMode];
}