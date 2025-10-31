import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class EditMessageUseCase implements UseCase<Message, EditMessageParams> {
  final ChatRepository repository;

  EditMessageUseCase(this.repository);

  @override
  Future<Either<Failure, Message>> call(EditMessageParams params) async {
    return await repository.editMessage(
      messageId: params.messageId,
      content: params.content,
    );
  }
}

class EditMessageParams extends Equatable {
  final String messageId;
  final String content;

  const EditMessageParams({
    required this.messageId,
    required this.content,
  });

  @override
  List<Object> get props => [messageId, content];
}