import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<AuthResponse, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResponse>> call(LoginParams params) async {
    return await repository.login(
      emailOrPhone: params.emailOrPhone,
      password: params.password,
      rememberMe: params.rememberMe,
    );
  }
}

class LoginParams extends Equatable {
  final String emailOrPhone;
  final String password;
  final bool rememberMe;

  const LoginParams({
    required this.emailOrPhone,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [emailOrPhone, password, rememberMe];
}