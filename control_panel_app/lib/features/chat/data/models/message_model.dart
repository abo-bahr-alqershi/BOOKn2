import 'dart:convert';
import 'package:bookn_cp_app/features/chat/data/models/delivery_receipt_model.dart';
import 'message_reaction_model.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/attachment.dart';
import 'attachment_model.dart';

/// نموذج الرسالة مع دعم كامل لجميع أنواع الرسائل
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.messageType,
    super.content,
    super.location,
    super.replyToMessageId,
    super.replyToMessage,
    super.reactions,
    super.attachments,
    required super.createdAt,
    required super.updatedAt,
    required super.status,
    super.isEdited,
    super.editedAt,
    super.deliveryReceipt,
    super.isDeleted,
    super.deletedAt,
    super.senderName,
    super.senderAvatar,
    super.isForwarded,
    super.forwardedFrom,
    super.mentions,
    super.isPinned,
    super.isStarred,
    super.readBy,
    super.metadata,
  });

  /// إنشاء نموذج من JSON مع معالجة شاملة
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? json['message_id'] ?? '',
      conversationId: json['conversation_id'] ?? json['conversationId'] ?? '',
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      messageType: _extractMessageType(json),
      content: _extractContent(json),
      location: _parseLocation(json),
      replyToMessageId: json['reply_to_message_id'] ?? json['replyToMessageId'],
      replyToMessage: _parseReplyToMessage(json),
      reactions: _parseReactions(json),
      attachments: _parseAttachments(json),
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _parseDateTime(json, 'updated_at', 'updatedAt'),
      status: _extractStatus(json),
      isEdited: _parseBool(json['is_edited'] ?? json['isEdited']),
      editedAt: _parseOptionalDateTime(json, 'edited_at', 'editedAt'),
      deliveryReceipt: _parseDeliveryReceipt(json),
      isDeleted: _parseBool(json['is_deleted'] ??
          json['isDeleted'] ??
          json['deleted_at'] != null),
      deletedAt: _parseOptionalDateTime(json, 'deleted_at', 'deletedAt'),
      senderName: _extractSenderName(json),
      senderAvatar: _extractSenderAvatar(json),
      isForwarded: _parseBool(json['is_forwarded'] ?? json['isForwarded']),
      forwardedFrom: json['forwarded_from'] ?? json['forwardedFrom'],
      mentions: _parseMentions(json),
      isPinned: _parseBool(json['is_pinned'] ?? json['isPinned']),
      isStarred: _parseBool(json['is_starred'] ?? json['isStarred']),
      readBy: _parseReadBy(json),
      metadata: _parseMetadata(json),
    );
  }

  /// تحويل النموذج إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'message_id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_type': messageType,
      if (content != null && content!.isNotEmpty) 'content': content,
      if (location != null) 'location': (location as LocationModel).toJson(),
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (replyToMessage != null)
        'reply_to_message': (replyToMessage as MessageModel).toJson(),
      'reactions':
          reactions.map((r) => (r as MessageReactionModel).toJson()).toList(),
      'attachments':
          attachments.map((a) => (a as AttachmentModel).toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'is_edited': isEdited,
      if (editedAt != null) 'edited_at': editedAt!.toIso8601String(),
      if (deliveryReceipt != null)
        'delivery_receipt': (deliveryReceipt as DeliveryReceiptModel).toJson(),
      'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
      if (senderName != null) 'sender_name': senderName,
      if (senderAvatar != null) 'sender_avatar': senderAvatar,
      'is_forwarded': isForwarded,
      if (forwardedFrom != null) 'forwarded_from': forwardedFrom,
      if (mentions.isNotEmpty) 'mentions': mentions,
      'is_pinned': isPinned,
      'is_starred': isStarred,
      if (readBy.isNotEmpty) 'read_by': readBy,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// إنشاء نموذج من Entity
  factory MessageModel.fromEntity(Message message) {
    if (message is MessageModel) return message;

    return MessageModel(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      messageType: message.messageType,
      content: message.content,
      location: message.location,
      replyToMessageId: message.replyToMessageId,
      replyToMessage: message.replyToMessage,
      reactions: message.reactions,
      attachments: message.attachments,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      status: message.status,
      isEdited: message.isEdited,
      editedAt: message.editedAt,
      deliveryReceipt: message.deliveryReceipt,
      isDeleted: message.isDeleted,
      deletedAt: message.deletedAt,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      isForwarded: message.isForwarded,
      forwardedFrom: message.forwardedFrom,
      mentions: message.mentions,
      isPinned: message.isPinned,
      isStarred: message.isStarred,
      readBy: message.readBy,
      metadata: message.metadata,
    );
  }

  /// نسخ النموذج مع التحديثات
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? messageType,
    String? content,
    Location? location,
    String? replyToMessageId,
    Message? replyToMessage,
    List<MessageReaction>? reactions,
    List<Attachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    bool? isEdited,
    DateTime? editedAt,
    DeliveryReceipt? deliveryReceipt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? senderName,
    String? senderAvatar,
    bool? isForwarded,
    String? forwardedFrom,
    List<String>? mentions,
    bool? isPinned,
    bool? isStarred,
    List<String>? readBy,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      location: location ?? this.location,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      reactions: reactions ?? this.reactions,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      deliveryReceipt: deliveryReceipt ?? this.deliveryReceipt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      mentions: mentions ?? this.mentions,
      isPinned: isPinned ?? this.isPinned,
      isStarred: isStarred ?? this.isStarred,
      readBy: readBy ?? this.readBy,
      metadata: metadata ?? this.metadata,
    );
  }

  // ========== دوال مساعدة خاصة ==========

  /// استخراج نوع الرسالة
  static String _extractMessageType(Map<String, dynamic> json) {
    final type = json['message_type'] ?? json['messageType'] ?? json['type'];
    if (type != null && type.toString().isNotEmpty) {
      return type.toString().toLowerCase();
    }

    // استنتاج النوع من المحتوى
    if (json['attachments'] != null &&
        (json['attachments'] as List).isNotEmpty) {
      final firstAttachment = (json['attachments'] as List).first;
      final contentType =
          firstAttachment['mime_type'] ?? firstAttachment['contentType'] ?? '';
      if (contentType.toString().startsWith('image/')) return 'image';
      if (contentType.toString().startsWith('video/')) return 'video';
      if (contentType.toString().startsWith('audio/')) return 'audio';
      return 'file';
    }

    if (json['location'] != null) return 'location';

    return 'text';
  }

  /// استخراج المحتوى
  static String? _extractContent(Map<String, dynamic> json) {
    final content = json['content'] ?? json['text'] ?? json['message'];
    if (content == null) return null;
    if (content is String) return content;
    if (content is Map) {
      try {
        return jsonEncode(content);
      } catch (_) {
        return content.toString();
      }
    }
    return content.toString();
  }

  /// تحليل الموقع
  static LocationModel? _parseLocation(Map<String, dynamic> json) {
    final location = json['location'];
    if (location == null) return null;

    if (location is Map<String, dynamic>) {
      return LocationModel.fromJson(location);
    }

    if (location is String) {
      try {
        final decoded = jsonDecode(location);
        if (decoded is Map<String, dynamic>) {
          return LocationModel.fromJson(decoded);
        }
      } catch (_) {}
    }

    return null;
  }

  /// تحليل الرسالة المُرد عليها
  static Message? _parseReplyToMessage(Map<String, dynamic> json) {
    final reply = json['reply_to_message'] ?? json['replyToMessage'];
    if (reply == null) return null;

    if (reply is Map<String, dynamic>) {
      return MessageModel.fromJson(reply);
    }

    return null;
  }

  /// تحليل التفاعلات
  static List<MessageReaction> _parseReactions(Map<String, dynamic> json) {
    final reactions = json['reactions'];
    if (reactions == null) return [];

    if (reactions is List) {
      return reactions
          .where((r) => r != null)
          .map((r) => MessageReactionModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// تحليل المرفقات
  static List<Attachment> _parseAttachments(Map<String, dynamic> json) {
    final attachments = json['attachments'];
    if (attachments == null) return [];

    if (attachments is List) {
      return attachments
          .where((a) => a != null)
          .map((a) => AttachmentModel.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// استخراج حالة الرسالة
  static String _extractStatus(Map<String, dynamic> json) {
    final status = json['status'] ?? json['message_status'];
    if (status != null && status.toString().isNotEmpty) {
      return status.toString().toLowerCase();
    }

    // استنتاج من معلومات التسليم
    if (json['read_at'] != null || json['readAt'] != null) return 'read';
    if (json['delivered_at'] != null || json['deliveredAt'] != null)
      return 'delivered';

    return 'sent';
  }

  /// استخراج اسم المرسل
  static String? _extractSenderName(Map<String, dynamic> json) {
    // محاولة مباشرة
    final directName = json['sender_name'] ?? json['senderName'];
    if (directName != null && directName.toString().isNotEmpty) {
      return directName.toString();
    }

    // من كائن المرسل
    final sender = json['sender'] ?? json['from'] ?? json['user'];
    if (sender != null) {
      if (sender is String && sender.isNotEmpty) return sender;
      if (sender is Map<String, dynamic>) {
        return sender['full_name'] ??
            sender['name'] ??
            sender['display_name'] ??
            sender['username'];
      }
    }

    return null;
  }

  /// استخراج صورة المرسل
  static String? _extractSenderAvatar(Map<String, dynamic> json) {
    final avatar = json['sender_avatar'] ?? json['senderAvatar'];
    if (avatar != null && avatar.toString().isNotEmpty) {
      return avatar.toString();
    }

    final sender = json['sender'] ?? json['from'] ?? json['user'];
    if (sender != null && sender is Map<String, dynamic>) {
      final pic = sender['profile_image'] ??
          sender['avatar'] ??
          sender['photo'] ??
          sender['picture'];
      if (pic != null && pic.toString().isNotEmpty) {
        return pic.toString();
      }
    }

    return null;
  }

  /// تحليل إيصال التسليم
  static DeliveryReceiptModel? _parseDeliveryReceipt(
      Map<String, dynamic> json) {
    final receipt = json['delivery_receipt'] ?? json['deliveryReceipt'];
    if (receipt != null && receipt is Map<String, dynamic>) {
      return DeliveryReceiptModel.fromJson(receipt);
    }

    // بناء من الحقول المباشرة
    if (json['delivered_at'] != null || json['read_at'] != null) {
      return DeliveryReceiptModel.fromJson({
        'delivered_at': json['delivered_at'] ?? json['deliveredAt'],
        'read_at': json['read_at'] ?? json['readAt'],
        'read_by': json['read_by'] ?? json['readBy'] ?? [],
      });
    }

    return null;
  }

  /// تحليل قائمة المنشنات
  static List<String> _parseMentions(Map<String, dynamic> json) {
    final mentions = json['mentions'];
    if (mentions == null) return [];

    if (mentions is List) {
      return mentions
          .map((m) => m.toString())
          .where((m) => m.isNotEmpty)
          .toList();
    }

    if (mentions is String) {
      return mentions
          .split(',')
          .map((m) => m.trim())
          .where((m) => m.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// تحليل قائمة القراء
  static List<String> _parseReadBy(Map<String, dynamic> json) {
    final readBy = json['read_by'] ?? json['readBy'];
    if (readBy == null) return [];

    if (readBy is List) {
      return readBy
          .map((id) => id.toString())
          .where((id) => id.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// تحليل البيانات الوصفية
  static Map<String, dynamic>? _parseMetadata(Map<String, dynamic> json) {
    final meta = json['metadata'] ?? json['meta'] ?? json['extra'];
    if (meta == null) return null;

    if (meta is Map<String, dynamic>) return meta;

    if (meta is String) {
      try {
        final decoded = jsonDecode(meta);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }

    return null;
  }

  /// تحليل التاريخ والوقت
  static DateTime _parseDateTime(
      Map<String, dynamic> json, String key1, String key2) {
    final dateStr = json[key1] ?? json[key2];
    if (dateStr != null) {
      final parsed = DateTime.tryParse(dateStr.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  /// تحليل التاريخ والوقت الاختياري
  static DateTime? _parseOptionalDateTime(
      Map<String, dynamic> json, String key1, String key2) {
    final dateStr = json[key1] ?? json[key2];
    if (dateStr != null) {
      return DateTime.tryParse(dateStr.toString());
    }
    return null;
  }

  /// تحليل القيم المنطقية
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }
}

/// نموذج الموقع الجغرافي
class LocationModel extends Location {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    super.address,
    super.placeName,
    super.accuracy,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
      address: json['address']?.toString(),
      placeName: json['place_name'] ?? json['placeName'],
      accuracy: _parseDouble(json['accuracy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (placeName != null) 'place_name': placeName,
      if (accuracy != null) 'accuracy': accuracy,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
