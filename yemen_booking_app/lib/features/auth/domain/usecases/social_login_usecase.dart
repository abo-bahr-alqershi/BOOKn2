import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class SocialLoginUseCase implements UseCase<AuthResponse, SocialLoginParams> {
  final AuthRepository repository;

  SocialLoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResponse>> call(SocialLoginParams params) async {
    return await repository.socialLogin(
      provider: params.provider,
      token: params.token,
    );
  }
}

class SocialLoginParams extends Equatable {
  final String provider; // google | facebook
  final String token;

  const SocialLoginParams({required this.provider, required this.token});

  @override
  List<Object?> get props => [provider, token];
}
