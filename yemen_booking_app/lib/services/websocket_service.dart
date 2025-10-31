import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:yemen_booking_app/features/chat/data/models/message_reaction_model.dart';
import '../core/constants/api_constants.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/chat/domain/entities/conversation.dart';
import '../features/chat/domain/entities/message.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../injection_container.dart';

import '../features/chat/data/models/conversation_model.dart';
import '../features/chat/data/models/message_model.dart';


class ChatWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final AuthLocalDataSource? _authLocalDataSource;
  
  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  // Reconnection
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  static const Duration _reconnectionDelay = Duration(seconds: 5);
  
  // Typing indicators
  final Map<String, Set<String>> _typingUsers = {};
  Timer? _typingTimer;
  
  // Stream controllers
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _conversationController = StreamController<Conversation>.broadcast();
  final _messageController = StreamController<MessageEvent>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _presenceController = StreamController<PresenceEvent>.broadcast();
  final _errorController = StreamController<WebSocketError>.broadcast();
  
  // Streams
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<Conversation> get conversationUpdates => _conversationController.stream;
  Stream<MessageEvent> get messageEvents => _messageController.stream;
  Stream<TypingEvent> get typingEvents => _typingController.stream;
  Stream<PresenceEvent> get presenceEvents => _presenceController.stream;
  Stream<WebSocketError> get errors => _errorController.stream;
  
  ChatWebSocketService({
    AuthLocalDataSource? authLocalDataSource,
  }) : _authLocalDataSource = authLocalDataSource;

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
      final msg = MessageModel.fromJson(message['data']);
      _messageController.add(MessageEvent(
        type: MessageEventType.edited,
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
        type: MessageEventType.deleted,
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
      
      _messageController.add(MessageEvent(
        type: isAdded ? MessageEventType.reactionAdded : MessageEventType.reactionRemoved,
        messageId: data['messageId'],
        conversationId: data['conversationId'],
        reaction: MessageReactionModel.fromJson(data['reaction']),
      ));
    } catch (e) {
      debugPrint('Error handling reaction update: $e');
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
        lastSeen: data['lastSeen'] != null 
            ? DateTime.parse(data['lastSeen']) 
            : null,
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

  // Send typing indicator
  void sendTypingIndicator(String conversationId, bool isTyping) {
    if (!_isConnected) return;
    // disabled
  }

  // Send presence update
  void _sendPresence(String status) {
    if (!_isConnected) return;
    // disabled
  }

  // Mark messages as read
  void markMessagesAsRead(String conversationId, List<String> messageIds) {
    if (!_isConnected) return;
    // disabled
  }

  // Handle error
  void _handleError(dynamic error) {
    _errorController.add(WebSocketError(
      type: ErrorType.connectionError,
      message: error.toString(),
    ));
    
    if (_isConnected) {
      _isConnected = false;
      _connectionStatusController.add(ConnectionStatus.error);
    }
  }

  // Handle connection closed
  void _handleDone() {
    _isConnected = false;
    _connectionStatusController.add(ConnectionStatus.disconnected);
  }

  // Attempt reconnection
  void _attemptReconnection() {
    // disabled
  }

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
  edited,
  deleted,
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