import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class MarkAsReadUseCase implements UseCase<void, MarkAsReadParams> {
  final ChatRepository repository;

  MarkAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkAsReadParams params) async {
    return await repository.markAsRead(
      conversationId: params.conversationId,
      messageIds: params.messageIds,
    );
  }
}

class MarkAsReadParams extends Equatable {
  final String conversationId;
  final List<String> messageIds;

  const MarkAsReadParams({
    required this.conversationId,
    required this.messageIds,
  });

  @override
  List<Object> get props => [conversationId, messageIds];
}