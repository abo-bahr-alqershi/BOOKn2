import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/attachment.dart';
import '../repositories/chat_repository.dart';

class UploadAttachmentUseCase implements UseCase<Attachment, UploadAttachmentParams> {
  final ChatRepository repository;

  UploadAttachmentUseCase(this.repository);

  @override
  Future<Either<Failure, Attachment>> call(UploadAttachmentParams params) async {
    return await repository.uploadAttachment(
      conversationId: params.conversationId,
      filePath: params.filePath,
      messageType: params.messageType,
      onSendProgress: params.onSendProgress,
    );
  }
}

class UploadAttachmentParams extends Equatable {
  final String conversationId;
  final String filePath;
  final String messageType;
  final ProgressCallback? onSendProgress;

  const UploadAttachmentParams({
    required this.conversationId,
    required this.filePath,
    required this.messageType,
    this.onSendProgress,
  });

  @override
  List<Object?> get props => [
    conversationId,
    filePath,
    messageType,
  ];
}