import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class DeleteMessageUseCase implements UseCase<void, DeleteMessageParams> {
  final ChatRepository repository;

  DeleteMessageUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMessageParams params) async {
    return await repository.deleteMessage(params.messageId);
  }
}

class DeleteMessageParams extends Equatable {
  final String messageId;

  const DeleteMessageParams({required this.messageId});

  @override
  List<Object> get props => [messageId];
}