import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yemen_booking_app/features/chat/data/models/chat_settings_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/message.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class ChatLocalDataSource {
  // Conversations
  Future<void> cacheConversations(List<ConversationModel> conversations);
  Future<List<ConversationModel>?> getCachedConversations();
  Future<ConversationModel?> getCachedConversationById(String conversationId);
  Future<void> deleteConversationCache(String conversationId);
  
  // Messages
  Future<void> cacheMessages(String conversationId, List<MessageModel> messages);
  Future<List<MessageModel>?> getCachedMessages(String conversationId);
  Future<void> addMessageToCache(String conversationId, MessageModel message);
  Future<void> queueMessage({
    required String conversationId,
    required String messageType,
    String? content,
    Location? location,
    String? replyToMessageId,
    List<String>? attachmentIds,
  });
  Future<List<Map<String, dynamic>>> getQueuedMessages();
  Future<void> removeQueuedMessage(String messageId);
  
  // Settings
  Future<void> cacheSettings(ChatSettingsModel settings);
  Future<ChatSettingsModel?> getCachedSettings();
  
  // Clear
  Future<void> clearAllCache();
  Future<void> clearConversationsCache();
  Future<void> clearMessagesCache();
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  static const String _conversationsBoxName = 'chat_conversations';
  static const String _messagesBoxName = 'chat_messages';
  static const String _settingsBoxName = 'chat_settings';
  static const String _queuedMessagesBoxName = 'queued_messages';
  
  late Box<String> _conversationsBox;
  late Box<String> _messagesBox;
  late Box<String> _settingsBox;
  late Box<String> _queuedMessagesBox;
  bool _isInitialized = false;
  Future<void>? _initFuture;
  
  ChatLocalDataSourceImpl() {
    _initFuture = _initializeBoxes();
  }
  
  Future<void> _initializeBoxes() async {
    try {
      if (!Hive.isBoxOpen(_conversationsBoxName)) {
        _conversationsBox = await Hive.openBox<String>(_conversationsBoxName);
      } else {
        _conversationsBox = Hive.box<String>(_conversationsBoxName);
      }
      if (!Hive.isBoxOpen(_messagesBoxName)) {
        _messagesBox = await Hive.openBox<String>(_messagesBoxName);
      } else {
        _messagesBox = Hive.box<String>(_messagesBoxName);
      }
      if (!Hive.isBoxOpen(_settingsBoxName)) {
        _settingsBox = await Hive.openBox<String>(_settingsBoxName);
      } else {
        _settingsBox = Hive.box<String>(_settingsBoxName);
      }
      if (!Hive.isBoxOpen(_queuedMessagesBoxName)) {
        _queuedMessagesBox = await Hive.openBox<String>(_queuedMessagesBoxName);
      } else {
        _queuedMessagesBox = Hive.box<String>(_queuedMessagesBoxName);
      }
      _isInitialized = true;
    } catch (e) {
      throw const CacheException('فشل في تهيئة التخزين المحلي');
    }
  }
  
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    _initFuture = _initializeBoxes();
    await _initFuture;
  }
  
  @override
  Future<void> cacheConversations(List<ConversationModel> conversations) async {
    await _ensureInitialized();
    try {
      final conversationsMap = <String, String>{};
      for (final conversation in conversations) {
        conversationsMap[conversation.id] = json.encode(conversation.toJson());
      }
      await _conversationsBox.putAll(conversationsMap);
      
      // Also cache the list order
      await _conversationsBox.put(
        'conversations_list',
        json.encode(conversations.map((c) => c.id).toList()),
      );
    } catch (e) {
      throw const CacheException('فشل في حفظ المحادثات');
    }
  }
  
  @override
  Future<List<ConversationModel>?> getCachedConversations() async {
    await _ensureInitialized();
    try {
      final listJson = _conversationsBox.get('conversations_list');
      if (listJson == null) return null;
      
      final List<String> conversationIds = List<String>.from(json.decode(listJson));
      final conversations = <ConversationModel>[];
      
      for (final id in conversationIds) {
        final conversationJson = _conversationsBox.get(id);
        if (conversationJson != null) {
          conversations.add(
            ConversationModel.fromJson(json.decode(conversationJson)),
          );
        }
      }
      
      return conversations.isNotEmpty ? conversations : null;
    } catch (e) {
      throw const CacheException('فشل في قراءة المحادثات المحفوظة');
    }
  }
  
  @override
  Future<ConversationModel?> getCachedConversationById(String conversationId) async {
    await _ensureInitialized();
    try {
      final conversationJson = _conversationsBox.get(conversationId);
      if (conversationJson == null) return null;
      
      return ConversationModel.fromJson(json.decode(conversationJson));
    } catch (e) {
      throw const CacheException('فشل في قراءة المحادثة');
    }
  }
  
  @override
  Future<void> deleteConversationCache(String conversationId) async {
    await _ensureInitialized();
    try {
      await _conversationsBox.delete(conversationId);
      
      // Update the list
      final listJson = _conversationsBox.get('conversations_list');
      if (listJson != null) {
        final List<String> conversationIds = List<String>.from(json.decode(listJson));
        conversationIds.remove(conversationId);
        await _conversationsBox.put(
          'conversations_list',
          json.encode(conversationIds),
        );
      }
      
      // Delete messages
      await _messagesBox.delete('messages_$conversationId');
    } catch (e) {
      throw const CacheException('فشل في حذف المحادثة');
    }
  }
  
  @override
  Future<void> cacheMessages(String conversationId, List<MessageModel> messages) async {
    await _ensureInitialized();
    try {
      final messagesJson = messages.map((m) => m.toJson()).toList();
      await _messagesBox.put(
        'messages_$conversationId',
        json.encode(messagesJson),
      );
    } catch (e) {
      throw const CacheException('فشل في حفظ الرسائل');
    }
  }
  
  @override
  Future<List<MessageModel>?> getCachedMessages(String conversationId) async {
    await _ensureInitialized();
    try {
      final messagesJson = _messagesBox.get('messages_$conversationId');
      if (messagesJson == null) return null;
      
      final List<dynamic> messagesList = json.decode(messagesJson);
      return messagesList
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw const CacheException('فشل في قراءة الرسائل المحفوظة');
    }
  }
  
  @override
  Future<void> addMessageToCache(String conversationId, MessageModel message) async {
    await _ensureInitialized();
    try {
      final messages = await getCachedMessages(conversationId) ?? [];
      messages.insert(0, message);
      
      // Keep only last 100 messages in cache
      if (messages.length > 100) {
        messages.removeRange(100, messages.length);
      }
      
      await cacheMessages(conversationId, messages);
    } catch (e) {
      throw const CacheException('فشل في إضافة الرسالة للذاكرة المؤقتة');
    }
  }
  
  @override
  Future<void> queueMessage({
    required String conversationId,
    required String messageType,
    String? content,
    Location? location,
    String? replyToMessageId,
    List<String>? attachmentIds,
  }) async {
    await _ensureInitialized();
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final queuedMessage = {
        'id': messageId,
        'conversationId': conversationId,
        'messageType': messageType,
        if (content != null) 'content': content,
        if (location != null) 'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          if (location.address != null) 'address': location.address,
        },
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        if (attachmentIds != null) 'attachmentIds': attachmentIds,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _queuedMessagesBox.put(messageId, json.encode(queuedMessage));
    } catch (e) {
      throw const CacheException('فشل في إضافة الرسالة لقائمة الانتظار');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getQueuedMessages() async {
    await _ensureInitialized();
    try {
      final messages = <Map<String, dynamic>>[];
      for (final key in _queuedMessagesBox.keys) {
        final messageJson = _queuedMessagesBox.get(key);
        if (messageJson != null) {
          messages.add(json.decode(messageJson));
        }
      }
      return messages;
    } catch (e) {
      throw const CacheException('فشل في قراءة الرسائل في قائمة الانتظار');
    }
  }
  
  @override
  Future<void> removeQueuedMessage(String messageId) async {
    await _ensureInitialized();
    try {
      await _queuedMessagesBox.delete(messageId);
    } catch (e) {
      throw const CacheException('فشل في حذف الرسالة من قائمة الانتظار');
    }
  }
  
  @override
  Future<void> cacheSettings(ChatSettingsModel settings) async {
    await _ensureInitialized();
    try {
      await _settingsBox.put('settings', json.encode(settings.toJson()));
    } catch (e) {
      throw const CacheException('فشل في حفظ الإعدادات');
    }
  }
  
  @override
  Future<ChatSettingsModel?> getCachedSettings() async {
    await _ensureInitialized();
    try {
      final settingsJson = _settingsBox.get('settings');
      if (settingsJson == null) return null;
      
      return ChatSettingsModel.fromJson(json.decode(settingsJson));
    } catch (e) {
      throw const CacheException('فشل في قراءة الإعدادات المحفوظة');
    }
  }
  
  @override
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    try {
      await Future.wait([
        _conversationsBox.clear(),
        _messagesBox.clear(),
        _settingsBox.clear(),
        _queuedMessagesBox.clear(),
      ]);
    } catch (e) {
      throw const CacheException('فشل في مسح الذاكرة المؤقتة');
    }
  }
  
  @override
  Future<void> clearConversationsCache() async {
    await _ensureInitialized();
    try {
      await _conversationsBox.clear();
    } catch (e) {
      throw const CacheException('فشل في مسح المحادثات المحفوظة');
    }
  }
  
  @override
  Future<void> clearMessagesCache() async {
    await _ensureInitialized();
    try {
      await _messagesBox.clear();
    } catch (e) {
      throw const CacheException('فشل في مسح الرسائل المحفوظة');
    }
  }
}