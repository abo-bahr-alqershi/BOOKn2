import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class SearchChatsUseCase implements UseCase<SearchResult, SearchChatsParams> {
  final ChatRepository repository;

  SearchChatsUseCase(this.repository);

  @override
  Future<Either<Failure, SearchResult>> call(SearchChatsParams params) async {
    return await repository.searchChats(
      query: params.query,
      conversationId: params.conversationId,
      messageType: params.messageType,
      senderId: params.senderId,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      page: params.page,
      limit: params.limit,
    );
  }
}

class SearchChatsParams extends Equatable {
  final String query;
  final String? conversationId;
  final String? messageType;
  final String? senderId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int page;
  final int limit;

  const SearchChatsParams({
    required this.query,
    this.conversationId,
    this.messageType,
    this.senderId,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [
    query,
    conversationId,
    messageType,
    senderId,
    dateFrom,
    dateTo,
    page,
    limit,
  ];
}