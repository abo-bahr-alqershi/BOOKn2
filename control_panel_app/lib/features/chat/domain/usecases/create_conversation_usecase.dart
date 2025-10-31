import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:bookn_cp_app/features/chat/domain/entities/conversation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class CreateConversationUseCase implements UseCase<Conversation, CreateConversationParams> {
  final ChatRepository repository;

  CreateConversationUseCase(this.repository);

  @override
  Future<Either<Failure, Conversation>> call(CreateConversationParams params) async {
    return await repository.createConversation(
      participantIds: params.participantIds,
      conversationType: params.conversationType,
      title: params.title,
      description: params.description,
      propertyId: params.propertyId,
    );
  }
}

class CreateConversationParams extends Equatable {
  final List<String> participantIds;
  final String conversationType;
  final String? title;
  final String? description;
  final String? propertyId;

  const CreateConversationParams({
    required this.participantIds,
    required this.conversationType,
    this.title,
    this.description,
    this.propertyId,
  });

  @override
  List<Object?> get props => [
    participantIds,
    conversationType,
    title,
    description,
    propertyId,
  ];
}