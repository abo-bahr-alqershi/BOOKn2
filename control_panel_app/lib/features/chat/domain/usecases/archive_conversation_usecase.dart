import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class ArchiveConversationUseCase implements UseCase<void, ArchiveConversationParams> {
  final ChatRepository repository;

  ArchiveConversationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ArchiveConversationParams params) async {
    return await repository.archiveConversation(params.conversationId);
  }
}

class ArchiveConversationParams extends Equatable {
  final String conversationId;

  const ArchiveConversationParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}