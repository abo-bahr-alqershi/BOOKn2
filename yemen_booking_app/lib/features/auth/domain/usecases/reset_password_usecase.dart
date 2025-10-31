import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(
      emailOrPhone: params.emailOrPhone,
    );
  }
}

class ResetPasswordParams extends Equatable {
  final String emailOrPhone;

  const ResetPasswordParams({
    required this.emailOrPhone,
  });

  @override
  List<Object?> get props => [emailOrPhone];
}