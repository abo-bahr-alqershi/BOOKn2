import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class UpdateUserStatusUseCase implements UseCase<void, UpdateUserStatusParams> {
  final ChatRepository repository;

  UpdateUserStatusUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserStatusParams params) async {
    return await repository.updateUserStatus(params.status);
  }
}

class UpdateUserStatusParams extends Equatable {
  final String status;

  const UpdateUserStatusParams({required this.status});

  @override
  List<Object> get props => [status];
}