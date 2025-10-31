import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/attachment.dart';
import '../repositories/chat_repository.dart';

class UpdateChatSettingsUseCase implements UseCase<ChatSettings, UpdateChatSettingsParams> {
  final ChatRepository repository;

  UpdateChatSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, ChatSettings>> call(UpdateChatSettingsParams params) async {
    return await repository.updateChatSettings(
      notificationsEnabled: params.notificationsEnabled,
      soundEnabled: params.soundEnabled,
      showReadReceipts: params.showReadReceipts,
      showTypingIndicator: params.showTypingIndicator,
      theme: params.theme,
      fontSize: params.fontSize,
      autoDownloadMedia: params.autoDownloadMedia,
      backupMessages: params.backupMessages,
    );
  }
}

class UpdateChatSettingsParams extends Equatable {
  final bool? notificationsEnabled;
  final bool? soundEnabled;
  final bool? showReadReceipts;
  final bool? showTypingIndicator;
  final String? theme;
  final String? fontSize;
  final bool? autoDownloadMedia;
  final bool? backupMessages;

  const UpdateChatSettingsParams({
    this.notificationsEnabled,
    this.soundEnabled,
    this.showReadReceipts,
    this.showTypingIndicator,
    this.theme,
    this.fontSize,
    this.autoDownloadMedia,
    this.backupMessages,
  });

  @override
  List<Object?> get props => [
    notificationsEnabled,
    soundEnabled,
    showReadReceipts,
    showTypingIndicator,
    theme,
    fontSize,
    autoDownloadMedia,
    backupMessages,
  ];
}