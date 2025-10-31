part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<Conversation> conversations;
  final Map<String, List<Message>> messages;
  final Map<String, List<String>> typingUsers;
  final Map<String, UserPresence> userPresence;
  final List<ChatUser> availableUsers;
  final List<ChatUser> adminUsers;
  final ChatSettings? settings;
  final SearchResult? searchResult;
  final bool isLoadingMessages;
  final bool isLoadingMore;
  final bool isSearching;
  final bool isSendingMessage;
  final String? error;
  final Attachment? uploadingAttachment;
  final double? uploadProgress;
  final Map<String, List<ImageUploadInfo>> uploadingImages;
  final String? currentUserId;
  final String? currentUserName;
  final String? loadingConversationId;
  final String? sendingConversationId;

  const ChatLoaded({
    this.conversations = const [],
    this.messages = const {},
    this.typingUsers = const {},
    this.userPresence = const {},
    this.availableUsers = const [],
    this.adminUsers = const [],
    this.settings,
    this.searchResult,
    this.isLoadingMessages = false,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.isSendingMessage = false,
    this.error,
    this.uploadingAttachment,
    this.uploadProgress,
    this.uploadingImages = const {},
    this.currentUserId,
    this.currentUserName,
    this.loadingConversationId,
    this.sendingConversationId,
  });

  ChatLoaded copyWith({
    List<Conversation>? conversations,
    Map<String, List<Message>>? messages,
    Map<String, List<String>>? typingUsers,
    Map<String, UserPresence>? userPresence,
    List<ChatUser>? availableUsers,
    List<ChatUser>? adminUsers,
    ChatSettings? settings,
    SearchResult? searchResult,
    bool? isLoadingMessages,
    bool? isLoadingMore,
    bool? isSearching,
    bool? isSendingMessage,
    String? error,
    Attachment? uploadingAttachment,
    double? uploadProgress,
    Map<String, List<ImageUploadInfo>>? uploadingImages,
    String? currentUserId,
    String? currentUserName,
    String? loadingConversationId,
    String? sendingConversationId,
  }) {
    return ChatLoaded(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      typingUsers: typingUsers ?? this.typingUsers,
      userPresence: userPresence ?? this.userPresence,
      availableUsers: availableUsers ?? this.availableUsers,
      adminUsers: adminUsers ?? this.adminUsers,
      settings: settings ?? this.settings,
      searchResult: searchResult ?? this.searchResult,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearching: isSearching ?? this.isSearching,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      error: error,
      uploadingAttachment: uploadingAttachment,
      uploadProgress: uploadProgress,
      uploadingImages: uploadingImages ?? this.uploadingImages,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserName: currentUserName ?? this.currentUserName,
      loadingConversationId: loadingConversationId,
      sendingConversationId: sendingConversationId,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        messages,
        typingUsers,
        userPresence,
        availableUsers,
        adminUsers,
        settings,
        searchResult,
        isLoadingMessages,
        isLoadingMore,
        isSearching,
        isSendingMessage,
        error,
        uploadingAttachment,
        uploadProgress,
        uploadingImages,
        currentUserId,
        currentUserName,
        loadingConversationId,
        sendingConversationId,
      ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object> get props => [message];
}

class UserPresence extends Equatable {
  final String status;
  final DateTime? lastSeen;

  const UserPresence({
    required this.status,
    this.lastSeen,
  });

  @override
  List<Object?> get props => [status, lastSeen];
}

class ConversationCreated extends ChatState {
  final Conversation conversation;
  final String? message;

  const ConversationCreated({
    required this.conversation,
    this.message = 'تم إنشاء المحادثة بنجاح',
  });

  @override
  List<Object?> get props => [conversation, message];
}

class ConversationCreating extends ChatState {
  const ConversationCreating();
}
