import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class RemoveReactionUseCase implements UseCase<void, RemoveReactionParams> {
  final ChatRepository repository;

  RemoveReactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveReactionParams params) async {
    return await repository.removeReaction(
      messageId: params.messageId,
      reactionType: params.reactionType,
    );
  }
}

class RemoveReactionParams extends Equatable {
  final String messageId;
  final String reactionType;

  const RemoveReactionParams({
    required this.messageId,
    required this.reactionType,
  });

  @override
  List<Object> get props => [messageId, reactionType];
}