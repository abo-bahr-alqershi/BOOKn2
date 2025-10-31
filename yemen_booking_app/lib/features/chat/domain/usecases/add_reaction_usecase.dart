import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class AddReactionUseCase implements UseCase<void, AddReactionParams> {
  final ChatRepository repository;

  AddReactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddReactionParams params) async {
    return await repository.addReaction(
      messageId: params.messageId,
      reactionType: params.reactionType,
    );
  }
}

class AddReactionParams extends Equatable {
  final String messageId;
  final String reactionType;

  const AddReactionParams({
    required this.messageId,
    required this.reactionType,
  });

  @override
  List<Object> get props => [messageId, reactionType];
}