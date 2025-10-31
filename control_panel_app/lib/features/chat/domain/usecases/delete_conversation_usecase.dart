import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class DeleteConversationUseCase implements UseCase<void, DeleteConversationParams> {
  final ChatRepository repository;

  DeleteConversationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteConversationParams params) async {
    return await repository.deleteConversation(params.conversationId);
  }
}

class DeleteConversationParams extends Equatable {
  final String conversationId;

  const DeleteConversationParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}