import 'package:equatable/equatable.dart';
import 'attachment.dart';

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String messageType;
  final String? content;
  final Location? location;
  final String? replyToMessageId;
  final Message? replyToMessage;
  final List<MessageReaction> reactions;
  final List<Attachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final bool isEdited;
  final DateTime? editedAt;
  final DeliveryReceipt? deliveryReceipt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? failureReason; // إضافة سبب الفشل
  final bool isForwarded;
  final String? forwardedFrom;
  final List<String> mentions;
  final bool isPinned;
  final bool isStarred;
  final List<String> readBy;
  final Map<String, dynamic>? metadata;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.messageType,
    this.content,
    this.location,
    this.replyToMessageId,
    this.replyToMessage,
    this.reactions = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.isEdited = false,
    this.editedAt,
    this.deliveryReceipt,
    this.isDeleted = false,
    this.deletedAt,
    this.failureReason,
    this.isForwarded = false,
    this.forwardedFrom,
    this.mentions = const [],
    this.isPinned = false,
    this.isStarred = false,
    this.readBy = const [],
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        senderAvatar,
        messageType,
        content,
        location,
        replyToMessageId,
        replyToMessage,
        reactions,
        attachments,
        createdAt,
        updatedAt,
        status,
        isEdited,
        editedAt,
        deliveryReceipt,
        isDeleted,
        deletedAt,
        failureReason,
        isForwarded,
        forwardedFrom,
        mentions,
        isPinned,
        isStarred,
        readBy,
        metadata,
      ];

  // Helper methods
  bool get isTextMessage => messageType == 'text';
  bool get isMediaMessage => ['image', 'video', 'audio'].contains(messageType);
  bool get hasAttachments => attachments.isNotEmpty;
  bool get isDelivered => status == 'delivered' || status == 'read';
  bool get isRead => status == 'read';
  bool get isFailed => status == 'failed';
}

class Location extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;
  final double? accuracy;

  const Location({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
    this.accuracy,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, placeName, accuracy];
}

class MessageReaction extends Equatable {
  final String id;
  final String messageId;
  final String userId;
  final String reactionType; // "like", "love", "laugh", "sad", "angry", "wow"

  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.reactionType,
  });

  @override
  List<Object?> get props => [id, messageId, userId, reactionType];
}

class DeliveryReceipt extends Equatable {
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<String> readBy;

  const DeliveryReceipt({
    this.deliveredAt,
    this.readAt,
    this.readBy = const [],
  });

  @override
  List<Object?> get props => [deliveredAt, readAt, readBy];
}

extension LocationExtension on Location {
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
    };
  }
}
