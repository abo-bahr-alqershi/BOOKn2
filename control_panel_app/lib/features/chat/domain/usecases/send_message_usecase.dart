import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase implements UseCase<Message, SendMessageParams> {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      conversationId: params.conversationId,
      messageType: params.messageType,
      content: params.content,
      location: params.location,
      replyToMessageId: params.replyToMessageId,
      attachmentIds: params.attachmentIds,
    );
  }
}

class SendMessageParams extends Equatable {
  final String conversationId;
  final String messageType;
  final String? content;
  final Location? location;
  final String? replyToMessageId;
  final List<String>? attachmentIds;

  const SendMessageParams({
    required this.conversationId,
    required this.messageType,
    this.content,
    this.location,
    this.replyToMessageId,
    this.attachmentIds,
  });

  @override
  List<Object?> get props => [
    conversationId,
    messageType,
    content,
    location,
    replyToMessageId,
    attachmentIds,
  ];
}