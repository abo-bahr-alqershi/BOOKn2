import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/users_repository.dart';

class ActivateUserUseCase implements UseCase<bool, ActivateUserParams> {
  final UsersRepository repository;

  ActivateUserUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ActivateUserParams params) {
    return repository.activateUser(params.userId);
  }
}

class ActivateUserParams extends Equatable {
  final String userId;

  const ActivateUserParams({required this.userId});

  @override
  List<Object> get props => [userId];
}