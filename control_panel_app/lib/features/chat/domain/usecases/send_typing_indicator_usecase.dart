import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../services/websocket_service.dart';

class SendTypingIndicatorUseCase
    implements UseCase<void, SendTypingIndicatorParams> {
  final ChatWebSocketService webSocketService;

  SendTypingIndicatorUseCase(this.webSocketService);

  @override
  Future<Either<Failure, void>> call(SendTypingIndicatorParams params) async {
    try {
      webSocketService.sendTypingIndicator(
        params.conversationId,
        params.isTyping,
      );
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}

class SendTypingIndicatorParams extends Equatable {
  final String conversationId;
  final bool isTyping;

  const SendTypingIndicatorParams({
    required this.conversationId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [conversationId, isTyping];
}

