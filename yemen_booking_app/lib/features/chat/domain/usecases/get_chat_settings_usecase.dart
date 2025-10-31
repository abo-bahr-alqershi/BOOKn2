import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/attachment.dart';
import '../repositories/chat_repository.dart';

class GetChatSettingsUseCase implements UseCase<ChatSettings, NoParams> {
  final ChatRepository repository;

  GetChatSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, ChatSettings>> call(NoParams params) async {
    return await repository.getChatSettings();
  }
}