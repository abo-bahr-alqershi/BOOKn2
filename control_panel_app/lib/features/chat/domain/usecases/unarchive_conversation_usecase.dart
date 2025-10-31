import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class UnarchiveConversationUseCase implements UseCase<void, UnarchiveConversationParams> {
  final ChatRepository repository;

  UnarchiveConversationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UnarchiveConversationParams params) async {
    return await repository.unarchiveConversation(params.conversationId);
  }
}

class UnarchiveConversationParams extends Equatable {
  final String conversationId;

  const UnarchiveConversationParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}