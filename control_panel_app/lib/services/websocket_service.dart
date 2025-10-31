import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:bookn_cp_app/features/chat/data/models/message_reaction_model.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/chat/data/datasources/chat_remote_datasource.dart';
import '../features/chat/domain/entities/conversation.dart';
import '../features/chat/domain/entities/message.dart';

import '../features/chat/data/models/conversation_model.dart';
import '../features/chat/data/models/message_model.dart';

class ChatWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  // final AuthLocalDataSource? _authLocalDataSource; // Unused field
  final ChatRemoteDataSource? _chatRemoteDataSource;

  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Reconnection
  Timer? _reconnectionTimer;
  // final int _reconnectionAttempts = 0; // Unused field
  // static const int _maxReconnectionAttempts = 5; // Unused field
  // static const Duration _reconnectionDelay = Duration(seconds: 5); // Unused field

  // Typing indicators
  final Map<String, Set<String>> _typingUsers = {};
  Timer? _typingTimer;

  // Stream controllers
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final _conversationController = StreamController<Conversation>.broadcast();
  final _messageController = StreamController<MessageEvent>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _presenceController = StreamController<PresenceEvent>.broadcast();
  final _errorController = StreamController<WebSocketError>.broadcast();

  // Streams
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;
  Stream<Conversation> get conversationUpdates =>
      _conversationController.stream;
  // Compatibility stream expected by ChatBloc
  Stream<ConversationEventWS> get conversationEvents =>
      _conversationController.stream
          .map((c) => ConversationEventWS(conversation: c));
  Stream<MessageEvent> get messageEvents => _messageController.stream;
  Stream<TypingEvent> get typingEvents => _typingController.stream;
  Stream<PresenceEvent> get presenceEvents => _presenceController.stream;
  Stream<WebSocketError> get errors => _errorController.stream;

  ChatWebSocketService({
    AuthLocalDataSource? authLocalDataSource,
    ChatRemoteDataSource? remoteDataSource,
  }) : _chatRemoteDataSource = remoteDataSource;

  // Connect to WebSocket (disabled, rely on FCM)
  Future<void> connect() async {
    if (_isConnected) return;
    _isConnected = true;
    _connectionStatusController.add(ConnectionStatus.connected);
  }

  // Disconnect
  void disconnect() {
    _reconnectionTimer?.cancel();
    _typingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _isConnected = false;
    _connectionStatusController.add(ConnectionStatus.disconnected);
  }

  // Handle incoming message
  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = json.decode(data as String);
      final String type = message['type'] ?? '';

      switch (type) {
        case 'ConversationCreated':
        case 'ConversationUpdated':
          _handleConversationUpdate(message);
          break;

        case 'NewMessage':
          _handleNewMessage(message);
          break;

        case 'MessageEdited':
          _handleMessageEdited(message);
          break;

        case 'MessageDeleted':
          _handleMessageDeleted(message);
          break;

        case 'MessageStatusUpdated':
          _handleMessageStatusUpdate(message);
          break;

        case 'ReactionAdded':
        case 'ReactionRemoved':
          _handleReactionUpdate(message);
          break;

        case 'UserTyping':
          _handleTypingIndicator(message);
          break;

        case 'UserPresence':
          _handlePresenceUpdate(message);
          break;

        case 'Error':
          _handleServerError(message);
          break;

        default:
          debugPrint('Unknown WebSocket message type: $type');
      }
    } catch (e) {
      _errorController.add(WebSocketError(
        type: ErrorType.parseError,
        message: 'Failed to parse message: $e',
      ));
    }
  }

  void _handleConversationUpdate(Map<String, dynamic> message) {
    try {
      final conversation = ConversationModel.fromJson(message['data']);
      _conversationController.add(conversation);
    } catch (e) {
      debugPrint('Error handling conversation update: $e');
    }
  }

  void _handleNewMessage(Map<String, dynamic> message) {
    try {
      final msg = MessageModel.fromJson(message['data']);
      _messageController.add(MessageEvent(
        type: MessageEventType.newMessage,
        message: msg,
        conversationId: msg.conversationId,
      ));
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  void _handleMessageEdited(Map<String, dynamic> message) {
    try {
      final msg = MessageModel.fromJson(message[ 'data']);
      _messageController.add(MessageEvent(
        type: MessageEventType.messageUpdated,
        message: msg,
        conversationId: msg.conversationId,
      ));
    } catch (e) {
      debugPrint('Error handling message edit: $e');
    }
  }

  void _handleMessageDeleted(Map<String, dynamic> message) {
    try {
      final data = message['data'];
      _messageController.add(MessageEvent(
        type: MessageEventType.messageDeleted,
        messageId: data['messageId'],
        conversationId: data['conversationId'],
      ));
    } catch (e) {
      debugPrint('Error handling message deletion: $e');
    }
  }

  void _handleMessageStatusUpdate(Map<String, dynamic> message) {
    try {
      final data = message['data'];
      _messageController.add(MessageEvent(
        type: MessageEventType.statusUpdated,
        messageId: data['messageId'],
        conversationId: data['conversationId'],
        status: data['status'],
      ));
    } catch (e) {
      debugPrint('Error handling message status update: $e');
    }
  }

  void _handleReactionUpdate(Map<String, dynamic> message) {
    try {
      final data = message['data'];
      final isAdded = message['type'] == 'ReactionAdded';

      // data may arrive either as a full reaction object or as primitives via FCM data
      final reaction = data['reaction'] != null
          ? MessageReactionModel.fromJson(data['reaction'])
          : MessageReactionModel.fromJson({
              'id': data['reactionId'] ?? data['reaction_id'] ?? '',
              'message_id': data['messageId'] ?? data['message_id'] ?? '',
              'user_id': data['userId'] ?? data['user_id'] ?? '',
              'reaction_type':
                  data['reactionType'] ?? data['reaction_type'] ?? '',
            });

      _messageController.add(MessageEvent(
        type: isAdded
            ? MessageEventType.reactionAdded
            : MessageEventType.reactionRemoved,
        messageId: data['messageId'] ?? data['message_id'],
        conversationId: data['conversationId'] ?? data['conversation_id'],
        reaction: reaction,
      ));
    } catch (e) {
      debugPrint('Error handling reaction update: $e');
    }
  }

  // Emit reaction update (used by FCM NotificationService)
  void emitReactionUpdate({
    required String conversationId,
    required String messageId,
    required String userId,
    required String reactionType,
    required bool isAdded,
  }) {
    try {
      final reaction = MessageReactionModel.fromJson({
        'id': 'temp_${DateTime.now().microsecondsSinceEpoch}',
        'message_id': messageId,
        'user_id': userId,
        'reaction_type': reactionType,
      });
      _messageController.add(MessageEvent(
        type: isAdded
            ? MessageEventType.reactionAdded
            : MessageEventType.reactionRemoved,
        messageId: messageId,
        conversationId: conversationId,
        reaction: reaction,
      ));
    } catch (e) {
      debugPrint('emitReactionUpdate error: $e');
    }
  }

  void _handleTypingIndicator(Map<String, dynamic> message) {
    try {
      final data = message['data'];
      final conversationId = data['conversationId'];
      final userId = data['userId'];
      final isTyping = data['isTyping'] ?? false;

      if (!_typingUsers.containsKey(conversationId)) {
        _typingUsers[conversationId] = {};
      }

      if (isTyping) {
        _typingUsers[conversationId]!.add(userId);
      } else {
        _typingUsers[conversationId]!.remove(userId);
      }

      _typingController.add(TypingEvent(
        conversationId: conversationId,
        typingUserIds: _typingUsers[conversationId]!.toList(),
      ));
    } catch (e) {
      debugPrint('Error handling typing indicator: $e');
    }
  }

  void _handlePresenceUpdate(Map<String, dynamic> message) {
    try {
      final data = message['data'];
      _presenceController.add(PresenceEvent(
        userId: data['userId'],
        status: data['status'],
        lastSeen:
            data['lastSeen'] != null ? DateTime.parse(data['lastSeen']) : null,
      ));
    } catch (e) {
      debugPrint('Error handling presence update: $e');
    }
  }

  void _handleServerError(Map<String, dynamic> message) {
    _errorController.add(WebSocketError(
      type: ErrorType.serverError,
      message: message['error'] ?? 'Server error occurred',
    ));
  }

  // Emit a new message event using IDs (for FCM data messages inside app)
  void emitNewMessageById({
    required String conversationId,
    required String messageId,
  }) {
    _messageController.add(MessageEvent(
      type: MessageEventType.newMessage,
      messageId: messageId,
      conversationId: conversationId,
    ));
  }

  // Emit a message status update event (for FCM data messages inside app)
  void emitMessageStatusUpdate({
    required String conversationId,
    required String messageId,
    required String status,
  }) {
    _messageController.add(MessageEvent(
      type: MessageEventType.statusUpdated,
      messageId: messageId,
      conversationId: conversationId,
      status: status,
    ));
  }

  // Fetch and emit conversation update by ID (for conversation_created)
  Future<void> emitConversationById({
    required String conversationId,
  }) async {
    try {
      if (_chatRemoteDataSource == null) return;
      final conversation =
          await _chatRemoteDataSource!.getConversationById(conversationId);
      _conversationController.add(conversation);
    } catch (e) {
      debugPrint('emitConversationById error: $e');
    }
  }

  // Send typing indicator
  void sendTypingIndicator(String conversationId, bool isTyping) {
    if (!_isConnected) return;
    // disabled
  }

  // Send presence update
  // void _sendPresence(String status) {
  //   if (!_isConnected) return;
  //   // disabled
  // }

  // Mark messages as read
  void markMessagesAsRead(String conversationId, List<String> messageIds) {
    if (!_isConnected) return;
    // disabled
  }

  // Handle error
  // void _handleError(dynamic error) {
  //   _errorController.add(WebSocketError(
  //     type: ErrorType.connectionError,
  //     message: error.toString(),
  //   ));
  //
  //   if (_isConnected) {
  //     _isConnected = false;
  //     _connectionStatusController.add(ConnectionStatus.error);
  //   }
  // }

  // Handle connection closed
  // void _handleDone() {
  //   _isConnected = false;
  //   _connectionStatusController.add(ConnectionStatus.disconnected);
  // }

  // Attempt reconnection
  // void _attemptReconnection() {
  //   // disabled
  // }

  // Dispose
  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _conversationController.close();
    _messageController.close();
    _typingController.close();
    _presenceController.close();
    _errorController.close();
  }
}

// Event Models
class MessageEvent {
  final MessageEventType type;
  final Message? message;
  final String? messageId;
  final String conversationId;
  final String? status;
  final MessageReaction? reaction;

  MessageEvent({
    required this.type,
    this.message,
    this.messageId,
    required this.conversationId,
    this.status,
    this.reaction,
  });
}

class TypingEvent {
  final String conversationId;
  final List<String> typingUserIds;

  TypingEvent({
    required this.conversationId,
    required this.typingUserIds,
  });
}

// Wrapper class for conversation updates to satisfy ChatBloc event type
class ConversationEventWS {
  final Conversation? conversation;
  ConversationEventWS({this.conversation});
}

class PresenceEvent {
  final String userId;
  final String status;
  final DateTime? lastSeen;

  PresenceEvent({
    required this.userId,
    required this.status,
    this.lastSeen,
  });
}

class WebSocketError {
  final ErrorType type;
  final String message;

  WebSocketError({
    required this.type,
    required this.message,
  });
}

// Enums
enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
  reconnecting,
  error,
  failed,
}

enum MessageEventType {
  newMessage,
  messageUpdated,
  messageDeleted,
  statusUpdated,
  reactionAdded,
  reactionRemoved,
}

enum ErrorType {
  connectionError,
  parseError,
  authError,
  serverError,
}

// Exception
class WebSocketException implements Exception {
  final String message;
  WebSocketException(this.message);

  @override
  String toString() => message;
}
