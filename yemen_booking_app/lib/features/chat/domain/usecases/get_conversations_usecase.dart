import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUseCase implements UseCase<List<Conversation>, GetConversationsParams> {
  final ChatRepository repository;

  GetConversationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Conversation>>> call(GetConversationsParams params) async {
    return await repository.getConversations(
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetConversationsParams extends Equatable {
  final int pageNumber;
  final int pageSize;

  const GetConversationsParams({
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  @override
  List<Object> get props => [pageNumber, pageSize];
}