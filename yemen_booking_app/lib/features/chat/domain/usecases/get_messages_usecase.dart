import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class GetMessagesUseCase implements UseCase<List<Message>, GetMessagesParams> {
  final ChatRepository repository;

  GetMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Message>>> call(GetMessagesParams params) async {
    return await repository.getMessages(
      conversationId: params.conversationId,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      beforeMessageId: params.beforeMessageId,
    );
  }
}

class GetMessagesParams extends Equatable {
  final String conversationId;
  final int pageNumber;
  final int pageSize;
  final String? beforeMessageId;

  const GetMessagesParams({
    required this.conversationId,
    this.pageNumber = 1,
    this.pageSize = 50,
    this.beforeMessageId,
  });

  @override
  List<Object?> get props => [
    conversationId,
    pageNumber,
    pageSize,
    beforeMessageId,
  ];
}