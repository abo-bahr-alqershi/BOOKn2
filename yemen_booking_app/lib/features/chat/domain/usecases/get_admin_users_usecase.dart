import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetAdminUsersUseCase implements UseCase<List<ChatUser>, NoParams> {
  final ChatRepository repository;

  GetAdminUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatUser>>> call(NoParams params) async {
    return await repository.getAdminUsers();
  }
}
