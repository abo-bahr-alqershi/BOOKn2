import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/users_repository.dart';

class AssignRoleUseCase implements UseCase<bool, AssignRoleParams> {
  final UsersRepository repository;

  AssignRoleUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(AssignRoleParams params) {
    return repository.assignRole(
      userId: params.userId,
      roleId: params.roleId,
    );
  }
}

class AssignRoleParams extends Equatable {
  final String userId;
  final String roleId;

  const AssignRoleParams({
    required this.userId,
    required this.roleId,
  });

  @override
  List<Object> get props => [userId, roleId];
}