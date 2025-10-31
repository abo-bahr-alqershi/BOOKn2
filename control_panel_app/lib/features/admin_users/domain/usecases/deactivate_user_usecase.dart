import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/users_repository.dart';

class DeactivateUserUseCase implements UseCase<bool, DeactivateUserParams> {
  final UsersRepository repository;

  DeactivateUserUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeactivateUserParams params) {
    return repository.deactivateUser(params.userId);
  }
}

class DeactivateUserParams extends Equatable {
  final String userId;

  const DeactivateUserParams({required this.userId});

  @override
  List<Object> get props => [userId];
}