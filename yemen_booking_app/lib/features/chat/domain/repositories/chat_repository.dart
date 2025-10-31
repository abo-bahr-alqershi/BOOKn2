import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';
import '../entities/attachment.dart';

abstract class ChatRepository {
  // Conversations
  Future<Either<Failure, Conversation>> createConversation({
    required List<String> participantIds,
    required String conversationType,
    String? title,
    String? description,
    String? propertyId,
  });
  
  Future<Either<Failure, List<Conversation>>> getConversations({
    required int pageNumber,
    required int pageSize,
  });
  
  Future<Either<Failure, Conversation>> getConversationById(String conversationId);
  
  Future<Either<Failure, void>> archiveConversation(String conversationId);
  
  Future<Either<Failure, void>> unarchiveConversation(String conversationId);
  
  Future<Either<Failure, void>> deleteConversation(String conversationId);
  
  // Messages
  Future<Either<Failure, List<Message>>> getMessages({
    required String conversationId,
    required int pageNumber,
    required int pageSize,
    String? beforeMessageId,
  });
  
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String messageType,
    String? content,
    Location? location,
    String? replyToMessageId,
    List<String>? attachmentIds,
  });
  
  Future<Either<Failure, Message>> editMessage({
    required String messageId,
    required String content,
  });
  
  Future<Either<Failure, void>> deleteMessage(String messageId);
  
  Future<Either<Failure, void>> markAsRead({
    required String conversationId,
    required List<String> messageIds,
  });
  
  // Reactions
  Future<Either<Failure, void>> addReaction({
    required String messageId,
    required String reactionType,
  });
  
  Future<Either<Failure, void>> removeReaction({
    required String messageId,
    required String reactionType,
  });
  
  // Attachments
  Future<Either<Failure, Attachment>> uploadAttachment({
    required String conversationId,
    required String filePath,
    required String messageType,
    ProgressCallback? onSendProgress,
  });
  
  Future<Either<Failure, List<Attachment>>> uploadMultipleAttachments({
    required String conversationId,
    required List<String> filePaths,
    required String messageType,
    ProgressCallback? onSendProgress,
  });
  
  // Search
  Future<Either<Failure, SearchResult>> searchChats({
    required String query,
    String? conversationId,
    String? messageType,
    String? senderId,
    DateTime? dateFrom,
    DateTime? dateTo,
    required int page,
    required int limit,
  });
  
  // Users
  Future<Either<Failure, List<ChatUser>>> getAvailableUsers({
    String? userType,
    String? propertyId,
  });
  
  Future<Either<Failure, List<ChatUser>>> getAdminUsers();
  
  Future<Either<Failure, void>> updateUserStatus(String status);
  
  // Settings
  Future<Either<Failure, ChatSettings>> getChatSettings();
  
  Future<Either<Failure, ChatSettings>> updateChatSettings({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    String? theme,
    String? fontSize,
    bool? autoDownloadMedia,
    bool? backupMessages,
  });
  
  // Cache
  Future<void> cacheConversations(List<Conversation> conversations);
  Future<List<Conversation>?> getCachedConversations();
  Future<void> cacheMessages(String conversationId, List<Message> messages);
  Future<List<Message>?> getCachedMessages(String conversationId);
  Future<void> clearChatCache();
}

class SearchResult {
  final List<Message> messages;
  final List<Conversation> conversations;
  final int totalCount;
  final bool hasMore;
  final int? nextPageNumber;

  const SearchResult({
    required this.messages,
    required this.conversations,
    required this.totalCount,
    required this.hasMore,
    this.nextPageNumber,
  });
}